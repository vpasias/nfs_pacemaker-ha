#! /bin/sh

export LC_ALL=C
export LC_CTYPE="UTF-8",
export LANG="en_US.UTF-8"

# ---- PART ONE ------
# Configure SSH connectivity from 'deployment' - server102 to Target Hosts 

echo 'run-conf.sh: Cleaning directory /home/vagrant/.ssh/'
rm -f /home/vagrant/.ssh/known_hosts
rm -f /home/vagrant/.ssh/id_rsa
rm -f /home/vagrant/.ssh/id_rsa.pub

echo 'run-conf.sh: Running ssh-keygen -t rsa'
ssh-keygen -q -t rsa -N "" -f /home/vagrant/.ssh/id_rsa

echo 'run-conf.sh: Install sshpass'
sudo apt-get install sshpass -y

echo 'run-conf.sh: Running ssh-copy-id for server202'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server202
echo 'run-conf.sh: Running ssh-copy-id for server302'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server302
echo 'run-conf.sh: Running ssh-copy-id for server402'
sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=no vagrant@server402

echo 'run-conf.sh: Running scp node_setup.sh for server202'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server202:/home/vagrant/node_setup.sh
echo 'run-conf.sh: Running scp node_setup.sh for server302'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server302:/home/vagrant/node_setup.sh
echo 'run-conf.sh: Running scp node_setup.sh for server402'
scp -o StrictHostKeyChecking=no node_setup.sh vagrant@server402:/home/vagrant/node_setup.sh

echo 'run-conf.sh: Running ssh vagrant@server202 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server202 "sudo bash /home/vagrant/node_setup.sh"
echo 'run-conf.sh: Running ssh vagrant@server302 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server302 "sudo bash /home/vagrant/node_setup.sh"
echo 'run-conf.sh: Running ssh vagrant@server402 “sudo bash /home/vagrant/node_setup.sh”'
ssh -o StrictHostKeyChecking=no vagrant@server402 "sudo bash /home/vagrant/node_setup.sh"
