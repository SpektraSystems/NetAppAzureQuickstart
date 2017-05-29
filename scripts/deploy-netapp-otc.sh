#!/bin/sh
## Argument 1 will be password for Ansible Tower UI Admin  ##
## Argument 2 will be password for Database Admin  ##
## Argument 3 will be username for Client VMs  ##
## Argument 4 will be password for Client Vms  ##
## Argument 5 will be IP address of client VM 1 ##
## Argument 6 will be IP address of client VM 2 ##

region=$1
adminEmail=$2
adminPassword=$3
subscriptionId=$4
azureTenantId=$5
applicationId=$6
applicationKey=$7
vnetID=$8
cidrnew="10.0.0.0/16"
cidrnew=$9
subnetID=$10
nsgID=$11
licenseType=$12
instanceType=$13
storageType=$14
QuickstartNameTagName=15
QuickstartNameTagValue=16
QuickstartProviderTagName=17
QuickstartProviderTagValue=18
otcName=azureqsotc

echo $region
echo $adminEmail
echo $adminPassword
echo $subscriptionId
echo $azureTenantId
echo $applicationId
echo $applicationKey
echo $vnetID
echo $cidr
echo $subnetID
echo $nsgID
echo $licenseType
echo $instanceType
echo $storageType
echo $QuickstartNameTagName
echo $QuickstartNameTagValue
echo $QuickstartProviderTagName
echo $QuickstartProviderTagValue
echo $otcName=azureqsotc


##Fixed Values##
tenantName="azurenetappqs_tenant"
roleID="Role-1"
siteName="AzureQS"
siteCompany="AzureQS"
autoVsaCapacityManagement=true
autoUpgrade=false
## Fixed Values - Deploying Working Env###
svmPassword="'$adminPassword'"
ontapVersion="ONTAP-9.1.T4.azure"
sqlvolname="sqldatadrive"
sqlvolsize="500"
unit="GB"
snapshotPolicyName="default"



sudo wget -O /usr/bin/jq http://stedolan.github.io/jq/download/linux64/jq
sleep 5
sudo chmod +x /usr/bin/jq


## Setup Cloud Manager
curl http://localhost/occm/api/occm/setup/init -X POST --header 'Content-Type:application/json' --header 'Referer:AzureQS' --data '{ "tenantRequest": { "name": "'$tenantName'", "description": "", "costCenter": "", "nssKeys": {} }, "proxyUrl": { "uri": "" }, "userRequest":{  "email": "'$adminEmail'","lastName": "user", "firstName":"admin","roleId": "'$roleID'","password": "'$adminPassword'", "ldap": "false", "azureCredentials": { "subscriptionId": "'$subscriptionId'", "tenantId": "'$azureTenantId'", "applicationId": "'$applicationId'", "applicationKey": "'$applicationKey'" }  }, "site": "'$siteName'", "company": "'$siteCompany'", "autoVsaCapacityManagement": "'$autoVsaCapacityManagement'",   "autoUpgrade": "'$autoUpgrade'" }}'
sleep 40

until sudo wget http://localhost/occmui > /dev/null 2>&1; do sudo wget http://localhost > /dev/null 2>&1 ; done
sleep 60

## Authenticate to Cloud Manager
curl http://localhost/occm/api/auth/login --header 'Content-Type:application/json' --header 'Referer:AzureQS' --data '{"email":"'$adminEmail'","password":"'$adminPassword'"}' --cookie-jar cookies.txt
sleep 5

## Get the Tenant ID so we can create the ONTAP Cloud system in that Cloud Manager Tenant
tenantId=`sudo curl http://localhost/occm/api/tenants -X GET --header 'Content-Type:application/json' --header 'Referer:AzureQS' --cookie cookies.txt | jq -r .[0].publicId`

## Create a ONTAP Cloud working env
curl http://localhost/occm/api/azure/vsa/working-environments -X POST --cookie cookies.txt --header 'Content-Type:application/json' --header 'Referer:AzureQS' --data '{ "name": "'$otcName'", "svmPassword": "'$svmPassword'",  "vnetId": "'$vnetID'",   "cidr": ["'$cidr'"],  "description": "", "vsaMetadata": { "ontapVersion": "'$ontapVersion'", "licenseType": "'$licenseType'", "instanceType": "'$instanceType'" }, "volume": { "name": "'$sqlvolname'", "size": { "size": "'$sqlvolsize'", "unit": "'$unit'" }, "snapshotPolicyName": "'$snapshotPolicyName'", "exportPolicyInfo": { "policyType": "custom", "ips": ['$cidr'] }, "enableThinProvisioning": "'true'", "enableCompression": "false", "enableDeduplication": "false" }, "region": "'$region'", "tenantId": "'$tenantId'", "subnetId":"'$subnetID'", "dataEncryptionType":"NONE", "ontapEncryptionParameters": null, "securityGroupId":"'$nsgID'", "skipSnapshots": "false", "diskSize": { "size": "1","unit": "TB" }, "storageType": "'$storageType'", "azureTags": [ { "tagKey": "'$QuickstartNameTagName'", "tagKey": "'$QuickstartNameTagValue'"}, { "tagKey": "'$QuickstartProviderTagName'", "tagKey": "'$QuickstartProviderTagValue'"} ],"writingSpeedState": "NORMAL" }' > /tmp/createnetappotc.txt
OtcPublicId=`cat /tmp/createnetappotc.txt| jq -r .publicId`
if [ ${OtcPublicId} = null ] ; then
  message=`cat /tmp/createnetappotc.txt| jq -r .message`
  echo "OCCM setup failed: $message" > /tmp/occmError.txt
  exit 1
fi
sleep 2
## Check SRC VSA
waitForAction ${OtcPublicId} 60 1
## grab the Cluster managment LIF IP address
clusterLif=`curl 'http://localhost/occm/api/azure/vsa/working-environments/'${OtcPublicId}'?fields=clusterProperties' -X GET --header 'Content-Type:application/json' --header 'Referer:AWSQS1' --cookie cookies.txt |jq -r .clusterProperties.lifs |grep "Cluster Management" -a2|head -1|cut -f4 -d '"'`
echo "${clusterLif}" > /tmp/clusterLif.txt
## grab the iSCSI data LIF IP address
dataLif=`curl 'http://localhost/occm/api/azure/vsa/working-environments/'${OtcPublicId}'?fields=clusterProperties' -X GET --header 'Content-Type:application/json' --header 'Referer:AWSQS1' --cookie cookies.txt |jq -r .clusterProperties.lifs |grep iscsi -a4|head -1|cut -f4 -d '"'`
echo "${dataLif}" > /tmp/iscsiLif.txt
## grab the NFS and CIFS data LIF IP address
dataLif2=`curl 'http://localhost/occm/api/azure/vsa/working-environments/'${OtcPublicId}'?fields=clusterProperties' -X GET --header 'Content-Type:application/json' --header 'Referer:AWSQS1' --cookie cookies.txt |jq -r .clusterProperties.lifs |grep nfs -a4|head -1|cut -f4 -d '"'`
echo "${dataLif2}" > /tmp/nasLif.txt

# Remove passwords from files
sed -i s/${adminPassword}/xxxxx/g /var/log/cloud-init.log
sed -i s/${svmPassword}/xxxxx/g /var/log/cloud-init.log
