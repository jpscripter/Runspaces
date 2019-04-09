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
}

$JobTime = Measure-Command {
    $Job = Start-Job -Name "DemoJob" -ArgumentList @($SCRIPTTEMP, $DLROOT) -ScriptBlock {
        Set-Location $args[0]
        for ($i = 0; $i -lt 30; $i++) {
            Write-Output "$($args[1])5M_$($i).dum"
            $wc = New-Object System.Net.WebClient
            $wc.DownloadFile("$($args[1])5M_$($i).dum", "$($args[0])5M_$($i).dum")
        }
    }
    Wait-Job -Job $Job
}
#endregion

Receive-Job $Job
$JobTime
