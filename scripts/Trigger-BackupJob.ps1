<#
.SYNOPSIS
    Triggers a Veeam backup job and logs the result.

.DESCRIPTION
    Starts a specified Veeam Backup & Replication job, waits for completion,
    and logs whether it succeeded or failed. Intended to be run on a schedule
    (e.g., via Windows Task Scheduler) as part of the automated DR pipeline.

.PARAMETER JobName
    The name of the Veeam backup job to trigger.

.EXAMPLE
    .\Trigger-BackupJob.ps1 -JobName "Daily-VM-Backup"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$JobName
)

Import-Module Veeam.Backup.PowerShell -ErrorAction Stop

$logPath = "C:\DR-Pipeline\Logs\backup-log.txt"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

try {
    $job = Get-VBRJob -Name $JobName -ErrorAction Stop
    Start-VBRJob -Job $job

    $session = Get-VBRBackupSession | Where-Object { $_.JobId -eq $job.Id } | Sort-Object CreationTime -Descending | Select-Object -First 1

    if ($session.Result -eq "Success") {
        Add-Content -Path $logPath -Value "$timestamp - SUCCESS - Job '$JobName' completed."
    } else {
        Add-Content -Path $logPath -Value "$timestamp - FAILURE - Job '$JobName' result: $($session.Result)"
    }
}
catch {
    Add-Content -Path $logPath -Value "$timestamp - ERROR - $($_.Exception.Message)"
}
