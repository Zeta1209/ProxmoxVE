# Arr suite network drive installation on Proxmox
Quick guide for install some services from the Arr suite on Proxmox. Also setting up network drive from a NAS.
> FYI: To install the Arr suite, the most easy and beautiful solution is using this: [Proxmox VE Helper-Scripts](https://community-scripts.github.io/ProxmoxVE/)

# *On the NAS*
  1. Turn on NFS Share (NFS is better than SMB for Linux systems, otherwise we could use SMB)
  2. Add NFS permissions for the concerned folder
     1. In my case, my local network is 10.0.0.1/24 so I'll use 10.0.0.* which will allow all host from 10.0.0.1 to 10.0.0.255
  4. Apply all your changes and take not of the path (ex: Volume1/Media)

# *On Proxmox*
## 1. Create a folder to mount our NAS:
```bash
mkdir /mnt/MyNAS/ && mkdir /mnt/MyNAS/Media
```
## 2. Then we need to manually mount the shared folder:
##### Here the "-t nfs" specify the filesystem and the "-o vers=4.1" specify the version of NFS (last one is optional but In my case to avoid any compatiblity issues. I do specify it.
```bash
mount -t nfs -o vers=4.1 nas-ip-address:/Volume1/Media /mnt/MyNAS/Media
ls -a /mnt/MyNAS/Media
```
##### This last command should output the content of our Media folder (if there was something). If not, ggs and try again.

## 3. We also need to edit the permission of the folder:
```bash
chmod -R 777 /mnt/MyNAS/Media
```
## 4. Now we can add the auto-mount (if we don't want to mount it at every startup like some bafoons)
```bash
nano /etc/fstab
```
## 5. Add this line to the file:
```nano
nas-ip-address:/Volume1/Media /mnt/TerraNAS/Media nfs defaults,nfsvers=4.1 0 0
```
##### Don't forget to change it to your own NAS ip
## 6. Now we can add the mounted drive to our Arr containers (only need Radarr, Sonarr and qBitorrent since they need to see the Media folder to scan/download)
> DO THIS FOR ALL CONTAINER THAT NEEDS IT
```bash
nano /etc/pve/lxc/712.conf
```
##### here replace 712 by your own container id.
## 7. Inside the file add this line at the end:
```nano
mp0: /mnt/MyNAS/Media,mp=/mnt/media
```
##### As you can see here, inside our container our media will have this path: "/mnt/media"
## 8. Finally, you can reboot the container if it was still running

# *On Radarr/Sonarr*

## 1. Go in your Settings, Media Management, Root Folders and add "/mnt/media"
    
# *qBitorrent (with VPN)*

## 1. Add the network drive like we did before from step 6-8

## 2. 
