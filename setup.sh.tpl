#!/bin/bash

# nvidia driver
bash /opt/deeplearning/install-driver.sh

# fix ldconfig
rm /lib/libnvonnxparser.so.8
ln /lib/libnvonnxparser.so.8.6.1 /lib/libnvonnxparser.so.8

rm /lib/libnvinfer_dispatch.so.8
ln /lib/libnvinfer_dispatch.so.8.6.1 /lib/libnvinfer_dispatch.so.8

rm /lib/libnvinfer.so.8
ln /lib/libnvinfer.so.8.6.1 /lib/libnvinfer.so.8

rm /lib/libnvinfer_plugin.so.8
ln /lib/libnvinfer_plugin.so.8.6.1 /lib/libnvinfer_plugin.so.8

rm /lib/libnvinfer_vc_plugin.so.8
ln /lib/libnvinfer_vc_plugin.so.8.6.1 /lib/libnvinfer_vc_plugin.so.8

rm /lib/libnvparsers.so.8
ln /lib/libnvparsers.so.8.6.1 /lib/libnvparsers.so.8

rm /lib/libnvinfer_lean.so.8
ln /lib/libnvinfer_lean.so.8.6.1 /lib/libnvinfer_lean.so.8

# install tailscale
apt-get update --allow-releaseinfo-change
curl -fsSL https://tailscale.com/install.sh | sh
# tailscale_authkey comes from terraform
tailscale up --authkey ${tailscale_authkey}

# create a new user
useradd -m -s /bin/bash ${user_name}
usermod -aG sudo ${user_name}
echo "${user_name} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/${user_name}
chmod 0440 /etc/sudoers.d/${user_name}
mkdir /home/${user_name}/.ssh
touch /home/${user_name}/.ssh/authorized_keys
echo ${ssh_pubkey} >>/home/${user_name}/.ssh/authorized_keys
chown -R ${user_name}:${user_name} /home/${user_name}/.ssh

# fix PATH
echo -e '\nexport PATH="/sbin:$PATH"' >>/home/${user_name}/.bashrc

# install starship
curl -sS https://starship.rs/install.sh | sh -s -- -y
echo -e '\neval "$(starship init bash)"' >>/home/${user_name}/.bashrc
