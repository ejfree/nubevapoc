# nubevapoc
Nubeva Proof of Concept Files

## Usage
Uses whatever account you are logged into currently with 'az login'

### Create Example 
`./nubeva-poc-install -n nubevapoc -r westus -p NubevaCustomPass!`

### Delete Example 
`./nubeva-poc-install -n nubevapoc -d`

### Arguments
```
-n|--name <name>
    REQUIRED
    The name of the POC resource group to create/delete
-r|--region <region>
    CONDITIONAL (Required for create only)
    The region to use for the POC resource group
-d|--delete
    Flag to schedule a delete of a POC environment, if not specified goes to
    create by default
-p|--password <password>
    Manually override the password for all devices, default is 'G0Nub3va20[]'
-o|--offer <preview|live>
    Choose whether to use preview version of the Controller or live.
-h|--help
    Display this help message
```
