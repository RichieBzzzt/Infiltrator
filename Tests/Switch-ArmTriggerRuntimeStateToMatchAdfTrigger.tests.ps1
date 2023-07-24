Describe "Import Module" {
    it "Should not throw" {
        Set-Location $PSScriptRoot
        Import-Module "..\Infiltrator.psm1" -Force
    }
}