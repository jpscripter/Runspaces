<#
    .SYNOPSIS
    PowerShell Runspace Customization

    .DESCRIPTION
    Demonstrates PowerShell Runspace examples with adding customizations to runspaces.

    .NOTES
    File Name:    CustomizingRunspaces.ps1
    Author:       Jeff Scripter JPScripter@gmail.com
    
    .LINK
#>

#region Initial State
$initialSessionState = [initialsessionstate]::CreateDefault() # Enter PSSnapins here
$initialSessionState.LanguageMode = 'Full'
$initialSessionState.ExecutionPolicy = 'bypass'

#initial Variables
$Variable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('InitVariable','Value','Description?')
$initialSessionState.Variables.Add($Variable)

#Initial Modules
$initialSessionState.ImportPSModule('tls')

#StartupScripts
$initialSessionState.StartupScripts.Add('$startup = $true')

#Thread Option
#https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.runspaces.psthreadoptions?view=powershellsdk-1.1.0
#$initialSessionState.ThreadOptions = 'Default' #'UseCurrentThread'
#endregion

#region Syncronized hash tables
$hash = [hashtable]::Synchronized(@{})
$Variable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('SyncHash',$hash ,'Description?')
$initialSessionState.Variables.Add($Variable)

$Runspace = [RunspaceFactory]::CreateRunspace($Host,$initialSessionState)
$Runspace.Open()

$PowerShell = [PowerShell]::Create()
$PowerShell.Runspace = $RunSpace
$Hash.add('name','value')
$ScriptBlock = {
    $VerbosePreference = 2
    Write-Verbose "Startup = $startup"
    Write-Verbose $SyncHash['name']
    $SyncHash['name'] = 'Changed'
    Write-Verbose $SyncHash['name']
    start-sleep -Seconds 3 
}
$Null = $PowerShell.AddScript($ScriptBlock)
$Null = $PowerShell.BeginInvoke()
$hash
#endregion

#region
$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1,3,$initialSessionState,$host)
$RunspacePool.Open()
$hash['name'] = 'New value'
$PowerShell = [PowerShell]::Create()
$PowerShell.RunspacePool = $RunspacePool
$ScriptBlock = {
    $VerbosePreference = 2
    Write-Verbose "Startup = $startup"
    Write-Verbose $SyncHash['name']
    $SyncHash['name'] = 'Changed'
    Write-Verbose $SyncHash['name']
    start-sleep -Seconds 3 
}
$Null = $PowerShell.AddScript($ScriptBlock)
$Null = $PowerShell.BeginInvoke()
$hash
#endregion
