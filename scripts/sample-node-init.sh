#!/bin/bash

echo "########################################################"
echo "#### icpprep:  starting ICP node pre-req install   #####"
echo "########################################################\n\n"


# disable selinux
echo "#### icpprep: turn off se-linux "
apt install selinux-utils -y
setenforce 0

# make sure the public ip and hostname are referenceable
export PIP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
echo "$PIP $HOSTNAME" | sudo tee -a /etc/hosts

# install ssh server
echo "#### icpprep: install ssh server "
apt-get install openssh-server -y
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
systemctl restart sshd.service

# update max map count
echo "#### icpprep:  update max map count"
echo "vm.max_map_count = 262144" | tee -a  /etc/sysctl.conf

# install docker
echo "#### icpprep:  install docker"
apt-get remove docker docker-engine docker-io
apt-get install python python-pip -y
apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -y
apt-get install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
apt-key fingerprint 0ebfcd88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install docker-ce -y
systemctl start docker

echo "########################################################"
echo "#### icpprep:  done with ICP node pre-req install##### "
echo "########################################################"
