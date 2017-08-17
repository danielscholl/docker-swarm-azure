###############################
## FUNCTIONS                 ##
###############################
function CreateResourceGroup() {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = LOCATION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (LOCATION) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az group show --name $1)
  if [ "$_result"  == "" ]
    then
      OUTPUT=$(az group create --name $1 \
        --location $2 \
        -ojsonc)
    else
      tput setaf 3;  echo "Resource Group $1 already exists."; tput sgr0
    fi
}
function CreateStorageAccount() {
  # Required Argument $1 = RESOURCE_GROUP

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi

  local _storage=$(az group deployment create \
    --resource-group $1 \
    --template-file 'templates/nested/deployStorageAccount.json' \
    --query [properties.outputs.storageAccount.value.name] -otsv)

  echo $_storage
}
function GetStorageAccount() {
  # Required Argument $1 = RESOURCE_GROUP

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received' ; tput sgr0
    exit 1;
  fi

  local _storage=$(az storage account list --resource-group $1 --query [].name -otsv)
  echo ${_storage}
}
function GetStorageConnection() {
  # Required Argument $1 = RESOURCE_GROUP
  # Required Argument $2 = STORAGE_ACCOUNT

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (STORAGE_ACCOUNT) not received'; tput sgr0
    exit 1;
  fi

  local _result=$(az storage account show-connection-string \
    --resource-group $1 \
    --name $2\
    --query connectionString \
    --output tsv)

  echo $_result
}
function CreateBlobContainer() {
  # Required Argument $1 = CONTAINER_NAME
  # Required Argument $2 CONNECTION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (CONTAINER_NAME) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (STORAGE_CONNECTION) not received' ; tput sgr0
    exit 1;
  fi

 az storage container create --name $1 \
    --connection-string $2 \
    -ojsonc 1>&2;
}
function CreateSASToken() {
  # Required Argument $1 CONTAINER_NAME
  # Required Argument $2 = CONNECTION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (CONTAINER_NAME) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (CONNECTION) not received' ; tput sgr0
    exit 1;
  fi

  local _expire=$(date -v+30M -u +%Y-%m-%dT%H:%MZ)
  local _token=$(az storage container generate-sas --name $1 \
  --expiry ${_expire} \
  --permissions r \
  --connection-string $2 \
  --output tsv)
  echo ${_token}
}
function GetUrl() {
  # Required Argument $1 = BLOB_NAME
  # Required Argument $2 = TOKEN
  # Required Argument $3 CONTAINER_NAME
  # Required Argument $4 = CONNECTION

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (BLOB_NAME) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (TOKEN) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $3 ]; then
    tput setaf 1; echo 'ERROR: Argument $3 (CONTAINER_NAME) not received' ; tput sgr0
    exit 1;
  fi
  if [ -z $4 ]; then
    tput setaf 1; echo 'ERROR: Argument $4 (CONNECTION) not received' ; tput sgr0
    exit 1;
  fi

  local _url=$(az storage blob url --name $1.json \
    --container-name $3 \
    --connection-string $4 \
    --output tsv)
  echo ${_url}?$2
}
function GetParams() {
  # Required Argument $1 = TOKEN

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (TOKEN) not received' ; tput sgr0
    exit 1;
  fi

  local _params="uniquePrefix=${UNIQUE} sasToken=?$1"

  echo ${_params}
}
function CreateVirtualMachine() {
  # Required Argument $1 = VM_NAME
  # Required Argument $2 = RESOURCE_GROUP

  if [ -z $1 ]; then
    tput setaf 1; echo 'ERROR: Argument $1 (VM_NAME) not received'; tput sgr0
    exit 1;
  fi
  if [ -z $2 ]; then
    tput setaf 1; echo 'ERROR: Argument $2 (RESOURCE_GROUP) not received'; tput sgr0
    exit 1;
  fi


  local _result=$(az vm show --name $1 --resource-group $2 -ojsonc)
  if [ "$_result"  == "" ]
    then
      az vm create -n $1 --resource-group $2 --image UbuntuLTS -ojsonc
    else
      tput setaf 3;  echo "Virtual Machine $1 already exists."; tput sgr0
    fi
}
