#!/bin/bash
# Generate PowerShell scripts for manual Windows VM configuration
# Use this if bootstrap-windows.sh doesn't work

echo "Generating manual setup scripts..."

# DC01 Setup Script
cat > setup-dc01.ps1 << 'PSEOF'
# Configuration script for DC01
# Run this in PowerShell as Administrator on DC01

Write-Host "Configuring DC01..." -ForegroundColor Cyan

# Get network adapter
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
$adapterName = $adapter.Name

# Remove existing IP configuration
Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

# Set static IP
New-NetIPAddress -InterfaceAlias $adapterName -IPAddress 192.168.122.10 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses 127.0.0.1

# Enable WinRM
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Configure firewall
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# Set network profile to Private
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

# Restart WinRM
Restart-Service WinRM

Write-Host "DC01 configuration complete!" -ForegroundColor Green
Write-Host "IP Address: 192.168.122.10" -ForegroundColor Yellow
Write-Host "DNS Server: 127.0.0.1" -ForegroundColor Yellow
PSEOF

# SQL01 Setup Script
cat > setup-sql01.ps1 << 'PSEOF'
# Configuration script for SQL01
# Run this in PowerShell as Administrator on SQL01

Write-Host "Configuring SQL01..." -ForegroundColor Cyan

# Get network adapter
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
$adapterName = $adapter.Name

# Remove existing IP configuration
Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

# Set static IP
New-NetIPAddress -InterfaceAlias $adapterName -IPAddress 192.168.122.11 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses 192.168.122.10

# Enable WinRM
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Configure firewall
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# Set network profile to Private
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

# Restart WinRM
Restart-Service WinRM

Write-Host "SQL01 configuration complete!" -ForegroundColor Green
Write-Host "IP Address: 192.168.122.11" -ForegroundColor Yellow
Write-Host "DNS Server: 192.168.122.10" -ForegroundColor Yellow
PSEOF

# SQL02 Setup Script
cat > setup-sql02.ps1 << 'PSEOF'
# Configuration script for SQL02
# Run this in PowerShell as Administrator on SQL02

Write-Host "Configuring SQL02..." -ForegroundColor Cyan

# Get network adapter
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
$adapterName = $adapter.Name

# Remove existing IP configuration
Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

# Set static IP
New-NetIPAddress -InterfaceAlias $adapterName -IPAddress 192.168.122.12 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses 192.168.122.10

# Enable WinRM
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Configure firewall
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# Set network profile to Private
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

# Restart WinRM
Restart-Service WinRM

Write-Host "SQL02 configuration complete!" -ForegroundColor Green
Write-Host "IP Address: 192.168.122.12" -ForegroundColor Yellow
Write-Host "DNS Server: 192.168.122.10" -ForegroundColor Yellow
PSEOF

# SQL03 Setup Script
cat > setup-sql03.ps1 << 'PSEOF'
# Configuration script for SQL03
# Run this in PowerShell as Administrator on SQL03

Write-Host "Configuring SQL03..." -ForegroundColor Cyan

# Get network adapter
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
$adapterName = $adapter.Name

# Remove existing IP configuration
Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

# Set static IP
New-NetIPAddress -InterfaceAlias $adapterName -IPAddress 192.168.122.13 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses 192.168.122.10

# Enable WinRM
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Configure firewall
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# Set network profile to Private
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

# Restart WinRM
Restart-Service WinRM

Write-Host "SQL03 configuration complete!" -ForegroundColor Green
Write-Host "IP Address: 192.168.122.13" -ForegroundColor Yellow
Write-Host "DNS Server: 192.168.122.10" -ForegroundColor Yellow
PSEOF

echo "✓ Manual setup scripts generated:"
echo "  - setup-dc01.ps1"
echo "  - setup-sql01.ps1"
echo "  - setup-sql02.ps1"
echo "  - setup-sql03.ps1"
echo ""
echo "Instructions:"
echo "1. Open each VM in Virtual Machine Manager"
echo "2. Login as Administrator"
echo "3. Open PowerShell as Administrator"
echo "4. Copy and paste the contents of the corresponding setup script"
echo "5. Press Enter to execute"
echo ""
echo "After all VMs are configured:"
echo "  ssh ansible@192.168.122.5"
echo "  vim ~/lab-inventory.yml (update password)"
echo "  ./deploy-lab.sh"
