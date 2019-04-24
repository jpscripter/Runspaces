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

#region MultiThreaded 
$MINRunspaces = 1
$MAXRunspaces = 3
$RunSpacePool = [RunspaceFactory]::CreateRunspacePool($minRunspaces,$MAXRunspaces,$initialSessionState,$Host)
#$RunSpacePool.ApartmentState = "MTA" # Thread safe com object coding
$RunSpacePool.Open()
#endregion

#region Single Threaded
#$RunspaceCOnfiguration = [System.Management.Automation.Runspaces.RunspaceConfiguration]::Create() #Console File
# Similar to InintialSessionState but no thread options
$Runspace = [RunspaceFactory]::CreateRunspace($Host,$initialSessionState)
$Runspace.Open()
#endregion

$hash = @{}
For ($Counter = 0; $Counter -lt 10; $counter++){
  #region Basic
    $PowerShell = [PowerShell]::Create()
    #$PowerShell.Runspacepool = $RunSpacePool
    $PowerShell.Runspace = $RunSpace
    
    $ScriptBlock = {
        $Process = Start-Process $Env:comspec -PassThru 
        Write-output -InputObject 'Runspaces!'
        Start-sleep -Seconds 20
        stop-process -InputObject $process
    }
    $Null = $PowerShell.AddScript($ScriptBlock)
    $Null = $PowerShell.BeginInvoke()

    <#region Extracting data
    Start-sleep -Seconds 2
    $Monitor = $powershell.CreateNestedPowerShell()
    $Monitor.AddScript({
        $VerbosePreference = 2
        Write-Verbose $process}
    )
    $Monitor.Invoke()
    #endregion
    #>

    #region streams
    $Powershell.streams
    $Flags = 'nonpublic','instance','static'
    [Powershell].getProperty('OutputBuffer',$Flags).getValue($PowerShell)
    #endregion

  #endregion

  #region Helpful
  $Hash.Add($Counter,$PowerShell)
  $Counter
  #endregion
}


#region Syncronized hash tables
$initialSessionState = [initialsessionstate]::CreateDefault() # Enter PSSnapins here
$initialSessionState.LanguageMode = 'Full'
$initialSessionState.ExecutionPolicy = 'bypass'
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
    Write-Verbose  $SyncHash['name']
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