#region Syncronized hash tables
$initialSessionState = [initialsessionstate]::CreateDefault() # Enter PSSnapins here
$hash = [hashtable]::Synchronized(@{})
$Variable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('SyncHash',$hash ,'Description?')
$initialSessionState.Variables.Add($Variable)

$Runspace = [RunspaceFactory]::CreateRunspace($Host,$initialSessionState)
$Runspace.ThreadOptions = ''
$Runspace.Open()

$PowerShell = [PowerShell]::Create()
$PowerShell.Runspace = $RunSpace
$ScriptBlock = {
    $VerbosePreference = 2
    Write-Output $SyncHash['name']
    $SyncHash['name'] = 'Changed'
    start-sleep -Seconds 3 
}
$Null = $PowerShell.AddScript($ScriptBlock)
$Null = $PowerShell.BeginInvoke()
$hash
#endregion


#region Debugging
$initialSessionState = [initialsessionstate]::CreateDefault() # Enter PSSnapins here
$initialSessionState.LanguageMode = 'Full'
$initialSessionState.ExecutionPolicy = 'bypass'
$Variable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('InitVariable','Value','Description?')
$initialSessionState.Variables.Add($Variable)

$Runspace = [RunspaceFactory]::CreateRunspace($Host,$initialSessionState)
$Runspace.Open()

$PowerShell = [PowerShell]::Create()
$PowerShell.Runspace = $RunSpace
$ScriptBlock = {
    Write-output -InputObject $InitVariable
    start-sleep -Seconds 3 
}
$Null = $PowerShell.AddScript($ScriptBlock)
$Null = $PowerShell.BeginInvoke()
Debug-Runspace -Runspace $RunSpace 

#debug-job for background jobs
#endregion

#region Remote Runspace
#https://docs.microsoft.com/en-us/powershell/developer/hosting/creating-remote-runspaces
$connectionInfo = [System.Management.Automation.Runspaces.WSManConnectionInfo]::new
$Runspace = [runspacefactory]::CreateRunspace($connectionInfo)
#endregion

#region Changing credentials
$Signature = @'
[DllImport("advapi32.dll", SetLastError = true, CharSet=CharSet.Unicode)]
public static extern bool LogonUserW(
  string pszUserName,
  string pszDomain,
  string pszPassword,
  int dwLogonType,
  int dwLogonProvider,
  ref IntPtr phToken);
'@
$Logonuser = Add-Type -MemberDefinition $Signature -Name LogonUserW -PassThru
[intptr] $token = 0
$Credential = Get-Credential 
$Logonuser::LogonUserw($Credential.GetNetworkCredential().UserName,$Credential.GetNetworkCredential().Domain,$Credential.GetNetworkCredential().Password,9,0,[ref]$Token)
[System.Security.Principal.WindowsIdentity]::Impersonate($token)
[System.Security.Principal.WindowsIdentity]::GetCurrent()
[System.Security.Principal.WindowsIdentity]::Impersonate(0)
#endregion