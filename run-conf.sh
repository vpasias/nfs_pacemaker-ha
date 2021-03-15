#! /bin/sh

export LC_ALL=C
export LC_CTYPE="UTF-8",
export LANG="en_US.UTF-8"

# ---- PART ONE ------
# Configure SSH connectivity from 'deployment' - server104 to Target Hosts 

echo 'run-conf.sh: Cleaning directory /home/vagrant/.ssh/'
rm -f /home/vagrant/.ssh/known_hosts
rm -f /home/vagrant/.ssh/id_rsa
rm -f /home/vagrant/.ssh/id_rsa.pub

echo 'run-conf.sh: Running ssh-keygen -t rsa'
ssh-keygen -q -t rsa -N "" -f /home/vagrant/.ssh/id_rsa

echo 'run-conf.sh: Install sshpass & nfs-common'
sudo apt -y install nfs-common sshpass

echo 'run-conf.sh: Running ssh-copy-id for server501'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server501
echo 'run-conf.sh: Running ssh-copy-id for server502'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server502
echo 'run-conf.sh: Running ssh-copy-id for server503'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server503

echo 'run-conf.sh: Running scp node_setup.sh for server501'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server501:/home/vagrant/node_setup.sh
echo 'run-conf.sh: Running scp node_setup.sh for server502'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server502:/home/vagrant/node_setup.sh
echo 'run-conf.sh: Running scp node_setup.sh for server503'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server503:/home/vagrant/node_setup.sh

echo 'run-conf.sh: Running ssh vagrant@server501 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo bash /home/vagrant/node_setup.sh"
echo 'run-conf.sh: Running ssh vagrant@server502 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server502 "sudo bash /home/vagrant/node_setup.sh"
echo 'run-conf.sh: Running ssh vagrant@server503 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server503 "sudo bash /home/vagrant/node_setup.sh"

sleep 30

ssh -o StrictHostKeyChecking=no vagrant@server501 "uname -a"
ssh -o StrictHostKeyChecking=no vagrant@server502 "uname -a"
ssh -o StrictHostKeyChecking=no vagrant@server503 "uname -a"

echo 'run-conf.sh: Configuration of GlusterFS'

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo systemctl status glusterd"
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo gluster peer probe server502"
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo gluster peer probe server503"

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo gluster peer status"
ssh -o StrictHostKeyChecking=no vagrant@server502 "sudo gluster peer status"
ssh -o StrictHostKeyChecking=no vagrant@server503 "sudo gluster peer status"

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo gluster volume create sharedvol replica 3 server501:/data/glusterfs/sharedvol/mybrick/brick \
server502:/data/glusterfs/sharedvol/mybrick/brick \
server503:/data/glusterfs/sharedvol/mybrick/brick"

sleep 10

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo gluster volume start sharedvol"

sleep 10

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo gluster volume info"

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo gluster volume status"

echo 'run-conf.sh: GlusterFS configuration finished'

echo 'run-conf.sh: Configure Pacemaker'

ssh -o StrictHostKeyChecking=no vagrant@server501 'echo "hacluster:gprm8350" | sudo chpasswd'
ssh -o StrictHostKeyChecking=no vagrant@server502 'echo "hacluster:gprm8350" | sudo chpasswd'
ssh -o StrictHostKeyChecking=no vagrant@server503 'echo "hacluster:gprm8350" | sudo chpasswd'

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo systemctl enable corosync && sudo systemctl enable pacemaker && sudo systemctl enable --now pcsd"
ssh -o StrictHostKeyChecking=no vagrant@server502 "sudo systemctl enable corosync && sudo systemctl enable pacemaker && sudo systemctl enable --now pcsd"
ssh -o StrictHostKeyChecking=no vagrant@server503 "sudo systemctl enable corosync && sudo systemctl enable pacemaker && sudo systemctl enable --now pcsd"

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo systemctl stop corosync"
sleep 10
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo systemctl stop pacemaker"

ssh -o StrictHostKeyChecking=no vagrant@server502 "sudo systemctl stop corosync"
sleep 10
ssh -o StrictHostKeyChecking=no vagrant@server502 "sudo systemctl stop pacemaker"

ssh -o StrictHostKeyChecking=no vagrant@server503 "sudo systemctl stop corosync"
sleep 10
ssh -o StrictHostKeyChecking=no vagrant@server503 "sudo systemctl stop pacemaker"

sleep 20

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo systemctl status pacemaker"
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo systemctl status corosync"

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo rm -rf /etc/corosync/corosync.conf"

ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo pcs host auth -u hacluster -p gprm8350 server501 server502 server503"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo pcs cluster setup HA-NFS server501 server502 server503 --force"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo pcs cluster start --all"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo pcs cluster enable --all"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo pcs property set stonith-enabled=false"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo pcs resource create nfs_server systemd:nfs-ganesha op monitor interval=10s"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo pcs resource create nfs_ip ocf:heartbeat:IPaddr2 ip=172.16.3.250 cidr_netmask=24 op monitor interval=10s"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo pcs resource group add nfs_group nfs_server nfs_ip"
sleep 5
ssh -o StrictHostKeyChecking=no vagrant@server501 "sudo pcs status"

echo 'run-conf.sh: Pacemaker configuration finished'
