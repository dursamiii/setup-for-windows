
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$username = "$env:COMPUTERNAME\default"
$drives = @("E:", "F:", "G:")

try {
    Write-Host "[1/3] Configuring SMB Server..."

    Set-Service LanmanServer -StartupType Automatic
    Start-Service LanmanServer

    Write-Host "[2/3] Configuring drive permissions..."

    foreach ($drive in $drives) {
        if (-not (Test-Path "$drive\")) {
            Write-Host "Skipping unavailable drive: $drive"
            continue
        }

        & icacls.exe "$drive\" /grant "${username}:(OI)(CI)F"

        if ($LASTEXITCODE -ne 0) {
            throw "Failed to configure NTFS permissions on $drive"
        }
    }

    Write-Host "[3/3] Creating SMB shares..."

    foreach ($drive in $drives) {
        if (-not (Test-Path "$drive\")) {
            continue
        }

        $shareName = "$($drive[0])-Drive"

        $existing = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue

        if ($existing) {
            Remove-SmbShare -Name $shareName -Force -Confirm:$false
        }

        New-SmbShare `
            -Name $shareName `
            -Path "$drive\" `
            -FullAccess $username | Out-Null
    }

    Write-Host "`n[SUCCESS] Drive sharing configured!" -ForegroundColor Green

    foreach ($drive in $drives) {
        if (Test-Path "$drive\") {
            Write-Host "\\$env:COMPUTERNAME\$($drive[0])-Drive"
        }
    }
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Read-Host "`nPress ENTER to exit"
