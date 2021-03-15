#! /bin/sh

export LC_ALL=C
export LC_CTYPE="UTF-8",
export LANG="en_US.UTF-8"

# ---- PART ONE ------
# Configure SSH connectivity from 'deployment' - server101 to Target Hosts 

echo 'run-conf.sh: Cleaning directory /home/vagrant/.ssh/'
rm -f /home/vagrant/.ssh/known_hosts
rm -f /home/vagrant/.ssh/id_rsa
rm -f /home/vagrant/.ssh/id_rsa.pub

echo 'run-conf.sh: Running ssh-keygen -t rsa'
ssh-keygen -q -t rsa -N "" -f /home/vagrant/.ssh/id_rsa

echo 'run-conf.sh: Install sshpass & nfs-common'
sudo apt -y install nfs-common sshpass

echo 'run-conf.sh: Running ssh-copy-id for server301'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server301
echo 'run-conf.sh: Running ssh-copy-id for server302'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server302
echo 'run-conf.sh: Running ssh-copy-id for server303'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server303

echo 'run-conf.sh: Running scp node_setup.sh for server301'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server301:/home/vagrant/node_setup.sh
echo 'run-conf.sh: Running scp node_setup.sh for server302'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server302:/home/vagrant/node_setup.sh
echo 'run-conf.sh: Running scp node_setup.sh for server303'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server303:/home/vagrant/node_setup.sh

echo 'run-conf.sh: Running ssh vagrant@server301 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo bash /home/vagrant/node_setup.sh"
echo 'run-conf.sh: Running ssh vagrant@server302 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server302 "sudo bash /home/vagrant/node_setup.sh"
echo 'run-conf.sh: Running ssh vagrant@server303 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server303 "sudo bash /home/vagrant/node_setup.sh"

sleep 30

ssh -o StrictHostKeyChecking=no vagrant@server301 "uname -a"
ssh -o StrictHostKeyChecking=no vagrant@server302 "uname -a"
ssh -o StrictHostKeyChecking=no vagrant@server303 "uname -a"

echo 'run-conf.sh: Configuration of GlusterFS'

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo systemctl status glusterd"
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo gluster peer probe server302"
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo gluster peer probe server303"

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo gluster peer status"
ssh -o StrictHostKeyChecking=no vagrant@server302 "sudo gluster peer status"
ssh -o StrictHostKeyChecking=no vagrant@server303 "sudo gluster peer status"

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo gluster volume create sharedvol replica 3 server301:/data/glusterfs/sharedvol/mybrick/brick \
server302:/data/glusterfs/sharedvol/mybrick/brick \
server303:/data/glusterfs/sharedvol/mybrick/brick"

sleep 10

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo gluster volume start sharedvol"

sleep 10

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo gluster volume info"

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo gluster volume status"

echo 'run-conf.sh: GlusterFS configuration finished'

echo 'run-conf.sh: Configure Pacemaker'

ssh -o StrictHostKeyChecking=no vagrant@server301 'echo "hacluster:gprm8350" | sudo chpasswd'
ssh -o StrictHostKeyChecking=no vagrant@server302 'echo "hacluster:gprm8350" | sudo chpasswd'
ssh -o StrictHostKeyChecking=no vagrant@server303 'echo "hacluster:gprm8350" | sudo chpasswd'

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo systemctl enable corosync && sudo systemctl enable pacemaker && sudo systemctl enable --now pcsd"
ssh -o StrictHostKeyChecking=no vagrant@server302 "sudo systemctl enable corosync && sudo systemctl enable pacemaker && sudo systemctl enable --now pcsd"
ssh -o StrictHostKeyChecking=no vagrant@server303 "sudo systemctl enable corosync && sudo systemctl enable pacemaker && sudo systemctl enable --now pcsd"

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo systemctl stop corosync"
sleep 10
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo systemctl stop pacemaker"

ssh -o StrictHostKeyChecking=no vagrant@server302 "sudo systemctl stop corosync"
sleep 10
ssh -o StrictHostKeyChecking=no vagrant@server302 "sudo systemctl stop pacemaker"

ssh -o StrictHostKeyChecking=no vagrant@server303 "sudo systemctl stop corosync"
sleep 10
ssh -o StrictHostKeyChecking=no vagrant@server303 "sudo systemctl stop pacemaker"

sleep 20

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo systemctl status pacemaker"
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo systemctl status corosync"

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo rm -rf /etc/corosync/corosync.conf"

ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo pcs host auth -u hacluster -p gprm8350 server301 server302 server303"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo pcs cluster setup HA-NFS server301 server302 server303 --force"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo pcs cluster start --all"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo pcs cluster enable --all"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo pcs property set stonith-enabled=false"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo pcs resource create nfs_server systemd:nfs-ganesha op monitor interval=10s"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo pcs resource create nfs_ip ocf:heartbeat:IPaddr2 ip=172.16.3.250 cidr_netmask=24 op monitor interval=10s"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo pcs resource group add nfs_group nfs_server nfs_ip"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server301 "sudo pcs status"

echo 'run-conf.sh: Pacemaker configuration finished'
