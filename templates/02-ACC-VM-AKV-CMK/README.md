# Azure Confidential Compute VM with Platform Managed Key
</br>
This template will deploy a defined number of ACC VMs, using a Customer Managed Key in a Azure Key Vault for encryption, along with a new Virtual Network and Bastion Host.
</br></br>

## Prerequisites

### Create Confidential VM Orchestrator Service Principal
The Azure Confidential Compute SKU VMs require an Azure AD Service Principal to be created for the Confidential VM Orchestrator service. This service principal is granted permissions with the encryption key in the Azure Key Vault to encrypt and decrypt the VM.

`Connect-AzureAD -Tenant "Your-Tenant-ID"`

`New-AzureADServicePrincipal -AppId bf7b6499-ff71-4aa2-97a4-f372087be7f0 -DisplayName "Confidential VM Orchestrator"`

### Get Confidential VM Orchestrator Object ID for Deployment
Once the service principal is created, the unique per tenent Object ID of the Service Principal will need to be identified and provided as part of the template deployment to assign permissions with the Azure Key Vault.

`(az ad sp show --id "bf7b6499-ff71-4aa2-97a4-f372087be7f0" | Out-String | ConvertFrom-Json).objectId`
