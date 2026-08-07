<#
.SYNOPSIS
    Checks the health/status of recent Veeam backup jobs.

.DESCRIPTION
    Reviews the most recent backup session for each specified job and reports
    whether it succeeded, failed, or is still running. Designed to run after
    Trigger-BackupJob.ps1 to confirm backups completed as expected before
    they're relied on for DR.

.PARAMETER JobNames
    One or more Veeam job names to check.

.EXAMPLE
    .\Check-BackupHealth.ps1 -JobNames "Daily-VM-Backup","Weekly-Full-Backup"
#>

param(
    [Parameter(Mandatory = $true)]
    [string[]]$JobNames
)

Import-Module Veeam.Backup.PowerShell -ErrorAction Stop

$results = foreach ($name in $JobNames) {
    $job = Get-VBRJob -Name $name -ErrorAction SilentlyContinue

    if (-not $job) {
        [PSCustomObject]@{
            JobName = $name
            Status  = "NOT FOUND"
            LastRun = $null
        }
        continue
    }

    $session = Get-VBRBackupSession |
        Where-Object { $_.JobId -eq $job.Id } |
        Sort-Object CreationTime -Descending |
        Select-Object -First 1

    [PSCustomObject]@{
        JobName = $name
        Status  = $session.Result
        LastRun = $session.CreationTime
    }
}

$results | Format-Table -AutoSize

# Exit with non-zero code if any job failed, useful for alerting/CI hooks
if ($results.Status -contains "Failed") {
    exit 1
} else {
    exit 0
}
