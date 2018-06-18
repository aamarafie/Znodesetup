## **The Script automatically installs and configures a Znode on VPS**
### **It also checks if a Znode is already running, if not updating**

* Installs Fail2Ban (optional)
* Installs Firewall (optional)
* Installs & configures MONIT (optional to monitor and keep Znode alive)
* Creates swap if less than 4GB memory
* Updates VPS
* Downloads all dependencies and github / builds Zcoin<br/>
  _Note: Compiling does take a while vs downloading the binary_
  _Update: Added manual bin installing since make install was broken in x.4"_


## **Please README before you Install**
### **Run as a normal user with sudo privilege**

I have created this simple script to complement the [Znode Setup Guide](https://zcoin.io/zcoin-znode-setup-guide/) and automatically install on VPS with all the required bells and whistles. <br/>

Once you send your 1000 Zcoins to the Znode address you can run this script on the VPS and it should take care of all the requirements. **All you need is to have is your _Znode Private key_ ready when it prompts for it <br/>**
**(generated from "_znode genkey_" command in Help> Debug Window)<br/>**
Don’t forget to edit your wallet's znode.conf to include your Znode details.

Feeling appreciative & generous, show some love by sending Zcoins my way :smiley:<br/>
aBJFCE2XaExDZAdd1vuek9GkFCNtmF7nao


### **First time Instructions**
Login the VPS as root to create a user
```
adduser <username>
usermod -aG sudo <username>
```
Login into the new created user
```
wget https://raw.githubusercontent.com/aamarafie/Znodesetup/master/znsetup.sh
sudo chmod u+x znsetup.sh
./znsetup.sh
```
### **In the future to update your Znode simply**
```
./znsetup.sh -update
```

### **To see the status, version and sync status of your Znode**
```
./znsetup.sh -s
```
