#! /bin/sh

DEBIAN_FRONTEND=noninteractive apt update
DEBIAN_FRONTEND=noninteractive apt install -y python3 python3-simplejson

echo "configfs" >> /etc/modules
update-initramfs -u
systemctl daemon-reload

systemctl stop open-iscsi
systemctl disable open-iscsi
systemctl stop iscsid
systemctl disable iscsid

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

apt update -y

reboot
