#!/bin/bash
install_bins(){
wget $filelink
ttt="$(basename -- $filelink)"
if [ -d "zcoin" ]; then
  sudo monit stop all
  zcoin-cli stop
  rm -rv zcoin
fi
mkdir zcoin
tar -xvf $ttt -C $HOME/zcoin --strip-components=1
sudo cp $HOME/zcoin/bin/zcoind /usr/local/bin/zcoind
sudo cp $HOME/zcoin/bin/zcoin-cli /usr/local/bin/zcoin-cli
sudo cp $HOME/zcoin/bin/zcoin-tx /usr/local/bin/zcoin-tx
rm $ttt
}


if [[ $1 == "-s" ]]
then
zcoin-cli znode status
zcoin-cli getinfo
zcoin-cli znsync status
exit
fi

if [[ $1 == "-u" ]]
then
filelink=$2
install_bins
echo "Finished Updating ....Starting Zcoin daemon & Monit"
sleep 5
zcoind -daemon
sudo monit start all
exit
fi


if [[ $1 == "-f" ]]
then
echo "Before starting script ensure you have: "
echo "1000XZC sent to ZN address, It has to be in one single transaction!"
echo "ran 'znode genkey', and 'getaccountaddress ZNX'"
echo "Add the following info to the znode config file (znode.conf) "
echo "LABEL vpsIp:8168  ZNODEPRIVKEY TXID INDEX"
echo "EXAMPLE------>ZN1 51.52.53.54:8168  XrxSr3fXpX3dZcU7CoiFuFWqeHYw83 d6fd38868bb8f9958e34d5155437d00 1"
echo "save your znode.conf. Restart your Zcoin wallet"

#read -e -p "Server IP Address : " ip
UFW="Y"
install_fail2ban="Y"
install_monit="Y"
filelink=$2

ip=$(hostname -I | awk {'print $1'})
read -e -p "Znode Private Key  : " key
read -e -p "Install Fail2ban? [Y/n] : " install_fail2ban
read -e -p "Install UFW and configure ports? [Y/n] : " UFW
read -e -p "Install MONIT to automaticaly keep you node alive? [Y/n] : " install_monit
echo "IP set to $ip"
pause

# Create swapfile if less then 4GB memory
totalmem=$(free -m | awk '/^Mem:/{print $2}')
totalswp=$(free -m | awk '/^Swap:/{print $2}')
totalm=$(($totalmem + $totalswp))
if [ $totalm -lt 4000 ]; then
  echo "Server memory is less then 4GB..."
  if ! grep -q '/swapfile' /etc/fstab ; then
    echo "Creating a 4GB swapfile..."
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee --append /etc/fstab > /dev/null
    sudo mount -a
    echo "Swap created"
  fi
fi

#Generating Random Passwords
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)


clear

echo "Updating Ubunto"
sleep 5

# update package and upgrade Ubuntu
sudo DEBIAN_FRONTEND=noninteractive apt -y update
sudo DEBIAN_FRONTEND=noninteractive apt -y upgrade
sudo DEBIAN_FRONTEND=noninteractive apt -y autoremove


echo "installing Zcoin..."
install_bins

echo "preparing Zcoin config..."
#znode config file
mkdir $HOME/.zcoin
cat <<EOF > $HOME/.zcoin/zcoin.conf
#
rpcuser=user
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
#
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=64
txindex=1
#
znode=1
znodeprivkey=$key
externalip=$ip:8168
EOF

echo "Starting zcoind"
sleep 5

zcoind -daemon

if [ "$install_fail2ban" = "y" ] || [ "$install_fail2ban" = "Y" ] || [ "$install_fail2ban" = "" ];
then
    echo "installing f2b"
    sudo apt-get install fail2ban -y
    sudo service fail2ban restart
fi

if [ "$UFW" = "y" ] || [ "$UFW" = "Y" ] || [ "$UFW" = "" ];
then
    echo "installing UFW"
    sudo apt-get install ufw -y
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 8168/tcp
    yes | sudo ufw enable
fi

if [ "$install_monit" = "y" ] || [ "$install_monit" = "Y" ] || [ "$install_monit" = "" ];
then
    echo "installing and configuring MONIT"
    sudo apt install monit

#monit config for process to monitor
cat <<EOF | sudo tee /etc/monit/conf.d/zcoind.conf
check process zcoind with pidfile $HOME/.zcoin/zcoind.pid
start program = "$HOME/zcoin/bin/zcoind -conf=$HOME/.zcoin/zcoin.conf -datadir=$HOME/.zcoin/"
as uid $USER and gid $USER
stop program = "$HOME/zcoin/bin/zcoin-cli stop"
as uid $USER and gid $USER
if failed port 8168 then restart
if 5 restarts within 5 cycles then unmonitor
EOF

#monit setting
cat <<EOF | sudo tee /etc/monit/monitrc
#
set daemon 120
#
set logfile /var/log/monit.log
#
set idfile /var/lib/monit/id
#
set statefile /var/lib/monit/state
#
set eventqueue
basedir /var/lib/monit/events # set the base directory where events will be stored
slots 100                     # optionally limit the queue size
#
set httpd port 2812 and
    use address localhost  # only accept connection from localhost
    allow localhost        # allow localhost to connect to the server and
    allow admin:monit      # require user 'admin' with password 'monit'
#
include /etc/monit/conf.d/*
#
EOF

sudo monit reload
sudo monit status
sudo monit start all

fi
fi

echo "Feeling appreciative & generous, show some love by sending Zcoins my way"
echo "aBJFCE2XaExDZAdd1vuek9GkFCNtmF7nao"
