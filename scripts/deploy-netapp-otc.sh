#!/bin/sh
## Script to Setup NetApp OnCommand Cloud Manager and Deploy Working Environment NetApp ONTAP Cloud on Azure ##

## Arguments : To be passed by Azure Custom Script Extension
region=${1}
otcName=${2}
adminEmail=${3}
adminPassword=${4}
subscriptionId=${5}
azureTenantId=${6}
applicationId=${7}
applicationKey=${8}
vnetID=${9}
cidr=${10}
subnetID=${11}
nsgID=${12}
licenseType=${13}
instanceType=${14}
storageType=${15}
QuickstartNameTagValue=${16}
QuickstartProviderTagValue=${17}

##Variable Values for Setting up OnCommand Manager 
tenantName="azurenetappqs_tenant"
roleID="Role-1"
siteName="AzureQS"
siteCompany="AzureQS"
autoVsaCapacityManagement=true
autoUpgrade=false
## Variable Values for Deploying Working Environment on Azure 
svmPassword="'$adminPassword'"
ontapVersion="ONTAP-9.1.T4.azure"
sqlvolname="sqldatadrive"
sqlvolsize="500"
unit="GB"
snapshotPolicyName="default"

## Downloading jQuery 
sudo wget -O /usr/bin/jq http://stedolan.github.io/jq/download/linux64/jq
sleep 5
sudo chmod +x /usr/bin/jq

## Setup NetApp OnCommand Cloud Manager
curl http://localhost/occm/api/occm/setup/init -X POST --header 'Content-Type:application/json' --header 'Referer:AzureQS' --data '{ "tenantRequest": { "name": "'${tenantName}'", "description": "", "costCenter": "", "nssKeys": {} }, "proxyUrl": { "uri": "" }, "userRequest":{  "email": "'${adminEmail}'","lastName": "user", "firstName":"admin","roleId": "'${roleID}'","password": "'${adminPassword}'", "ldap": "false", "azureCredentials": { "subscriptionId": "'${subscriptionId}'", "tenantId": "'${azureTenantId}'", "applicationId": "'${applicationId}'", "applicationKey": "'${applicationKey}'" }  }, "site": "'${siteName}'", "company": "'${siteCompany}'", "autoVsaCapacityManagement": "'${autoVsaCapacityManagement}'",   "autoUpgrade": "'${autoUpgrade}'" }}'
sleep 40

until sudo wget http://localhost/occmui > /dev/null 2>&1; do sudo wget http://localhost > /dev/null 2>&1 ; done
sleep 60

## Authenticate to NetApp OnCommand CloudManager
curl http://localhost/occm/api/auth/login --header 'Content-Type:application/json' --header 'Referer:AzureQS' --data '{"email":"'${adminEmail}'","password":"'${adminPassword}'"}' --cookie-jar cookies.txt
sleep 5

## Getting the NetApp Tenant ID, to deploy the ONTAP Cloud
tenantId=`sudo curl http://localhost/occm/api/tenants -X GET --header 'Content-Type:application/json' --header 'Referer:AzureQS' --cookie cookies.txt | jq -r .[0].publicId`

## Create a ONTAP Cloud working environment on Azure
curl http://localhost/occm/api/azure/vsa/working-environments -X POST --cookie cookies.txt --header 'Content-Type:application/json' --header 'Referer:AzureQS' --data '{ "name": "'${otcName}'", "svmPassword": "'${svmPassword}'",  "vnetId": "'${vnetID}'",   "cidr": "'${cidr}'",  "description": "", "vsaMetadata": { "ontapVersion": "'${ontapVersion}'", "licenseType": "'${licenseType}'", "instanceType": "'${instanceType}'" }, "volume": { "name": "'${sqlvolname}'", "size": { "size": "'${sqlvolsize}'", "unit": "'${unit}'" }, "snapshotPolicyName": "'${snapshotPolicyName}'", "exportPolicyInfo": { "policyType": "custom", "ips": ["'${cidr}'"] }, "enableThinProvisioning": "'true'", "enableCompression": "false", "enableDeduplication": "false" }, "region": "'${region}'", "tenantId": "'${tenantId}'", "subnetId":"'${subnetID}'", "dataEncryptionType":"NONE", "ontapEncryptionParameters": null, "securityGroupId":"'${nsgID}'", "skipSnapshots": "false", "diskSize": { "size": "1","unit": "TB" }, "storageType": "'${storageType}'", "azureTags": [ { "tagKey": "'quickstartName'", "tagKey": "'${QuickstartNameTagValue}'"}, { "tagKey": "provider", "tagKey": "'${QuickstartProviderTagValue}'"} ],"writingSpeedState": "NORMAL" }' > /tmp/createnetappotc.txt

OtcPublicId=`cat /tmp/createnetappotc.txt | jq -r .publicId`
if [ ${OtcPublicId} = null ] ; then
  message=`cat /tmp/createnetappotc.txt| jq -r .message`
  echo "OCCM setup failed: $message" > /tmp/occmError.txt
  exit 1
fi
sleep 2


## Getting the NetApp Ontap Cloud Cluster Properties

curl 'http://localhost/occm/api/azure/vsa/working-environments/'${OtcPublicId}'?fields=status' -X GET --header 'Content-Type:application/json' --header 'Referer:AzureQS' --cookie cookies.txt > /tmp/envdetails.json
otcstatus=`cat /tmp/envdetails.json | jq -r .status.status`

check_deploymentstatus()
{
curl 'http://localhost/occm/api/azure/vsa/working-environments/'${OtcPublicId}'?fields=status' -X GET --header 'Content-Type:application/json' --header 'Referer:AzureQS' --cookie cookies.txt > /tmp/envdetails.json
otcstatus=`cat /tmp/envdetails.json | jq -r .status.status`
}

until  [ ${otcstatus} = ON ] 
do
  message="Not Deployed Yet, Checking again in 60 seconds"
  echo  ${message}
  sleep 60
  check_deploymentstatus
done

sleep 5

curl 'http://localhost/occm/api/azure/vsa/working-environments/'${OtcPublicId}'?fields=ontapClusterProperties' -X GET --header 'Content-Type:application/json' --header 'Referer:AzureQS' --cookie cookies.txt > /tmp/ontapClusterProperties.json

## grab the Cluster managment LIF IP address
clusterLif=`curl 'http://localhost/occm/api/azure/vsa/working-environments/'${OtcPublicId}'?fields=ontapClusterProperties' -X GET --header 'Content-Type:application/json' --header 'Referer:AzureQS' --cookie cookies.txt |jq -r .ontapClusterProperties.nodes[].lifs[] |grep "Cluster Management" -a2|head -1|cut -f4 -d '"'`
echo "${clusterLif}" > /tmp/clusterLif.txt
## grab the iSCSI data LIF IP address
dataLif=`curl 'http://localhost/occm/api/azure/vsa/working-environments/'${OtcPublicId}'?fields=ontapClusterProperties' -X GET --header 'Content-Type:application/json' --header 'Referer:AzureQS' --cookie cookies.txt |jq -r .ontapClusterProperties.nodes[].lifs[] |grep iscsi -a4|head -1|cut -f4 -d '"'`
echo "${dataLif}" > /tmp/iscsiLif.txt
## grab the NFS and CIFS data LIF IP address
dataLif2=`curl 'http://localhost/occm/api/azure/vsa/working-environments/'${OtcPublicId}'?fields=ontapClusterProperties' -X GET --header 'Content-Type:application/json' --header 'Referer:AzureQS' --cookie cookies.txt |jq -r .ontapClusterProperties.nodes[].lifs[] |grep nfs -a4|head -1|cut -f4 -d '"'`
echo "${dataLif2}" > /tmp/nasLif.txt

# Cluster Ip Addresses Exported in tmp Files
