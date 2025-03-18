# Heading Exporting data to Excel files in Azure Data Factory (ADF) and Azure Synapse Analytics

The support for Excel files Azure Data Factory (ADF) and Azure Synapse Analytics *["is supported as source but not sink."](https://learn.microsoft.com/en-us/azure/data-factory/format-excel)* You can read from an excel file but can not write/export to an excel file. 

To get around this, you will have to output the data to a CSV file and then convert the CSV to an Excel file externally to ADF and have ADF call the External process with the ADF Activities such as [Azure Logic App](https://learn.microsoft.com/en-us/archive/msdn-technet-forums/a08b6d3a-f492-4f26-9309-e172553e9fdf), Azure Function, Notebooks, and Execute SSIS Package Activity. 

This solution uses SQL Server Integration Services (SSIS) Package to perform the CSV to Excel file conversion and will use the Azure SSIS-IR Integration runtime. 

## High Level Steps

 1. [Create an Azure-SSIS integration runtime](https://learn.microsoft.com/en-us/azure/data-factory/create-azure-ssis-integration-runtime-portal?tabs=data-factory) (**Recommended**:  use SSISDB catalog as deployment option) 
 2. [Deploy the SSIS package](https://learn.microsoft.com/en-us/azure/data-factory/create-azure-ssis-integration-runtime-deploy-packages) 
 4. [Run an SSIS package with the Execute SSIS Package activity](https://learn.microsoft.com/en-us/azure/data-factory/how-to-invoke-ssis-package-ssis-activity?tabs=data-factory)


## Leasons Learned
 - You will need to develop the SSIS Visual Studio solution targeted for **[SQL Server 2017](https://learn.microsoft.com/en-us/azure/data-factory/media/how-to-invoke-ssis-package-ssis-activity/ssdt-connection-manager-properties.png)**
   Since the SSIS-IR is like a self-managed Virtual Machine, which contains the SSIS 2017 Control Flow and Data Flow components. Targeting to a recent version will not work when it comes to running in ADF.    
 - SSIS can not create an Excel file, but it can write to an existing one. So you will need to store an empty Excel file and copy it to a new file name, then populate the new excel file. 
 - Folder Paths for the destination files will be different if running locally on your computer during SSIS pacakge development and different once deployed to Azure. 
    
## SSIS Solution
1. Install Visual Studio Extension for SSIS development 
	- for Visual Studio 2019 install [SQL Server Integration Services Projects](https://marketplace.visualstudio.com/items?itemName=SSIS.SqlServerIntegrationServicesProjects)
	- for Visual Studio 2022 install [SQL Server Integration Services Projects 2022](https://marketplace.visualstudio.com/items?itemName=SSIS.MicrosoftDataToolsIntegrationServices)
2. Install [SQL Server 2017 Integration Services Feature Pack for Azure](https://download.microsoft.com/download/e/e/0/ee0cb6a0-4105-466d-a7ca-5e39fa9ab128/SsisAzureFeaturePack_SQL2017.msi) 
3. Upload an Empty Excel (.XLSX) file to an Azure storage location. Restrict user access to this location to prevent accident deletion of the file as the solution will not work if file is deleted.
4. Download the SSIS solution from this repo and modify to your environment and reference the empty Excel file from previous step.  

The SSIS package screenshot is shown below. 
 ![image](https://github.com/user-attachments/assets/c7374cb2-9062-4503-ba6b-897b1201f411)
