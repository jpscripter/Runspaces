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


#region Job
#Prep
if (Test-Path -Path $SCRIPTTEMP -PathType Container) {
    Get-ChildItem -Path $SCRIPTTEMP | Remove-Item -Recurse -Force -Confirm:$false
} else {
    New-Item -Path $SCRIPTTEMP -ItemType Directory
}

#Job
$JobTime = Measure-Command {
    $Job = Start-Job -Name "DemoJob" -ArgumentList @($SCRIPTTEMP, $DLROOT) -ScriptBlock {
        Set-Location $args[0]
        for ($i = 0; $i -lt 30; $i++) {
            $wc = New-Object System.Net.WebClient
            Start-Sleep -Seconds 5
            #$wc.DownloadFile("$($args[1])5M_$($i).dum", "$($args[0])5M_$($i).dum")
            Write-Host "$($Using:DlRoot)5M_$($Using:i).dum"
        }
    }
    Wait-Job -Job $Job
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
