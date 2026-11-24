
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$username = "default"
$password = ConvertTo-SecureString "12345677" -AsPlainText -Force

try {
    Write-Host "[1/3] Configuring user..." -ForegroundColor Cyan

    $user = Get-LocalUser -Name $username -ErrorAction SilentlyContinue

    if (-not $user) {
        New-LocalUser -Name $username -Password $password -Description "Local Administrator" | Out-Null
    }
    else {
        Set-LocalUser -Name $username -Password $password
    }

    Add-LocalGroupMember -Group "Administrators" -Member $username -ErrorAction SilentlyContinue

    Write-Host "[2/3] Configuring drive permissions..." -ForegroundColor Cyan

    $acl = Get-Acl "D:\"

    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $username,
        "FullControl",
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )

    $acl.SetAccessRule($rule)
    Set-Acl -Path "D:\" -AclObject $acl

    Write-Host "[3/3] Setup complete!" -ForegroundColor Green

    Write-Host "Username: $username"
    Write-Host "Password: 12345677"
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
}

Read-Host "Press ENTER to exit"
