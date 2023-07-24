<#
.SYNOPSIS
    Sync Arm template trigger runtime state to match runtime status of trigger currently deployed. 
.DESCRIPTION
    This function will update the runtime status of each trigger in the ARM template of an ADF genereated by the npm package azure-data-factory-utilities to the current runtime status of the trigger on the deployed ADF. If trigger is new then it is left as is.  
    Intention of this function is to support using the prepostdeploymentscript.ps1 packaged up in the npm package azure-data-factory-utilities; 
    prepostdeploymentscript relies that the runtime states in the ARM template are in the correct desired state. 
    Note: triggers cannot be started by ARM Template deployment.
.OUTPUTS 
    PSCustomObject includes triggers from ADF and ARM Template, and arrays of updated/skipped/new triggers.
.PARAMETER ResourceGroupName
    Name of the resource group where the factory resource is in
.PARAMETER DataFactoryName
    Name of the data factory being deployed
.PARAMETER ArmTemplate
    Arm template file path
        example: C:\Adf\ArmTemlateOutput\ARMTemplateForFactory.json
.PARAMETER WhatIf
    Default: $false
    True: Does not save altered runtime status back to the ARM Template.
    False: Saves the altered runtime status to the ARM Template.
.LINK
    prepostdeploymentscript.ps1 (version 2 is packaged with npm package) https://github.com/Azure/Azure-DataFactory/blob/main/SamplesV2/ContinuousIntegrationAndDelivery/PrePostDeploymentScript.Ver2.ps1
.LINK 
    npm package the compiles ARM Template from ADF source code https://www.npmjs.com/package/@microsoft/azure-data-factory-utilities
    #>
Function Switch-ArmTriggerRuntimeStateToMatchAdfTrigger {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)][String]$ResourceGroupName,
        [parameter(Mandatory = $true)][String]$DataFactoryName,
        [parameter(Mandatory = $true)][String]$ArmTemplateFile,
        [parameter(Mandatory = $false)][switch]$WhatIf
    )

    $updateStatusOfTriggers = @()
    $newTriggers = @()
    $skipStatusOfTriggers = @()

    $armTemplateJson = Get-Content $ArmTemplateFile | Out-String | ConvertFrom-Json
    $triggersFromAdf = Get-AzDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName 
    $triggersFromArm = $armTemplateJson.resources | Where-Object { $_.type -eq "Microsoft.DataFactory/factories/triggers" }

    $triggersFromArm | ForEach-Object {
        Write-Verbose "[*] Formatting name of trigger: $($_.name)" 
        $adfTriggerName = $_.name.Substring(37, $_.name.Length - 40)
        Write-Verbose "[*] Searching for runtime status of $adfTriggerName on published ADF..."
        $triggerFromAdf = $null
        $triggerFromAdf = $triggersFromAdf | Where-Object { $_.Name -eq $adfTriggerName }
        if ($null -ne $triggerFromAdf) {
            Write-Verbose "[*] Trigger $adfTriggerName found!"
            if ($_.properties.RuntimeState -ne $triggerFromAdf.RuntimeState) {
                Write-Verbose "[*] Setting state in ARM Template from $($_.properties.RuntimeState) to $($triggerFromAdf.RuntimeState)"
                $_.properties.RuntimeState = $triggerFromAdf.RuntimeState
                $updateStatusOfTriggers += $_
            }
            else {
                Write-Verbose "[*] Leaving state as $($_.properties.RuntimeState)."
                $skipStatusOfTriggers += $_
            }
        }
        else {
            Write-Verbose "[*] Trigger $adfTriggerName not found. Assuming it is new. Setting to Stopped."
            $_.properties.RuntimeState = "Stopped"
            $newTriggers += $_
        }
    }
    if ($PSBoundParameters.ContainsKey('WhatIf') -eq $true) {
        Write-Host "[*] Switch WhatIf included, so not saving results to arm template file..." 
    }
    else {
        Write-Host "[*] Saving updated json back to $armTemplateFile" 
        $armTemplateJson | ConvertTo-Json -Depth 100 | Set-Content $armTemplateFile -Force
    }
    $Triggers = [PSCustomObject]@{
        ResourceGroupName      = $ResourceGroupName
        DataFactoryName        = $DataFactoryName
        TriggersFromADF        = $triggersFromAdf
        TriggersFromARM        = $triggersFromArm
        UpdateStatusOfTriggers = $updateStatusOfTriggers
        SkipStatusOfTriggers   = $skipStatusOfTriggers
        NewTriggers            = $newTriggers
        WhatIfIsPresent        = $WhatIf.IsPresent
    }
    Return $Triggers
}