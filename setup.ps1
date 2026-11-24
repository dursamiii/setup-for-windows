
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$shareName = "D-Drive"
$sharePath = "D:\"

try {
    Write-Host "[1/4] Configuring SMB Server..." -ForegroundColor Cyan

    Set-Service -Name LanmanServer -StartupType Automatic
    Start-Service -Name LanmanServer

    Write-Host "[2/4] Configuring NTFS permissions..." -ForegroundColor Cyan

    $acl = Get-Acl $sharePath

    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        "Everyone",
        "ReadAndExecute",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )

    $acl.SetAccessRule($rule)
    Set-Acl -Path $sharePath -AclObject $acl

    Write-Host "[3/4] Creating SMB Share..." -ForegroundColor Cyan

    $existing = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue

    if ($existing) {
        Remove-SmbShare -Name $shareName -Force -Confirm:$false
    }

    New-SmbShare `
        -Name $shareName `
        -Path $sharePath `
        -ReadAccess "Everyone" `
        -FolderEnumerationMode AccessBased | Out-Null

    Write-Host "[4/4] Configuring Firewall..." -ForegroundColor Cyan

    Get-NetFirewallRule -DisplayGroup "File and Printer Sharing" -ErrorAction SilentlyContinue |
        Where-Object { $_.Profile -match "Private" } |
        Enable-NetFirewallRule

    Write-Host "`n[SUCCESS] Configuration complete!" -ForegroundColor Green
    Write-Host "Share: \\$env:COMPUTERNAME\$shareName"
    Write-Host "Access: Read Only"
}
catch {
    Write-Host "`n[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
}

Read-Host "`nPress ENTER to exit"
