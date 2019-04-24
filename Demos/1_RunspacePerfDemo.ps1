<#
    .SYNOPSIS
    PowerShell Runspace Performance Demo

    .DESCRIPTION
    Demonstrates PowerShell Runspace Performance compared to Jobs and Workflows

    .NOTES
    File Name:    RunspacePerfDemo.ps1
    Author:       Scott Corio - scott.corio@gmail.com
    
    .LINK
#>



#region Sequential (No optimization)
#Wait for 5 seconds 30 times
Clear-Host
Write-Host "This Process ID is $($pid)" -ForegroundColor White -BackgroundColor Black
$SequentialTime = Measure-Command {
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Seconds 5
        Write-Host "Processing $($i) has completed" -ForegroundColor Magenta
    }
}
#endregion

#region Jobs
$JobTime = Measure-Command {
    $ActiveJobs = New-Object System.Collections.ArrayList
    $AllJobs = New-Object System.Collections.ArrayList

    for ($i = 0; $i -lt 10; $i++) {
        $Job = Start-Job -Name "Job_$($i)" -ArgumentList @($i) -ScriptBlock {
            Start-Sleep -Seconds 5
            Write-Host "Processing of Job_$($args[0]) with pid $($pid) completed." -ForegroundColor Cyan #Note: Since this is a job, this output will not be visible until we run Receive-Job
        }
        $ActiveJobs.Add($Job)
        $AllJobs.Add($Job)
    }
    foreach ($job in $ActiveJobs) {
        Wait-Job $job
        Receive-Job $job
    }
    $ActiveJobs.Clear()

    for ($i = 10; $i -lt 20; $i++) {
        $Job = Start-Job -Name "Job_$($i)" -ArgumentList @($i) -ScriptBlock {
            Start-Sleep -Seconds 5
            Write-Host "Processing of Job_$($args[0]) with pid $($pid) completed." -ForegroundColor Cyan
        }
        $ActiveJobs.Add($Job)
        $AllJobs.Add($Job)
    }
    foreach ($job in $ActiveJobs) {
        Wait-Job $job
        Receive-Job $job
    }
    $ActiveJobs.Clear()

    for ($i = 20; $i -lt 30; $i++) {
        $Job = Start-Job -Name "Job_$($i)" -ArgumentList @($i) -ScriptBlock {
            Start-Sleep -Seconds 5
            Write-Host "Processing of Job_$($args[0]) with pid $($pid) completed." -ForegroundColor Cyan
        }
        $ActiveJobs.Add($Job)
        $AllJobs.Add($Job)
    }
    foreach ($job in $ActiveJobs) {
        Wait-Job $job
        Receive-Job $job
    }
    $ActiveJobs.Clear()
}

#endregion

#region workflow
$host.ui.RawUI.ForegroundColor = 14 #Yellow
$WorkflowTime = Measure-Command {
    Workflow Test-Workflow{

        $ints = 0..29
        ForEach -Parallel -ThrottleLimit 10 ($i in $ints) {  #This is a thread
            InlineScript {  #This is a process
                Start-Sleep -Seconds 5
                Write-Host "Workflow_$($using:i) with Process ID $($pid) has completed." -ForegroundColor Yellow  #Will not show color because the workflow is only returning the text to the 
            }
            Start-Sleep -Seconds 1
        }
    }

    Test-Workflow
}
$host.ui.RawUI.ForegroundColor = 15 #White
#endregion

#region Runspace
$RunspaceTime = Measure-Command {
    #region Runspace Pool
    [runspacefactory]::CreateRunspacePool()
    $SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, 10)
    $PowerShell = [powershell]::Create()
    $PowerShell.RunspacePool = $RunspacePool
    $RunspacePool.Open()
    #endregion

    #region Runspaces
    $Spaces = [System.Collections.ArrayList]::new()
    for ($i = 0; $i -lt 30; $i++) {
        $PowerShell = [powershell]::Create()
        $PowerShell.Runspace.Name = "Runspace_$($i)"
        $PowerShell.RunspacePool = $RunspacePool
        $PowerShell.AddScript({
            Param(
                [string]$Param1,
                [int]$Param2
            )
            Start-Sleep -Seconds 5
            Write-Host "WH Runspace_$($Param2) with Process ID $($pid) has completed"  #Will NOT return output via EndInvoke
            Write-Output "Runspace_$($Param2) with Process ID $($pid) has completed"  #Will return output via EndInvoke
        })

        $Parameters = @{
            Param1 = "Runspace_$($i)";
            Param2 = $i;
        }
        [void]$PowerShell.AddParameters($Parameters)

        $Handle = $PowerShell.BeginInvoke()
        
        $temp = '' | Select PowerShell,Handle
        $temp.PowerShell = $PowerShell
        $temp.handle = $Handle
        [void]$Spaces.Add($Temp)

        $RunspacePool.GetAvailableRunspaces()
    }
    #endregion
    
    $return = foreach ($rs in $Spaces) {
        $output = $rs.PowerShell.EndInvoke($rs.Handle)
        Write-Host $output -ForegroundColor Green
        $rs.PowerShell.Dispose()
    }

    $Spaces.clear()

    ($return | Group Thread).Count
}
#endregion

#region Compare Results
Write-Host ([string]::Format("Sequential Execution:  {0:00}:{1:00}.{2} ({3:00.00}%)", $SequentialTime.Minutes, $SequentialTime.Seconds, $SequentialTime.Milliseconds, (($SequentialTime.TotalMilliseconds/$SequentialTime.TotalMilliseconds) * 100)))
Write-Host ([string]::Format("Jobs Execution:        {0:00}:{1:00}.{2} ({3:00.00}%)", $JobTime.Minutes, $JobTime.Seconds, $JobTime.Milliseconds, (($JobTime.TotalMilliseconds/$SequentialTime.TotalMilliseconds) * 100)))
Write-Host ([string]::Format("Workflow Execution:    {0:00}:{1:00}.{2} ({3:00.00}%)", $WorkflowTime.Minutes, $WorkflowTime.Seconds, $WorkflowTime.Milliseconds, (($WorkflowTime.TotalMilliseconds/$SequentialTime.TotalMilliseconds) * 100)))
Write-Host ([string]::Format("Runspace Execution:    {0:00}:{1:00}.{2} ({3:00.00}%)", $RunspaceTime.Minutes, $RunspaceTime.Seconds, $RunspaceTime.Milliseconds, (($RunspaceTime.TotalMilliseconds/$SequentialTime.TotalMilliseconds) * 100)))
#endregion
