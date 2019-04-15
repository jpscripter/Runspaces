#region Initial State
$initialSessionState = [initialsessionstate]::CreateDefault() # Enter PSSnapins here
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
  #endregion

  #region Helpful
  $Hash.Add($Counter,$PowerShell)
  $Counter
  #endregion
}

