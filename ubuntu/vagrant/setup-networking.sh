#!/bin/bash
set -e
IFNAME=$1
IP_ADDRESS=$2
DEFAULT_GATEWAY=$3
NUM_MASTER_NODE=$4
NUM_WORKER_NODE=$5
IP_NW=$6
MASTER_IP_START=$7
NODE_IP_START=$8

apt-get update
apt-get install net-tools
ifconfig ${IFNAME} up
ifconfig ${IFNAME} ${IP_ADDRESS}	

sudo ip route add default via ${DEFAULT_GATEWAY} dev ${IFNAME}

for (( i=1; i<=$NUM_MASTER_NODE; i++ ))
do  
	echo "${IP_NW}$(($MASTER_IP_START + $i))	kubemaster${i}" >> /etc/hosts
done

for (( i=1; i<=$NUM_WORKER_NODE; i++ ))
do  
	echo "${IP_NW}$(($NODE_IP_START + $i))	kubenode${i}" >> /etc/hosts
done

