# NetAppAzureQuickstart on Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FSpektraSystems%2FNetAppAzureQuickstart%2Fmaster%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FSpektraSystems%2FNetAppAzureQuickstart%2Fmaster%2Fazuredeploy.json" target="_blank">
<img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png"/>
</a> 
<br><br>
NetApp ONTAP Cloud on Azure Quickstart



<!-- TOC -->

1. [Solution Overview](#solution-overview)
2. [Template Solution Architecture ](#template-solution-architecture)
3. [Licenses and Costs ](#licenses-and-costs)
4. [Prerequisites](#prerequisites)
5. [Deployment Steps](#deployment-steps)
6. [Deployment Time](#deployment-time)
7. [Support](#support)


<!-- /TOC -->

## Solution Overview 


## Template Solution Architecture 

This template will deploy: 

- 	Six storage accounts 
-	One Virtual Network with two subnets
-	2 Public IP’s, one for OnCommand Manager and one for the Jump VM
-	One OnCommand Cloud Manager (BYOL)(for ONTAP Cloud)
-	One Windows Server 2012 R2 VM.
-	One SQL Server 2014 SP2 Enterprise on Windows Server 2012 R2 VM.
-	One NetApp ONTAP Cloud VM

<img src="https://raw.githubusercontent.com/Jithin-Varghese/Documentation-Images/master/netapp%20architecture.png"/>

## Licenses and Costs 

This NetApp ONTAP Cloud is the PAYGO model and doesn't require the user to license it, it will be licensed automatically after the instance is launched first time and user will be charged hourly. Click [here]( https://azuremarketplace.microsoft.com/en-us/marketplace/apps/netapp.netapp-ontap-cloud?tab=Overview) for pricing details.

## Prerequisites 

Azure Subscription with specified payment method (NetApp ONTAP cloud is a market place product and requires payment method to be specified in Azure Subscription)

## Deployment Steps  

Build your NetApp ONTAP environment on Azure in a few simple steps:
- Create an Active Directory Application.
- Create an Application Key
- Assigning the Cloud Manager role to AD application
- Enable programmatic deployment for NetApp ONTAP Cloud for Azure – (PAYGo)
- Launch the Template by click on Deploy to Azure button.  
- Fill in all the required parameter values. Accept the terms and condition and click on Purchase. 

## Deployment Time  

The deployment takes about 1 hour. 

## Support 

For any support related questions, issues or customization requirements, please contact info@spektrasystems.com
