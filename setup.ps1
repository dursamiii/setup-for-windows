
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$shareName = "D"
$sharePath = "D:\"

Write-Host "Configuring Samba / SMB..." -ForegroundColor Cyan

try {
    # Create dedicated shared folder
    New-Item -ItemType Directory -Path $sharePath -Force | Out-Null

    # Enable SMB server
    Set-Service -Name LanmanServer -StartupType Automatic
    Start-Service -Name LanmanServer

    # Configure folder permissions
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

    # Create read-only share
    if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
        Remove-SmbShare -Name $shareName -Force
    }

    New-SmbShare `
        -Name $shareName `
        -Path $sharePath `
        -ReadAccess "Everyone" `
        -FolderEnumerationMode AccessBased | Out-Null

    # Restrict SMB firewall rules to Private networks
    Set-NetFirewallRule `
        -DisplayGroup "File and Printer Sharing" `
        -Profile Private `
        -Enabled True

    Write-Host "Configuration complete." -ForegroundColor Green
    Write-Host "Share: \\$env:COMPUTERNAME\$shareName"
    Write-Host "Path: $sharePath"
}
catch {
    Write-Host "Configuration failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
