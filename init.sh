#!/usr/bin/env bash
# Copyright (c) 2017, cloudcodeit.com
#
#  Purpose: Initialize an Azure Virtual Machine for Ansible Play
#  Usage:
#    init.sh <unique> <server_count>


###############################
## ARGUMENT INPUT            ##
###############################
usage() { echo "Usage: init.sh <unique> <count>" 1>&2; exit 1; }

if [ -f ~/.azure/.env ]; then source ~/.azure/.env; fi
if [ -f ./.env ]; then source ./.env; fi
if [ -f ./functions.sh ]; then source ./functions.sh; fi


if [ ! -z $1 ]; then UNIQUE=$1; fi
if [ -z $UNIQUE ]; then
  tput setaf 1; echo 'ERROR: UNIQUE not found' ; tput sgr0
  usage;
fi
if [ -z ${AZURE_LOCATION} ]; then
  tput setaf 1; echo 'ERROR: Global Variable AZURE_LOCATION not set'; tput sgr0
  exit 1;
fi

if [ ! -z $2 ]; then COUNT=$2; fi
if [ -z $COUNT ]; then
  COUNT=1
fi

###############################
## Azure Intialize           ##
###############################
tput setaf 2; echo 'Logging in and setting subscription...' ; tput sgr0
az account set --subscription ${AZURE_SUBSCRIPTION}


##############################
## Resource Group Deploy ##
##############################
CATEGORY=${PWD##*/}
RESOURCE_GROUP=${UNIQUE}-${CATEGORY}
CONTAINER='rexray'

tput setaf 2; echo "Creating the $RESOURCE_GROUP resource group..." ; tput sgr0
CreateResourceGroup ${RESOURCE_GROUP} ${AZURE_LOCATION};
az group show --name ${RESOURCE_GROUP} -ojsonc

# tput setaf 2; echo "Deploying Template..." ; tput sgr0
az group deployment create \
  --resource-group ${RESOURCE_GROUP} \
  --template-file arm-templates/deployAzure.json \
  --parameters @arm-templates/deployAzure.params.json \
  --parameters unique=${UNIQUE} serverCount=${COUNT} \
  -ojsonc

tput setaf 2; echo "Creating the $CONTAINER blob container..." ; tput sgr0
STORAGE_ACCOUNT=$(GetStorageAccount $RESOURCE_GROUP)
CONNECTION=$(GetStorageConnection $RESOURCE_GROUP $STORAGE_ACCOUNT)
CreateBlobContainer $CONTAINER $CONNECTION

##############################
## Create Ansible Inventory ##
##############################
INVENTORY="./ansible/inventories/azure/"
mkdir -p ${INVENTORY};


tput setaf 2; echo "Retrieving IP Address ..." ; tput sgr0

IP=$(az vm list-ip-addresses \
    --resource-group ${RESOURCE_GROUP}  \
    --query [].virtualMachine.network.publicIpAddresses[].ipAddress -otsv)
echo ${IP}
tput setaf 2; echo 'Creating the ansible inventory files...' ; tput sgr0
cat > ${INVENTORY}/hosts << EOF
[all]
$(az network public-ip list --resource-group ${RESOURCE_GROUP} --query [].ipAddress -otsv)
EOF

tput setaf 2; echo 'Creating the ansible config file...' ; tput sgr0
cat > ansible.cfg << EOF1
[defaults]
inventory = ${INVENTORY}/hosts
private_key_file = ~/.ssh/id_rsa
host_key_checking = false
EOF1
