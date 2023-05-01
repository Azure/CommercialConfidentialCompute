# Azure Confidential Compute VM with Platform Managed Key
</br>
This template will deploy a defined number of ACC VMs, using a Customer Managed Key in a Azure Key Vault for encryption, along with a new Virtual Network and Bastion Host.
</br></br>

## Prerequisites

### Create Confidential VM Orchestrator Service Principal
The Azure Confidential Compute SKU VMs require an Azure AD Service Principal to be created for the Confidential VM Orchestrator service. This service principal is granted permissions with the encryption key in the Azure Key Vault to encrypt and decrypt the VM. This service principal is created using the [Azure Graph Powershell](https://learn.microsoft.com/powershell/microsoftgraph/overview?view=graph-powershell-1.0) commands below.

`Connect-Graph -Tenant "your tenant ID" Application.ReadWrite.All`

`New-MgServicePrincipal -AppId "bf7b6499-ff71-4aa2-97a4-f372087be7f0" -DisplayName "Confidential VM Orchestrator"`

### Get Confidential VM Orchestrator Object ID for Deployment
Once the service principal is created, the unique per tenent Object ID of the Service Principal will need to be identified and provided as part of the template deployment to assign permissions with the Azure Key Vault.

`$cvmAgent = az ad sp show --id "bf7b6499-ff71-4aa2-97a4-f372087be7f0" | Out-String | ConvertFrom-Json`

`$cvmAgent.id`

</br>

## Deploy
</br>

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2FCommercialConfidentialCompute%2Fmain%2Ftemplates%2F02-ACC-VM-AKV-CMK%2Fazuredeploy.json%3Ftoken%3DGHSAT0AAAAAABTVTKMABLLEZSW673SVDUWMYTS7DDA)