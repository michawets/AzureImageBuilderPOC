# Step 1: Connect
Connect-AzAccount
Get-AzSubscription | Out-GridView -PassThru | Select-AzSubscription

# Step 2: get existing context
$currentAzContext = Get-AzContext

# destination image resource group
$imageResourceGroup = "myimagebuilder-rg"

# location (see possible locations in main docs)
$location = "westeurope"

## if you need to change your subscription: Get-AzSubscription / Select-AzSubscription -SubscriptionName 

# get subscription, this will get your current subscription
$subscriptionID = $currentAzContext.Subscription.Id

# name of the image to be created
$imageName = "Win1020h1"

# image distribution metadata reference name
$runOutputName = "win1020h1ManImg01ro"

# image template name
$imageTemplateName = "window1020h1Template01"

# distribution properties object name (runOutput), i.e. this gives you the properties of the managed image on completion
$runOutputName = "winSvrSigR01"

# create resource group for image and image template resource
if ($null -eq (Get-AzResourceGroup -Name $imageResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $imageResourceGroup -Location $location
}

# setup role def names, these need to be unique
$imageRoleDefName = "Azure Image Builder Image Def"
$idenityName = "aibIdentity"

## Add AZ PS module to support AzUserAssignedIdentity
if ($null -eq (Get-Module -ListAvailable Az.ManagedServiceIdentity)) {
    Install-Module -Name Az.ManagedServiceIdentity
}

# create identity
if ($null -eq (Get-AzUserAssignedIdentity -Name $idenityName -ResourceGroupName $imageResourceGroup -ErrorAction SilentlyContinue)) {
    New-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName
}

$idenityNameResourceId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).Id
$idenityNamePrincipalId = $(Get-AzUserAssignedIdentity -ResourceGroupName $imageResourceGroup -Name $idenityName).PrincipalId

#Check Custom Role definition
if ($null -eq (Get-AzRoleDefinition -Name $imageRoleDefName -ErrorAction SilentlyContinue)) {
    #Custom Role definition does not exist. Creating now...
    $aibRoleImageCreationUrl = "https://raw.githubusercontent.com/danielsollondon/azvmimagebuilder/master/solutions/12_Creating_AIB_Security_Roles/aibRoleImageCreation.json"
    $aibRoleImageCreationPath = "aibRoleImageCreation.json"

    # download config
    Invoke-WebRequest -Uri $aibRoleImageCreationUrl -OutFile $aibRoleImageCreationPath -UseBasicParsing

    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<subscriptionID>', $subscriptionID) | Set-Content -Path $aibRoleImageCreationPath
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $aibRoleImageCreationPath
    ((Get-Content -path $aibRoleImageCreationPath -Raw) -replace 'Azure Image Builder Service Image Creation Role', $imageRoleDefName) | Set-Content -Path $aibRoleImageCreationPath

    # create role definition
    New-AzRoleDefinition -InputFile  ./aibRoleImageCreation.json
    ### NOTE: If you see this error: 'New-AzRoleDefinition: Role definition limit exceeded. No more role definitions can be created.' See this article to resolve: https://docs.microsoft.com/en-us/azure/role-based-access-control/troubleshooting
}

#Check Role Assignment
if ($null -eq (Get-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup" -ErrorAction SilentlyContinue)) {
    # grant role definition to image builder service principal
    New-AzRoleAssignment -ObjectId $idenityNamePrincipalId -RoleDefinitionName $imageRoleDefName -Scope "/subscriptions/$subscriptionID/resourceGroups/$imageResourceGroup"
}


# update AIB image config template
$templateUrl = "https://raw.githubusercontent.com/michawets/AzureImageBuilderPOC/master/clean_template_win1020h1.json"
$templateFilePath = "helloImageTemplateWin01.json"

# download configs
Invoke-WebRequest -Uri $templateUrl -OutFile $templateFilePath -UseBasicParsing

((Get-Content -path $templateFilePath -Raw) -replace '<subscriptionID>', $subscriptionID) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<rgName>', $imageResourceGroup) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<region>', $location) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<runOutputName>', $runOutputName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imageName>', $imageName) | Set-Content -Path $templateFilePath
((Get-Content -path $templateFilePath -Raw) -replace '<imgBuilderId>', $idenityNameResourceId) | Set-Content -Path $templateFilePath

New-AzResourceGroupDeployment -ResourceGroupName $imageResourceGroup -TemplateFile $templateFilePath -api-version "2019-05-01-preview" -imageTemplateName $imageTemplateName -svclocation $location

# note this will take minute, as validation is run (security / dependencies etc.)

Invoke-AzResourceAction -ResourceName $imageTemplateName -ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2019-05-01-preview" -Action Run -Force

########################################
#Get Status of the Image Build and Query
$resourcetowatch = Get-AzResource –ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $imageTemplateName
do {
    Start-Sleep -Seconds 30
    $status = (Get-AzResource –ResourceGroupName $imageResourceGroup -ResourceType Microsoft.VirtualMachineImages/imageTemplates -Name $imageTemplateName).Properties.lastRunStatus
    $status | Format-Table *
} while ($status.runState -eq "Running")


##Create a VM
$imageResourceGroup = "myResourceGroup"
$vmName = "aibVm1"

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a resource group
New-AzResourceGroup -Name $imageResourceGroup -Location $location

# Network pieces
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name mySubnet -AddressPrefix 192.168.1.0/24
$vnet = New-AzVirtualNetwork -ResourceGroupName $imageResourceGroup -Location $location `
    -Name MYvNET -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig
$pip = New-AzPublicIpAddress -ResourceGroupName $imageResourceGroup -Location $location `
    -Name "mypublicdns$(Get-Random)" -AllocationMethod Static -IdleTimeoutInMinutes 4
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $imageResourceGroup -Location $location `
    -Name myNetworkSecurityGroup -SecurityRules $nsgRuleRDP
$nic = New-AzNetworkInterface -Name myNic -ResourceGroupName $imageResourceGroup -Location $location `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration using $imageVersion.Id to specify the shared image
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_D1_v2 | `
    Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
    Set-AzVMSourceImage -Id $imageVersion.Id | `
    Add-AzVMNetworkInterface -Id $nic.Id

# Create a virtual machine
New-AzVM -ResourceGroupName $imageResourceGroup -Location $location -VM $vmConfig