# Synapse & Power BI Accelerator

This PowerShell script automates the following: 
- Installation of required PowerShell Modules

    [MicrosoftPowerBIMgmt](https://learn.microsoft.com/en-us/powershell/power-bi/overview?view=powerbi-ps)

    [Az.Synapse](https://learn.microsoft.com/en-us/powershell/module/az.synapse)

    [Az.Accounts](https://learn.microsoft.com/en-us/powershell/module/Az.Accounts)

- Creation a Power BI Workspace
- Grants accounts permissions to the Power BI workspace
- Uploads a PBIX file into the Power BI workspace. 
- Modifies the Power BI Dataset Parameter values.
- Creation of a Synapse Linked Service to the Power BI workspace.

## Prerequisite 
- Azure Subscription
- Power BI Subscription with "**Power BI Admin**" role 
- Azure Synapse with at least "**Synapse Linked Data Manager**" role access. 
- Power BI Dataset (PBIX file without visuals) 

## Soution - High Level steps 
1. Initialize script Parameter Values
2. Install any missing Powershell Modules ( MicrosoftPowerBIMgmt, Az.Synapse, Az.Accounts)
3. Log into Azure Service and Power BI Service 
4. Create Power BI Workspace 
5. Get Current list of Power BI Workspace Access and Grant any missing Access
6. Upload Power BI Dataset (PBIX file) to Power BI Workspace 
7. Get Power BI Dataset Parameter Names 
8. Set Power BI Dataset Parameter Values 
9. Create JSON file of Synapse Linked Service definition to Power BI workspace.
10. Create Synapsed Linked Service using the definition file.


## Additional Resources 
If you plan to also configure the data gateway settings after publishing the PBIX files then you can refer to these links. 
https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/get-datasources-in-group

https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/update-datasources-in-group

https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/get-gateway-datasources-in-group

https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/discover-gateways-in-group

https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/bind-to-gateway-in-group
