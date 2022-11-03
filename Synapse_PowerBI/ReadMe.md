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

