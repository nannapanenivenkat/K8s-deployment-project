#!/bin/bash

#Add the hostname to your Kubernetes worker node
sudo hostnamectl set-hostname K8s-Worker

# Disable swap and remove swap entry from /etc/fstab
sudo su
swapoff -a; sed -i '/swap/d' /etc/fstab

# Load kernel modules for Kubernetes
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# Set sysctl parameters required by Kubernetes and apply without reboot
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl - system

# Install dependencies
apt update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Add Kubernetes apt repository and install Kubernetes components
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg - dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni

# Install Docker
apt install docker.io -y

# Configure containerd
sudo mkdir /etc/containerd
sudo sh -c "containerd config default > /etc/containerd/config.toml"
sudo sed -i 's/ SystemdCgroup = false/ SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd.service

# Restart kubelet and enable it to start on boot
systemctl restart kubelet.service
systemctl enable kubelet.service

#The kubeadm join command is used to join a worker node to a Kubernetes cluster. The command you provided includes the necessary parameters for joining
kubeadm join 172.31.59.154:6443 - token deq9nl.y34go2ziii0fu8c1 \
 - discovery-token-ca-cert-hash sha256:e93c56bd59b175b81845a671a82ffd1839e42272d922f9c43ca8d8f6d145ce02
#

#KUBERNETES MONITORING FOR MASTER AND WORKER NODES 
sudo useradd \
--system \
--no-create-home \
--shell /bin/false prometheus

#Download the node exporter package on both Kubernetes Nodes and Untar the node exporter package file and move the node_exporter directory to the /usr/local/bin directory
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar -xvf node_exporter-1.7.0.linux-amd64.tar.gz
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/

#Create the systemd configuration file for node exporter.
sudo vim /etc/systemd/system/node_exporter.service
#Copy the below configurations and paste them into the /etc/systemd/system/node_exporter.service file.
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5
[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter \
 --collector.logind
[Install]
WantedBy=multi-user.target

#Enable the node exporter systemd configuration file and start it.
sudo systemctl enable node_exporter
sudo systemctl enable node_exporter
systemctl status node_exporter.service