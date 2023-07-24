BeforeAll {
    $CommandName = 'Switch-ArmTriggerRuntimeStateToMatchAdfTrigger.ps1'
    Get-Module Infiltrator | Remove-Module -Force
    $ModulePath = Join-Path $PSScriptRoot ".."
    $CommandNamePath = Resolve-Path (Join-Path $ModulePath /Public/$CommandName)
    Import-Module $CommandNamePath -Force
}

Describe "Import Module" {
    BeforeAll{
     
    }
    it "Should not throw" {
        $ResourceGroupName = 'infiltrator'
        $DataFactoryName = 'infiltrator'
        $ArmTemplateFile = Join-Path $PSScriptRoot 'arm_templates/test_one/ARMTemplateForFactory.json'
        { Switch-ArmTriggerRuntimeStateToMatchAdfTrigger `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -ArmTemplateFile $ArmTemplateFile } | Should -Not -Throw
    }

    it "Should not throw whatif" {
        $ResourceGroupName = 'infiltrator'
        $DataFactoryName = 'infiltrator'
        $ArmTemplateFile = Join-Path $PSScriptRoot 'arm_templates/test_one/ARMTemplateForFactory.json'
        { Switch-ArmTriggerRuntimeStateToMatchAdfTrigger `
            -ResourceGroupName $ResourceGroupName `
            -DataFactoryName $DataFactoryName `
            -ArmTemplateFile $ArmTemplateFile `
            -WhatIf } | Should -Not -Throw
    }
}