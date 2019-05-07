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
$SHashTable = [hashtable]::Synchronized(@{0=0;1=1;2=2;3=3;4=4;})
$AHashTable = [hashtable]::new(@{0=0;1=1;2=2;3=3;4=4;})
$Array = @(0,1,2,3,4)

[runspacefactory]::CreateRunspacePool()
#$SessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
[void]$RunspacePool.Open()


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

    Write-Host $y -ForegroundColor $z

    Write-Host "SYNCHRONIZED HASH TABLE:" -ForegroundColor $z
    foreach ($key in $SHashTable.Keys) {
        Write-Host "$($Key): $($SHashTable.Item($Key))" -ForegroundColor $z
    }

    Write-Host "HASH TABLE:" -ForegroundColor $z
    foreach ($key in $AHashTable.Keys) {
        Write-Host "$($Key): $($AHashTable.Item($Key))" -ForegroundColor $z
    }

    Write-Host "ARRAY:" -ForegroundColor $z
    foreach ($item in $Array) {
        Write-Host $item -ForegroundColor $z
    }
}

#region Runspaces
Show-Variables -Before

for ($i = 0; $i -lt 5; $i++) {
    $Runspace = [runspacefactory]::CreateRunspace()
    [void]$Runspace.Open()
    $Runspace.Name = "Runspace_$($i)"
    $PowerShell = [powershell]::Create()
    $PowerShell.Runspace = $Runspace
    $PowerShell.RunspacePool = $RunspacePool
    [void]$PowerShell.AddScript({
        Param(
            [int]$Counter,
            [hashtable]$SyncHashTable,
            [hashtable]$HashTable,
            [int[]]$Array
        )
        $NewValue = (Get-Date).Millisecond
        Write-Output "Setting index $($Counter) to $($NewValue)`n"

        #Set the values
        $SyncHashTable[$Counter] = $NewValue
        $HashTable[$Counter] = $NewValue
        $Array[$Counter] = $NewValue

        #Read the values back
        Write-Output "`$SyncHashTable[$($Counter)] is $($SyncHashTable[$Counter])`n"
        Write-Output "`$HashTable[$($Counter)] is $($HashTable[$Counter])`n"
        Write-Output "`$Array[$($Counter)] is $($Array[$Counter])`n"
    })

    #Set our Parameters
    $Parameters = @{
        Counter = $i;
        SyncHashTable = $SHashTable;
        HashTable = $AHashTable;
        Array = $Array;
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
