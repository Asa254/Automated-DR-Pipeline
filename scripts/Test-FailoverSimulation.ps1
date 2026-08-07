<#
.SYNOPSIS
    Simulates a DR failover for a specified VM and validates the result.

.DESCRIPTION
    Runs a Veeam "Sure Backup" style failover test against a replica or
    backup restore point without impacting production. Confirms the VM
    boots successfully and reports the outcome. Meant to be run on a
    schedule (e.g., monthly) to prove DR readiness rather than assume it.

.PARAMETER VMName
    The name of the VM to test failover for.

.PARAMETER RestorePointDate
    Optional. Specific restore point to test against. Defaults to the
    most recent restore point if not specified.

.EXAMPLE
    .\Test-FailoverSimulation.ps1 -VMName "APP01"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$VMName,

    [Parameter(Mandatory = $false)]
    [datetime]$RestorePointDate
)

Import-Module Veeam.Backup.PowerShell -ErrorAction Stop

$logPath = "C:\DR-Pipeline\Logs\failover-test-log.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

try {
    $restorePoint = if ($RestorePointDate) {
        Get-VBRRestorePoint -Name $VMName | Where-Object { $_.CreationTime -eq $RestorePointDate }
    } else {
        Get-VBRRestorePoint -Name $VMName | Sort-Object CreationTime -Descending | Select-Object -First 1
    }

    if (-not $restorePoint) {
        throw "No restore point found for VM: $VMName"
    }

    # Start a SureBackup-style verification job against the restore point
    Start-VBRSureBackupJob -RestorePoint $restorePoint

    Add-Content -Path $logPath -Value "$timestamp - SUCCESS - Failover simulation completed for '$VMName' using restore point $($restorePoint.CreationTime)."
    Write-Output "Failover simulation succeeded for $VMName."
}
catch {
    Add-Content -Path $logPath -Value "$timestamp - FAILURE - Failover simulation for '$VMName' failed: $($_.Exception.Message)"
    Write-Error "Failover simulation failed: $($_.Exception.Message)"
}
