#!/bin/sh

#set arguement equal to resource group
#resource_group=$1



#create 4 Vms
#az vm create --name source --resource-group $resource_group --image UbuntuLTS  --admin-username nubeva  --admin-password G0Nub3va20[]  --authentication-type password  --no-wait --nics sourceVNIC
#az vm create --name dest --resource-group $resource_group --image UbuntuLTS  --admin-username nubeva  --admin-password G0Nub3va20[]  --authentication-type password  --no-wait --nics destVNIC
#az vm create --name bastion --resource-group $resource_group --image UbuntuLTS  --admin-username nubeva  --admin-password G0Nub3va20[]  --authentication-type password  --no-wait --nics bastionVNIC
#az vm create --name peer --resource-group $resource_group --image UbuntuLTS  --admin-username nubeva  --admin-password G0Nub3va20[]  --authentication-type password  --no-wait --nics  peer-outsideVNIC peer-insideVNIC


#save for later run post commands on peer
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo ip route add 10.10.0.0/16 via 10.11.1.1
