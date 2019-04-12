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

#region Variables
    $SCRIPTTEMP = 'C:\Windows\Temp\RunspacePerfDemo\'
    $DLROOT = "https://github.com/DumpsterDave/MMS2019/raw/master/DummyFiles/"

#endregion

#region Sequential (No optimization)
#Prep
if (Test-Path -Path $SCRIPTTEMP -PathType Container) {
    Get-ChildItem -Path $SCRIPTTEMP | Remove-Item -Recurse -Force -Confirm:$false
} else {
    New-Item -Path $SCRIPTTEMP -ItemType Directory
}

#Download
$SequentialTime = Measure-Command {
    for ($i = 0; $i -lt 30; $i++) {
        $wc = New-Object System.Net.WebClient
        Start-Sleep -Seconds 5
        #$wc.DownloadFile("$($args[1])5M_$($i).dum", "$($args[0])5M_$($i).dum")
        Write-Host "$($DlRoot)5M_$($i).dum"
    }
}
#endregion

#region Jobs
#Prep
if (Test-Path -Path $SCRIPTTEMP -PathType Container) {
    Get-ChildItem -Path $SCRIPTTEMP | Remove-Item -Recurse -Force -Confirm:$false
} else {
    New-Item -Path $SCRIPTTEMP -ItemType Directory
}

#Job
$JobTime = Measure-Command {
    $ActiveJobs = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt 10; $i++) {
        $Job = Start-Job -Name "Job_$($i)" -ArgumentList @($SCRIPTTEMP, $DLROOT) -ScriptBlock {
            $wc = New-Object System.Net.WebClient
            Start-Sleep -Seconds 5
            #$wc.DownloadFile("$($args[1])5M_$($i).dum", "$($args[0])5M_$($i).dum")
            Write-Host "$($args[1])5M_$($args[0]).dum"
        }
        $ActiveJobs.Add($Job)
    }
    foreach ($job in $ActiveJobs) {
        Wait-Job $job
    }
    $ActiveJobs.Clear()

    for ($i = 10; $i -lt 20; $i++) {
        $Job = Start-Job -Name "Job_$($i)" -ArgumentList @($SCRIPTTEMP, $DLROOT) -ScriptBlock {
            $wc = New-Object System.Net.WebClient
            Start-Sleep -Seconds 5
            #$wc.DownloadFile("$($args[1])5M_$($i).dum", "$($args[0])5M_$($i).dum")
            Write-Host "$($args[1])5M_$($args[0]).dum"
        }
        $ActiveJobs.Add($Job)
    }
    foreach ($job in $ActiveJobs) {
        Wait-Job $job
    }
    $ActiveJobs.Clear()

    for ($i = 20; $i -lt 30; $i++) {
        $Job = Start-Job -Name "Job_$($i)" -ArgumentList @($SCRIPTTEMP, $DLROOT) -ScriptBlock {
            $wc = New-Object System.Net.WebClient
            Start-Sleep -Seconds 5
            #$wc.DownloadFile("$($args[1])5M_$($i).dum", "$($args[0])5M_$($i).dum")
            Write-Host "$($args[1])5M_$($args[0]).dum"
        }
        $ActiveJobs.Add($Job)
    }
    foreach ($job in $ActiveJobs) {
        Wait-Job $job
    }
    $ActiveJobs.Clear()
}
#endregion

#region workflow
#prep
if (Test-Path -Path $SCRIPTTEMP -PathType Container) {
    Get-ChildItem -Path $SCRIPTTEMP | Remove-Item -Recurse -Force -Confirm:$false
} else {
    New-Item -Path $SCRIPTTEMP -ItemType Directory
}

#Workflow
$WorkflowTime = Measure-Command {
    Workflow Download-Files {
        Param(
            [string]$ScriptTemp,
            [string]$DlRoot
        )

        $ints = 0..29
        ForEach -Parallel -ThrottleLimit 10 ($i in $ints) {
            InlineScript {
                $wc = New-Object System.Net.WebClient
                Start-Sleep -Seconds 5
                #$wc.DownloadFile("$($Using:DlRoot)5M_$($Using:i).dum", "$($Using:ScriptTemp)5M_$($Using:i).dum")
                Write-Host "$($Using:DlRoot)5M_$($Using:i).dum"
            }
        }
    }

    Download-Files -ScriptTemp $SCRIPTTEMP -DlRoot $DLROOT
}
#endregion

#region Runspace
#prep
if (Test-Path -Path $SCRIPTTEMP -PathType Container) {
    Get-ChildItem -Path $SCRIPTTEMP | Remove-Item -Recurse -Force -Confirm:$false
} else {
    New-Item -Path $SCRIPTTEMP -ItemType Directory
}
#Runspace
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
    $Jobs = [System.Collections.ArrayList]::new()
    for ($i = 0; $i -lt 30; $i++) {
        $PowerShell = [powershell]::Create()
        $PowerShell.RunspacePool = $RunspacePool
        $PowerShell.AddScript({
            Param(
                [string]$TempDir,
                [string]$DL
            )
            $wc = New-Object System.Net.WebClient
            Start-Sleep -Seconds 5
            #$wc.DownloadFile("$($Dl)5M_$($i).dum", "$($TempDir)5M_$($TempDir).dum")
            Write-Host "$($DL)5M_$($i).dum"
        })
        $Parameters = @{
            TempDir = $SCRIPTTEMP;
            DL = $DLROOT;
        }
        [void]$PowerShell.AddParameters($Parameters)
        $Handle = $PowerShell.BeginInvoke()
        
        $temp = '' | Select PowerShell,Handle
        $temp.PowerShell = $PowerShell
        $temp.handle = $Handle
        [void]$jobs.Add($Temp)

        $RunspacePool.GetAvailableRunspaces()
    }
    #endregion
    
    $return = foreach ($job in $jobs) {
        $job.PowerShell.EndInvoke($job.Handle)
        $job.PowerShell.Dispose()
    }

    $jobs.clear()

    ($return | Group Thread).Count
}
#endregion

#region Compare Results
Write-Host ([string]::Format("Sequential Execution:  {0:00}:{1:00}.{2} ({3:00.00}%)", $SequentialTime.Minutes, $SequentialTime.Seconds, $SequentialTime.Milliseconds, (($SequentialTime.TotalMilliseconds/$SequentialTime.TotalMilliseconds) * 100)))
Write-Host ([string]::Format("Jobs Execution:        {0:00}:{1:00}.{2} ({3:00.00}%)", $JobTime.Minutes, $JobTime.Seconds, $JobTime.Milliseconds, (($JobTime.TotalMilliseconds/$SequentialTime.TotalMilliseconds) * 100)))
Write-Host ([string]::Format("Workflow Execution:    {0:00}:{1:00}.{2} ({3:00.00}%)", $WorkflowTime.Minutes, $WorkflowTime.Seconds, $WorkflowTime.Milliseconds, (($WorkflowTime.TotalMilliseconds/$SequentialTime.TotalMilliseconds) * 100)))
Write-Host ([string]::Format("Runspace Execution:    {0:00}:{1:00}.{2} ({3:00.00}%)", $RunspaceTime.Minutes, $RunspaceTime.Seconds, $RunspaceTime.Milliseconds, (($RunspaceTime.TotalMilliseconds/$SequentialTime.TotalMilliseconds) * 100)))
#endregion
