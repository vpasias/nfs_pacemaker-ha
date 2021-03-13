#! /bin/sh

DEBIAN_FRONTEND=noninteractive apt update
DEBIAN_FRONTEND=noninteractive apt install -y python3 python3-simplejson xfsprogs
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

cat << EOF | tee /etc/hosts
127.0.0.1 localhost
172.16.2.101 server102
172.16.2.102 server202
172.16.2.103 server302
172.16.2.104 server402
EOF

apt update -y

reboot
