# Template Folder Structure

Each template directory contains the following items:
- Reamde.md: A README file for the template that contains any prerequisites, general information and links to deploy to Azure.
- azuredeploy.json: The main ARM template file that contains all the resources to be deployed to Azure.
- ARM-Templates: Folder that contains ARM template files broken into separate nested templates for each major part of the deployment
- Bicep-Templates: Folder that contains Bicep templates files that can be used to deploy the resources.