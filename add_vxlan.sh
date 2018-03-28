#!/bin/sh

#Add OVS and vxlan interface to bastion.
sudo apt-get update -y
sudo apt-get install openvswitch-common -y
sudo apt-get install openvswitch-switch -y
sudo ovs-vsctl add-br br2
sudo ovs-vsctl add-port br2 vxlan0 -- set interface vxlan0 type=vxlan options:remote_ip=10.10.200.10
sudo ovs-vsctl add-port br2 vxlan1 -- set interface vxlan1 type=vxlan options:remote_ip=10.10.200.11
