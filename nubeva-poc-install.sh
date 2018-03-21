#!/bin/bash

set -e

# trap exit commands to force them to run cleanup first
trap cleanup_artefacts SIGINT


#set arguement equal to resource group
NAME=
REGION=
OFFER=live
PASSWORD=G0Nub3va20[]
DELETE=false
DEV=false

TEMPLATE_URL=https://raw.githubusercontent.com/ejfree/nubevapoc/master
TEMPLATE=azuretemplatev8.json

# Display the help message for the script
help () {
    echo ""
    echo "Nubeva Proof-of-Concept (POC) enviroment launching script"
    echo "---------"
    echo "| USAGE |"
    echo "---------"
    echo "CREATE: ./nubeva-poc-install -n nubevapoc -r westus -p NubevaCustomPass!"
    echo "DELETE: ./nubeva-poc-install -n nubevapoc -r westus -d"
    echo ""
    echo "-------------"
    echo "| ARGUMENTS |"
    echo "-------------"
    echo "-n|--name <name>"
    echo "    REQUIRED"
    echo "    The name of the POC resource group to create/delete"
    echo "-r|--region <region>"
    echo "    CONDITIONAL (Required for create only)"
    echo "    The region to use for the POC resource group"
    echo "-o|--offer <preview|live>"
    echo "    Indicates whether to use the latest preview controller version"
    echo "    or the live marketplace offer. Preview requires whitelisting.  Defaults to $OFFER."
    echo "-d|--delete"
    echo "    Flag to schedule a delete of a POC environment, if not specified goes to"
    echo "    create by default"
    echo "-p|--password <password>"
    echo "    Manually override the environment password, default is '$PASSWORD'"
    echo "-h|--help"
    echo "    Display this help message"
    echo ""

    #  Undocumented options:
    #  --dev
    #      Uses the nubeva development, "master" version.
    #      Requires whitelisting to launch.
}

# Delete a resource group with a given name, to run pass in a -d|--delete flag
delete () {
    read -p "Are you sure you would like to delete resource group '$NAME'? [y/n]: " -r
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo ""
        echo "Running: 'az group delete --name $NAME'"
        echo ""
        az group delete --name $NAME
    fi
}

# Create a resource group with a give name in a given region (-n|--name, -r|--region)
create () {
    echo "Setting offer parameters"
    #create resource group
    OFFERBASE="controller"
    if $DEV
    then
        OFFERBASE="controller-dev"
    fi
    if [[ $OFFER == 'preview' ]]; then
        PARAMETERS_STR="{'marketplaceControllerOffer': {'value': '$OFFERBASE-preview'}}"
    elif [[ $OFFER == 'live' ]]; then
        PARAMETERS_STR="{'marketplaceControllerOffer': {'value': '$OFFERBASE'}}"
    else
        echo "Unknown argument '$OFFER' provided to --offer|-o flag. Please provide either 'live' or 'preview'"
        exit 1
    fi

    echo Creating Resource Group
    az group create --name $NAME --location $REGION

    #deploy azure template
    # Use local template to deploy
    echo Deploying Azure Template

    if [ -e "$TEMPLATE" ]
    then
        echo "from local file"
        az group deployment create -g $NAME --template-file "$TEMPLATE" --parameters "$PARAMETERS_STR"
    else
        echo "from $TEMPLATE_URL"
        az group deployment create -g $NAME --template-uri $TEMPLATE_URL/$TEMPLATE --parameters "$PARAMETERS_STR"
    fi
    
    #create 5 Vms: n+1 source machines
    echo Creating Source, Dest, and Bastion VMs and continuing.....
    az vm create --name source1 --resource-group $NAME --image UbuntuLTS  --admin-username nubeva  --admin-password $PASSWORD  --authentication-type password  --no-wait --nics source1VNIC
    az vm create --name source2 --resource-group $NAME --image UbuntuLTS  --admin-username nubeva  --admin-password $PASSWORD  --authentication-type password  --no-wait --nics source2VNIC
    az vm create --name dest --resource-group $NAME --image UbuntuLTS  --admin-username nubeva  --admin-password $PASSWORD  --authentication-type password  --no-wait --nics destVNIC
    az vm create --name bastion --resource-group $NAME --image UbuntuLTS  --admin-username nubeva  --admin-password $PASSWORD  --authentication-type password  --no-wait --nics bastionVNIC

    echo Creating Peer VM and waiting.....
    az vm create --name peer --resource-group $NAME --image UbuntuLTS  --admin-username nubeva  --admin-password $PASSWORD  --authentication-type password --nics  peer-outsideVNIC peer-insideVNIC
    az vm create --name windows --resource-group $NAME --image win2016datacenter  --admin-username nubeva  --admin-password $PASSWORD --subnet bastion --vnet-name nubevapoc-vnet


    #Update route table, IP forwarding, and enable outbound NAT w/masquerade on Peer VM
    echo Modifying Peer Routes, Forwarding, and NAT.
    az vm extension set --resource-group $NAME --vm-name peer --name customScript --publisher Microsoft.Azure.Extensions --settings '{"fileUris": ["https://raw.githubusercontent.com/ejfree/nubevapoc/master/routemod.sh"],"commandToExecute": "./routemod.sh"}'
    az vm extension set --resource-group $NAME --vm-name bastion --name customScript --publisher Microsoft.Azure.Extensions --settings '{"fileUris": ["https://raw.githubusercontent.com/ejfree/nubevapoc/master/add_vxlan.sh"],"commandToExecute": "./add_vxlan.sh"}'
    #Below doesnt work yet. 
    #az vm extension set --resource-group $NAME --vm-name windows --name customScript --publisher Microsoft.Azure.Extensions --settings '{"fileUris": ["https://raw.githubusercontent.com/ejfree/nubevapoc/master/Post-Install.ps1"],"commandToExecute": "Post-Install.ps1"}'
}


# Argparsing
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        --dev)
            DEV=true
            echo "Dev work specified, switching to preview offer.  Override with -o switch _after_ --dev switch."
            if [ "$OFFER" == "live" ]
            then
                OFFER="preview"
            fi
            shift
            ;;
        -d|--delete)
            DELETE=true
            shift
            ;;
        -h|--help)
            help
            exit 0
            ;;
        -n|--name)
            NAME=$2
            shift
            shift
            ;;
        -r|--region)
            REGION=$2
            shift
            shift
            ;;
        -o|--offer)
            OFFER=$2
            shift
            shift
            ;;
        -p|--password)
            PASSWORD=$2
            shift
            shift
            ;;
        *)
            echo "Unknown argument '$key', skipping..."
            shift
            ;;
    esac
done

#echo "DELETE   = $DELETE"
#echo "REGION   = $REGION"
#echo "NAME     = $NAME"
#echo "PASSWORD = $PASSWORD"

if [ -z "$NAME" ]
then
    echo "Required argument resource group name is unset, please specify using '-n <name>'"
    exit 1
fi

if [ "$DELETE" = true ]
then
    delete
else
    if [ -z "$REGION" ]
    then
        echo "Required argument region is unset, please specify using '-r <region>'"
        exit 1
    fi
    create
fi

