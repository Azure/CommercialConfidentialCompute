# Release Policy Encode

## Overview
When creating a new encryption key in the Azure Key Vault, a key release policy must be provided so that the key will only be released to AMD ACC VM with the proper configuration. Using the Azure CLI, the key release policy can be refrenced in the command, however when using templates to deploy the key release policy must be Base64URL encoded.

The PowerShell script Get-EncodedReleasePolicy.ps1 can be used to encode the key release policy by passing the key release policy JSON file as a parameter.

`Get-EncodedReleasePolicy.ps1 -fpath .\skr-policy.json`