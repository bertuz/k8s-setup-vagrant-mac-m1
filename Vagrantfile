# -*- mode: ruby -*-
# vi:set ft=ruby sw=2 ts=2 sts=2:

# Define the number of master and worker nodes
# If this number is changed, remember to update setup-hosts.sh script with the new hosts IP details in /etc/hosts of each VM.
NUM_MASTER_NODE = 1
# max 7 to make this script work
NUM_WORKER_NODE = 1

IP_NW = "192.168.64."
MASTER_IP_START = 1
NODE_IP_START = 2

Vagrant.configure("2") do |config|
  config.vm.box = "perk/ubuntu-2204-arm64"
  config.vm.box_check_update = false

  config.vm.provider "qemu" do |qe|
    #qe.extra_netdev_args = "net=192.168.51.0/24,dhcpstart=192.168.51.10"
    #qe.net_device="virtio-net,netdev=vlan0"
    #qe.extra_qemu_args = %w(-netdev vmnet-shared,id=net1 -netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9)

  end
 #
 # Provision Master Nodes
  (1..NUM_MASTER_NODE).each do |i|
      config.vm.define "kubemaster" do |node|
        # Name shown in the GUI
        node.vm.provider "qemu" do |vb|
            vb.name = "kubemaster"
            vb.memory = 2048
            vb.cpus = 2
            vb.ssh_port = 2035
            vb.extra_qemu_args = "-M accel=hvf -netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9 -netdev vmnet-shared,id=mynet1 -device virtio-net-pci,netdev=mynet1,mac=54:54:00:55:55:5#{i}".split
        end

        node.vm.hostname = "kubemaster#{i}"
        node.vm.provision "setup-dns", type: "shell", :path => "ubuntu/update-dns.sh"

        node.vm.provision "setup-networking", :type => "shell", :path => "ubuntu/vagrant/setup-networking.sh" do |s|
          s.args = ["enp0s1", IP_NW + "#{MASTER_IP_START + i}", IP_NW + "1", NUM_MASTER_NODE, NUM_WORKER_NODE, IP_NW, MASTER_IP_START, NODE_IP_START]
        end
        
        # ignored
        node.vm.network :private_network, ip: IP_NW + "#{MASTER_IP_START + i}"
      end
  end



  # Provision Worker Nodes
  (1..NUM_WORKER_NODE).each do |i|
    config.vm.define "kubenode#{i}" do |node|
        node.vm.provider "qemu" do |vb|
            vb.name = "kubenode#{i}"
            vb.memory = 2048
            vb.cpus = 2
            vb.ssh_port = 2039
            vb.extra_qemu_args = "-M accel=hvf -netdev user,id=mynet0,net=192.168.76.0/24,dhcpstart=192.168.76.9 -netdev vmnet-shared,id=mynet1 -device virtio-net-pci,netdev=mynet1,mac=54:54:00:55:54:5#{i}".split
        end
        node.vm.hostname = "kubenode#{i}"

        node.vm.provision "setup-networking", :type => "shell", :path => "ubuntu/vagrant/setup-networking.sh" do |s|
          s.args = ["enp0s1", IP_NW + "#{MASTER_IP_START + i}", IP_NW + "1", NUM_MASTER_NODE, NUM_WORKER_NODE, IP_NW, MASTER_IP_START, NODE_IP_START]
        end

        node.vm.provision "setup-dns", type: "shell", :path => "ubuntu/update-dns.sh"
    end
  end
end


