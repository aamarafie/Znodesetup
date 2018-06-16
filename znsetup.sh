#!/bin/bash

update_znode() {
	BUILD_CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
	cd $HOME/zcoin
	sudo monit stop all
	zcoin-cli stop
	git checkout master
	git pull
	./autogen.sh
	./configure
	make -j$BUILD_CORES
	sudo make install
	zcoind -daemon
	sudo monit start all
	exit
}

pause(){
	read -n1 -rsp $'Press any key to continue or Ctrl+C to exit...\n'
}

print_status() {
    echo "## $1"
}

if [[ $1 == "-update" ]]
then
	update_znode
fi

if [[ $1 == "-s" ]]
then
	zcoin-cli znode status
	zcoin-cli getinfo
	zcoin-cli znsync status
	exit
fi


clear
print_status "Before starting script ensure you have: "
print_status "1000XZC sent to ZN address, It has to be in one single transaction!"
print_status "ran 'znode genkey', and 'getaccountaddress ZNX'"
print_status "Add the following info to the znode config file (znode.conf) "
print_status "LABEL vpsIp:8168  ZNODEPRIVKEY TXID INDEX"
print_status "EXAMPLE------>ZN1 51.52.53.54:8168  XrxSr3fXpX3dZcU7CoiFuFWqeHYw83 d6fd38868bb8f9958e34d5155437d00 0"
print_status "EXAMPLE------>ZN1 51.52.53.54:8168  XrxSr3fXpX3dZcU7CoiFuFWqeHYw83 d6fd38868bb8f9958e34d5155437d00 1"
print_status "save your znode.conf. Restart your Zcoin wallet"

#read -e -p "Server IP Address : " ip
UFW="Y"
install_fail2ban="Y"
install_monit="Y"
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
  print_status "Server memory is less then 4GB..."
  if ! grep -q '/swapfile' /etc/fstab ; then
    print_status "Creating a 4GB swapfile..."
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee --append /etc/fstab > /dev/null
    sudo mount -a
    print_status "Swap created"
  fi
fi

#Generating Random Passwords
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)


clear

print_status "Updating system"
sleep 5

# update package and upgrade Ubuntu
sudo DEBIAN_FRONTEND=noninteractive apt-get -y update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt-get -y autoremove
sudo apt-get install git -y

clear
print_status "Installing dependencies"
sleep 5

git clone https://github.com/zcoinofficial/zcoin.git
cd zcoin
sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils libboost-all-dev libminiupnpc-dev -y
sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y

clear
print_status "Building zcoin.. this will take a while"
sleep 5
./autogen.sh
clear
print_status "building in progress..."
sleep 5
./configure
clear
print_status "Final stage...almost there"
sleep 5
# if more cores
BUILD_CORES=$(cat /proc/cpuinfo | grep processor | wc -l)
print_status "Compiling from source with $BUILD_CORES core(s)"
make -j$BUILD_CORES
clear
print_status "Installing zcoin and zcoin-cli binaries."
sudo make install
clear

#znode config file
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

clear
print_status "Starting zcoind"
sleep 5

zcoind -daemon

clear


if [ $install_fail2ban == "y" ] || [ $install_fail2ban == "Y" ]
then
    print_status "installing f2b"
    sudo apt-get install fail2ban -y
    sudo service fail2ban restart
fi

if [ $UFW == "y" ] || [ $UFW == "Y" ]
then
    print_status "installing UFW"
    sudo apt-get install ufw -y
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 8168/tcp
    yes | sudo ufw enable
fi

if [ $install_monit == "y" ] || [ $install_monit == "Y" ]
then
    print_status "installing and configuring MONIT"
    sudo apt install monit

#monit config for process to monitor
cat <<EOF > $HOME/.zcoin/zcoin.conf
#
check process zcoind with pidfile $HOME/.zcoin/zcoind.pid
start program = "$HOME/zcoin/src/zcoind" -conf=$HOME/.zcoin/zcoin.conf -datadir=$HOME/.zcoin/"
as uid $USER and gid $USER
stop program = "$HOME/zcoin/src/zcoin-cli stop"
as uid $USER and gid $USER
if failed port 8168 then restart
if 5 restarts within 5 cycles then unmonitor
EOF

#monit setting
	cat <<EOF > /etc/monit/monitrc
cat <<EOF > /etc/monit/monitrc
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
set httpd port 2812 and use address localhost  # only accept connection from localhost
allow localhost        # allow localhost to connect to the server and
allow admin:monit      # require user 'admin' with password 'monit'
#
include /etc/monit/conf.d/*
EOF
	sudo monit reload
	sudo monit start all
fi
clear
