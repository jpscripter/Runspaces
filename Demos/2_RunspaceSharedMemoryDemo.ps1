<#
    .SYNOPSIS
    PowerShell Runspace Shared Memory Demo

    .DESCRIPTION
    Demonstrates Shared Memory between Runspaces

    .NOTES
    File Name:    RunspacePerfDemo.ps1
    Author:       Scott Corio - scott.corio@gmail.com
    
    .LINK
#>

$Spaces = [System.Collections.ArrayList]::new()

#Shared Memory Example Variables
$HashTable = [hashtable]::Synchronized(@{})
$x = 5

[runspacefactory]::CreateRunspacePool()
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
[void]$RunspacePool.Open()
#endregion

function Show-Variables {
    Param(
    [switch]$Before,
    [switch]$After
    )
    if ($Before) {
        $y = "Before"
        $z = [ConsoleColor]::Green
    } elseif ($After) {
        $y = "After"
        $z = [ConsoleColor]::Red
    }

    Write-Host "$($y)`nHASH TABLE:" -ForegroundColor $z
    foreach ($key in $HashTable.Keys) {
        Write-Host "$($Key): $($HashTable.Item($Key))" -ForegroundColor $z
    }
    Write-Host "X: $($x)" -foregroundColor $z
}

#region Runspaces
Show-Variables -Before

for ($i = 0; $i -lt 5; $i++) {
    $Runspace = [runspacefactory]::CreateRunspace()
    [void]$Runspace.Open()
    $Runspace.Name = "Runspace_$($i)"
    #$Runspace.SessionStateProxy.SetVariable('Hash', $HashTable)  #This is used for a single runspace
    $PowerShell = [powershell]::Create()
    $PowerShell.Runspace = $Runspace
    $PowerShell.RunspacePool = $RunspacePool
    [void]$PowerShell.AddScript({
        Param(
            [string]$Param1,
            [int]$Param2,
            [hashtable]$Param3,
            [int]$Param4
        )
        $Param3[$Param2] = $Param1
        Write-Output "$$x is $($Param4)`n"
        $Param4 = (Get-Date).Millisecond
        Write-Output "$$x is now $($Param4)"
    })

    $Parameters = @{
        Param1 = "Runspace_$($i)";
        Param2 = $i;
        Param3 = $HashTable;
        Param4 = $x;
    }
    [void]$PowerShell.AddParameters($Parameters)

    $Handle = $PowerShell.BeginInvoke()
    
    $temp = '' | Select PowerShell,Handle
    $temp.PowerShell = $PowerShell
    $temp.handle = $Handle
    [void]$Spaces.Add($Temp)

    [void]$RunspacePool.GetAvailableRunspaces()
}
#endregion
    
$return = foreach ($rs in $Spaces) {
    $Output = $rs.PowerShell.EndInvoke($rs.Handle)
    Write-Host $Output
    $rs.PowerShell.Dispose()
}
$Spaces.clear()

($return | Group Thread).Count

Show-Variables -After