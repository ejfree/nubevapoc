#!/bin/sh

#set arguement equal to resource group
resource_group=$1
location=$2

#create resource group
echo Creating Resoure Group
az group create --name $1 --location $2



#deploy azure template
echo Deploying Azure Template
az group deployment create -g $1 --template-uri https://raw.githubusercontent.com/ejfree/nubevapoc/master/azuretemplate.json


#create 4 Vms
echo Creating Source, Dest, and Bastion VMs and continuing.....
az vm create --name source --resource-group $resource_group --image UbuntuLTS  --admin-username nubeva  --admin-password G0Nub3va20[]  --authentication-type password  --no-wait --nics sourceVNIC
az vm create --name dest --resource-group $resource_group --image UbuntuLTS  --admin-username nubeva  --admin-password G0Nub3va20[]  --authentication-type password  --no-wait --nics destVNIC
az vm create --name bastion --resource-group $resource_group --image UbuntuLTS  --admin-username nubeva  --admin-password G0Nub3va20[]  --authentication-type password  --no-wait --nics bastionVNIC

echo Creating Peer VM and waiting.....
az vm create --name peer --resource-group $resource_group --image UbuntuLTS  --admin-username nubeva  --admin-password G0Nub3va20[]  --authentication-type password --nics  peer-outsideVNIC peer-insideVNIC


#Update route table, IP forwarding, and enable outbound NAT w/masquerade on Peer VM
echo Modifying Peer Routes, Forwarding, and NAT.
az vm extension set --resource-group $1 --vm-name peer --name customScript --publisher Microsoft.Azure.Extensions --settings '{"fileUris": ["https://raw.githubusercontent.com/ejfree/nubevapoc/master/routemod.sh"],"commandToExecute": "./routemod.sh"}'
az vm extension set --resource-group $1 --vm-name bastion --name customScript2 --publisher Microsoft.Azure.Extensions --settings '{"fileUris": ["https://raw.githubusercontent.com/ejfree/nubevapoc/master/add_vxlan.sh"],"commandToExecute": "./add_vxlan.sh"}'
