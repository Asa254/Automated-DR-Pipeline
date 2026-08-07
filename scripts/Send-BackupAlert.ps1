<#
.SYNOPSIS
    Sends an email alert when a backup job has failed.

.DESCRIPTION
    Designed to be called after Check-BackupHealth.ps1 detects a failure.
    Sends a notification email so failures are caught quickly instead of
    being discovered during an actual DR event.

.PARAMETER JobName
    The name of the backup job that failed.

.PARAMETER ErrorDetail
    Optional additional detail about the failure to include in the alert.

.EXAMPLE
    .\Send-BackupAlert.ps1 -JobName "Daily-VM-Backup" -ErrorDetail "Job timed out after 4 hours"
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$JobName,

    [Parameter(Mandatory = $false)]
    [string]$ErrorDetail = "No additional details provided."
)

# --- Configuration (adjust for your environment) ---
$smtpServer = "smtp.yourdomain.com"
$smtpPort   = 587
$from       = "dr-pipeline@yourdomain.com"
$to         = "sysadmin-team@yourdomain.com"
$subject    = "ALERT: Backup Job Failed - $JobName"

$body = @"
A backup job has failed and requires attention.

Job Name:   $JobName
Time:       $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Detail:     $ErrorDetail

Please review the Veeam console and backup-log.txt for more information.
"@

try {
    Send-MailMessage -SmtpServer $smtpServer -Port $smtpPort -From $from -To $to `
        -Subject $subject -Body $body -UseSsl

    Write-Output "Alert sent for job: $JobName"
}
catch {
    Write-Error "Failed to send alert email: $($_.Exception.Message)"
}
