# Kodekloud's ARM solution for kubernetes

This repo is a starting point for the [https://github.com/kodekloudhub/certified-kubernetes-administrator-course](certified kubernetes administrator course) with an Apple Silicon.
I made it work a cluster from scratch, although it differs slightly from the solution provided on kodekloud. Maybe some little editing is needed to make it work on your Mac.

The original idea on which is based, and the topology it sets up, is the one described [https://gist.github.com/max-i-mil/f44e8e6f2416d88055fc2d0f36c6173b](here), but the setup differs: I don't use libvirt, but qemu along with vagrant's qemu-plugin.

![topology](https://assets.digitalocean.com/articles/alligator/boo.svg)

## A word about Weave
The initial setup used weave, at least in the first kubernetes' lecture. But it didn't work. So I switched to flannel in my own setup. Read more below on the steps.

## A word about the setup
Some things has changed since the videos were recorded. My setup below reflects this in order to make it work at the moment of writing this (01-13-2023).
The steps must be considered just a guide,  my own steps to make it work, not the perfect setup scenario. Please do read the original kubernetes documentation!

### Networking setup
I've added some scripts to add all the nodes on each `/etc/hosts`, enable the interface you should use to make them communicate on the vnet, and acquire the expected IP.
I don't know if this setup will work on your machine, so feel free to change the IPs defaults to make it work. Again, this is my very own solution and it's not intended to be world-proof 😅.

## Steps
```
#docker
sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo docker run hello-world


#https://github.com/Mirantis/cri-dockerd

git clone https://github.com/Mirantis/cri-dockerd.git
cd cri-dockerd
sudo apt-get install golang-go
mkdir bin
VERSION=$((git describe --abbrev=0 --tags | sed -e 's/v//') || echo $(cat VERSION)-$(git log -1 --pretty='%h')) PRERELEASE=$(grep -q dev <<< "${VERSION}" && echo "pre" || echo "") REVISION=$(git log -1 --pretty='%h')
go build -ldflags="-X github.com/Mirantis/cri-dockerd/version.Version='$VERSION}' -X github.com/Mirantis/cri-dockerd/version.PreRelease='$PRERELEASE' -X github.com/Mirantis/cri-dockerd/version.BuildTime='$BUILD_DATE' -X github.com/Mirantis/cri-dockerd/version.GitCommit='$REVISION'" -o cri-dockerd

go build -o bin/cri-dockerd
mkdir -p /usr/local/bin
sudo install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
sudo cp -a packaging/systemd/* /etc/systemd/system
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket


# install kubeadm, kubectl, kubelet
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo apt-get install -y apt-transport-https
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# init kubadm *ONLY ON MASTER*
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=192.168.64.8 --cri-socket=/var/run/cri-dockerd.sock

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

# install flannel on master
# I don't use weave because it didn't work when I tested it. the containers it creates were in a faulty state.
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.20.2/Documentation/kube-flannel.yml


# join a node (copy the output string from the kubeadm, not the below one, ad add the cri-socket option below to make it work
sudo kubeadm join 192.168.64.6:6443 --token nr5axz.oh1fg8xmt682mqd3 \
	--discovery-token-ca-cert-hash sha256:56b9a5f80c2ac0bec225540bf7479890b7b7a0e35319e37afce1dd304ee01d51 \
	--cri-socket=/var/run/cri-dockerd.sock

```
