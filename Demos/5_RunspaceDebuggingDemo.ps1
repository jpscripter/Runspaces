<#
    .SYNOPSIS
    PowerShell Debugging Demo

    .DESCRIPTION
    Demonstrates Debugging PowerShell Runspaces

    .NOTES
    File Name:    RunspaceDebuggingDemo.ps1
    Author:       Scott Corio - scott.corio@gmail.com
    
    .LINK
#>

#region 1 List our runspaces
Get-Runspace
#endregion

#region 2 The Debug Console
$ps = [powershell]::Create()
$ps.Runspace.Name = "DebugExample1"
$ps.AddScript({
    for ($i = 1; $i -lt 5; $i++) {
        Start-Sleep -Seconds 1
        Write-Output "I have slept for $($i) seconds"
    }
})
$async = $ps.BeginInvoke()
Debug-Runspace DebugExample1
$ps.EndInvoke($async)
if ($ps.InvocationStateInfo -eq 'Failed') {
    Write-Host "The Runspace exited in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Red
} else {
    Write-Host "The Runspace exited in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Green
}
$ps.Dispose()
#Show stepping, and detaching
#endregion

#region 3 Code that generates an Non-Fatal error
for ($i = 1; $i -lt 3; $i++) {
        Start-Sleep -Seconds 1
        Write-Output "I have slept for $($i) seconds"
        if (($i % 2) -eq 0) {
            Remove-Item -Path "I:\Dont Exist"
        }
    }
#endregion

#region 4 What if we put it in a runspace?
$ps = [powershell]::Create()
$ps.Runspace.Name = "DebugExample2"
$ps.AddScript({
    for ($i = 1; $i -lt 3; $i++) {
        Start-Sleep -Seconds 1
        Write-Output "I have slept for $($i) seconds"
        if (($i % 2) -eq 0) {
            Remove-Item -Path "I:\Dont Exist"
        }
    }
})
$async = $ps.BeginInvoke()
$ps.EndInvoke($async)
if ($ps.InvocationStateInfo -eq 'Failed') {
    Write-Host "The Runspace exited in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Red
} else {
    Write-Host "The Runspace exited in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Green
}
$ps.Dispose()
#endregion

#region 5 No Error?  Not so fast
$ps = [powershell]::Create()
$ps.Runspace.Name = "DebugExample3"
$ps.AddScript({
    for ($i = 1; $i -lt 3; $i++) {
        Start-Sleep -Seconds 1
        Write-Output "I have slept for $($i) seconds"
        if (($i % 2) -eq 0) {
            Remove-Item -Path "I:\Dont Exist"
        }
    }
})
$async = $ps.BeginInvoke()
Debug-Runspace DebugExample3
$ps.EndInvoke($async)
if ($ps.InvocationStateInfo -eq 'Failed') {
    Write-Host "The Runspace exited in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Red
} else {
    Write-Host "The Runspace exited in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Green
}
$ps.Dispose()
#endregion

#region 6 Where is my error?  In the error stream
$ps = [powershell]::Create()
$ps.AddScript({
    for ($i = 1; $i -lt 3; $i++) {
        Start-Sleep -Seconds 1
        Write-Output "I have slept for $($i) seconds"
        if (($i % 2) -eq 0) {
            Remove-Item -Path "I:\Dont Exist"
        }
    }
})
$async = $ps.BeginInvoke()
$ps.EndInvoke($async)
Write-Host "The runspace encountered $($ps.Streams.Error.Count) errors" -ForegroundColor Red
$ps.Streams
$ps.Streams.Error

if ($ps.InvocationStateInfo -eq 'Failed') {
    Write-Host "The Runspace exited in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Red
} else {
    Write-Host "The Runspace exited in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Green
}

$ps.Dispose()
#endregion

#region 7 What about Fatal Errors?
$ps = [powershell]::Create()
$ps.Runspace.Name = "DebugExample4"
$ps.AddScript({
    for ($i = 1; $i -lt 3; $i++) {
        Start-Sleep -Seconds 1
        Write-Output "I have slept for $($i) seconds"
        if (($i % 2) -eq 0) {
            Remove-Item -Path "I:\Dont Exist" -ErrorAction Stop
        }
    }
})
$async = $ps.BeginInvoke()
$ps.EndInvoke($async)

#The error stream is empty
Write-Host "The runspace encountered $($ps.Streams.Error.Count) errors" -ForegroundColor Red
$ps.Streams
$Ps.Streams.Error

#The error resides in the Invocation State Info (Reason)
if ($ps.InvocationStateInfo.State -eq 'Failed') {
    Write-Host "The Runspace exiting in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Red
} else {
    Write-Host "The Runspace exiting in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Green
}
$ps.InvocationStateInfo.Reason
#$ps.Dispose()
#endregion

#region 8 Fatal Errors are not included in STDERR.  But they can be trapped!
$ps = [powershell]::Create()
$ps.Runspace.Name = "DebugExample10"
$ps.AddScript({
    for ($i = 1; $i -lt 3; $i++) {
        Start-Sleep -Seconds 1
        Write-Output "I have slept for $($i) seconds"
        if (($i % 2) -eq 0) {
            trap {
                Write-Error -Message $_.Exception.Message
                continue
            }
            Remove-Item -Path "I:\Dont Exist" -ErrorAction Stop
        }
    }
})
$async = $ps.BeginInvoke()
Debug-Runspace DebugExample10
$ps.EndInvoke($async)
$ps.Streams
$ps.Streams.Error
if ($ps.InvocationStateInfo -eq 'Failed') {
    Write-Host "The Runspace exited in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Red
} else {
    Write-Host "The Runspace exited in a $($ps.InvocationStateInfo.State) state" -ForegroundColor Green
}
$ps.Dispose()
#endregion
