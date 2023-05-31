#Power BI REST API calls. 





#Get List Of DataGateways
$dataGateways= (Invoke-PowerBIRestMethod -Method Get -Url "https://api.powerbi.com/v1.0/myorg/gateways" |ConvertFrom-Json).value  |select-object id,type,name `
,@{ Name = 'gatewayMachine'; Expression = {  ($_.gatewayAnnotation|ConvertFrom-Json).gatewayMachine }}                                        `
,@{ Name = 'gatewayVersion'; Expression = {  ($_.gatewayAnnotation|ConvertFrom-Json).gatewayVersion }}                                        `
,@{ Name = 'gatewayContactInformation'; Expression = {  ($_.gatewayAnnotation|ConvertFrom-Json).gatewayContactInformation }}                  `
,@{ Name = 'gatewayVirtualNetworkSubnetId'; Expression = {  ($_.gatewayAnnotation|ConvertFrom-Json).gatewayVirtualNetworkSubnetId }}

