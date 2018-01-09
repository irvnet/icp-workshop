#!/bin/bash

# make ssh keys and copy the public key to root
echo "icpprep:  generate ssh keys "
ssh-keygen -b 4096 -t rsa -f ~/.ssh/master.id_rsa -N ""
cat ~/.ssh/master.id_rsa.pub >>  ~/.ssh/authorized_keys
cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys
#todo: push public key to worker nodes

# pull inception container
echo "icpprep:  pull inception container "
sudo docker pull ibmcom/icp-inception:2.1.0

# grab the install files
echo "icpprep:  grab install files "
cd
sudo docker run -e LICENSE=accept  -v "$(pwd)":/data ibmcom/icp-inception:2.1.0 cp -r cluster /data

# update the private key for install
echo "icpprep:  update private key in installs directory"
cat ~/.ssh/master.id_rsa | sudo tee -a ~/cluster/ssh_key

# install icp
# sudo docker run -e LICENSE=accept --net=host  -t -v "$(pwd)":/installer/cluster ibmcom/icp-inception:2.1.0 install
