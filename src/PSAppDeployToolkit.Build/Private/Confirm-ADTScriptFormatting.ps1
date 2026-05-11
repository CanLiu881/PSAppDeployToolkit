#-----------------------------------------------------------------------------
#
# MARK: Confirm-ADTScriptFormatting
#
#-----------------------------------------------------------------------------

function Confirm-ADTScriptFormatting {
    # Initialise the module build function.
    Initialize-ADTModuleBuildFunction
    try {
        # Verify the formatting of all PowerShell script files within the repository.
        # Collect PS files explicitly to avoid PSScriptAnalyzer recursing into bin/obj directories
        # which contain CsWin32-generated C# files that cause FileNotFoundException errors.
        Write-ADTBuildLogEntry -Message "Confirming all PowerShell files are formatted correctly."
        $psFiles = Get-ChildItem -Path $Script:ModuleConstants.Paths.SourceRoot -Include '*.ps1', '*.psm1', '*.psd1' -Recurse |
        Where-Object { $_.FullName -notmatch '\\(bin|obj)\\' }
        if ([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]$result = $psFiles | Invoke-ScriptAnalyzer -Setting CodeFormattingAllman -ExcludeRule PSAlignAssignmentStatement -Fix:(!(Test-ADTBuildingWithinPipeline)) -Verbose:$false | & { process { if (!$_.RuleName.Equals('PSUseToExportFieldsInManifest') -or !$_.ScriptName.Equals('PSAppDeployToolkit.Extensions.psd1')) { return $_ } } }) {
            Write-ADTBuildLogEntry -Message "PSScriptAnalyzer returned $($result.Count) script formatting violations." -ForegroundColor DarkRed
            Write-ADTScriptAnalyzerOutput -DiagnosticRecord $result
            throw "The call to Invoke-ScriptAnalyzer returned formatting violations that must be addressed."
        }
        Complete-ADTModuleBuildFunction
    }
    catch {
        Complete-ADTModuleBuildFunction -ErrorRecord $_
        throw
    }
}
