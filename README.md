## **The Script automatically installs and sets up a Znode on VPS**


-Installs Fail2Ban optional
-Installs Firewall optional
-Installs & configures MONIT optional (to monitor and keep Znode alive)
-Creates swap if less than 4GB memory
-Updates VPS
-Downloads all dependencies / builds Zcoin


## **Please README before you Install**
### **Run as a normal user with sudo privilege**

I have created this simple script to complement the Znode setup guide (https://zcoin.io/zcoin-znode-setup-guide/) and automatically complete the VPS setup process.

Once you send your 1k Zcoins to the Znode address you can run this script on the VPS and it should take care of all the requirements.

All you need is to have is your _Znode Private key_ ready when it prompts for it *(generated from “znode genkey“ command in Help> Debug Window)*

Don’t forget to edit your wallet's znode.conf to include your Znode.


Feeling generous & appreciative, show some love by sending Zcoins my way :simple_smile:

aBJFCE2XaExDZAdd1vuek9GkFCNtmF7nao


## **First time Instructions**
```
Wget https://github.com/aamarafie/Znodesetup/blob/master/znsetup.sh
sudo chmod u+x znsetup.sh
./znsetup.sh
```
## **In the future to update your Znode simply**
```
./znsetup.sh –update
```

## **To see the status, version and sync status of your Znode**
```
./znsetup.sh –s
```
