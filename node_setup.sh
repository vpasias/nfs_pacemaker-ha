#! /bin/sh

DEBIAN_FRONTEND=noninteractive apt update
DEBIAN_FRONTEND=noninteractive apt install -y python3 python3-simplejson xfsprogs sshpass
DEBIAN_FRONTEND=noninteractive apt install -y corosync glusterfs-server nfs-ganesha-gluster pacemaker pcs

modprobe -v xfs
grep xfs /proc/filesystems
modinfo xfs

echo "root:gprm8350" | sudo chpasswd

chmod -x /etc/update-motd.d/*

cat << EOF | sudo tee /etc/update-motd.d/01-custom
#!/bin/sh
echo "****************************WARNING****************************************
UNAUTHORISED ACCESS IS PROHIBITED. VIOLATORS WILL BE PROSECUTED.
*********************************************************************************"
EOF

chmod +x /etc/update-motd.d/01-custom

cat << EOF | sudo tee /etc/modprobe.d/qemu-system-x86.conf
options kvm_intel nested=1
EOF

modprobe -r kvm_intel

modprobe kvm_intel nested=1

cat /sys/module/kvm_intel/parameters/nested

modinfo kvm_intel | grep -i nested

mkdir -p /etc/apt/sources.list.d

mkfs.xfs -f -i size=512 -L gluster-000 /dev/sda

mkdir -p /data/glusterfs/sharedvol/mybrick
echo 'LABEL=gluster-000 /data/glusterfs/sharedvol/mybrick xfs defaults  0 0' >> /etc/fstab
mount /data/glusterfs/sharedvol/mybrick

systemctl enable --now glusterd

mv /etc/hosts /etc/old.hosts

cat << EOF | tee /etc/hosts
127.0.0.1 localhost
172.16.1.101 server101
172.16.1.102 server102
172.16.1.103 server103
172.16.1.110 server104
172.16.1.104 server301
172.16.1.105 server302
172.16.1.106 server303
172.16.2.101 server304
172.16.1.107 server501
172.16.1.108 server502
172.16.1.109 server503
172.16.2.102 server504
172.16.3.101 server701
172.16.3.102 server702
172.16.3.103 server703
172.16.4.101 server704
172.16.3.250 nfs
EOF

mv /etc/ganesha/ganesha.conf /etc/ganesha/old.ganesha.conf

cat << EOF | tee /etc/ganesha/ganesha.conf
EXPORT{
    Export_Id = 1 ;       # Unique identifier for each EXPORT (share)
    Path = "/sharedvol";  # Export path of our NFS share

    FSAL {
        name = GLUSTER;          # Backing type is Gluster
        hostname = "localhost";  # Hostname of Gluster server
        volume = "sharedvol";    # The name of our Gluster volume
    }

    Access_type = RW;          # Export access permissions
    Squash = No_root_squash;   # Control NFS root squashing
    Disable_ACL = FALSE;       # Enable NFSv4 ACLs
    Pseudo = "/sharedvol";     # NFSv4 pseudo path for our NFS share
    Protocols = "3","4" ;      # NFS protocols supported
    Transports = "UDP","TCP" ; # Transport protocols supported
    SecType = "sys";           # NFS Security flavors supported
}
EOF

apt update -y

reboot
