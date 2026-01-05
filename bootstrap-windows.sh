#!/bin/bash
# Bootstrap script to configure Windows VMs for Ansible management
# Run this ONCE after terraform apply to set up static IPs and WinRM

set -e

echo "=========================================="
echo "Windows VM Bootstrap Script"
echo "=========================================="
echo ""
echo "This script will configure DC01, SQL01, SQL02, SQL03 for Ansible:"
echo "  - Set static IP addresses"
echo "  - Enable and configure WinRM"
echo "  - Configure firewall rules"
echo ""

# Prompt for Windows Administrator password
read -sp "Enter Windows Administrator password: " WIN_PASSWORD
echo ""

# VM configuration
declare -A VMS
VMS[dc01]="192.168.122.10"
VMS[sql01]="192.168.122.11"
VMS[sql02]="192.168.122.12"
VMS[sql03]="192.168.122.13"

# PowerShell script to configure Windows
read -r -d '' SETUP_SCRIPT << 'PSEOF'
# Get the network adapter name (usually "Ethernet" or "Ethernet Instance 0")
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1
$adapterName = $adapter.Name

# Remove existing IP configuration
Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

# Set static IP
New-NetIPAddress -InterfaceAlias $adapterName -IPAddress IPADDRESS -PrefixLength 24 -DefaultGateway 192.168.122.1 -ErrorAction SilentlyContinue

# Set DNS
Set-DnsClientServerAddress -InterfaceAlias $adapterName -ServerAddresses DNSSERVER

# Enable WinRM
Enable-PSRemoting -Force -SkipNetworkProfileCheck
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Configure WinRM firewall rules
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue

# Set network profile to Private
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

# Restart WinRM service
Restart-Service WinRM

Write-Host "Configuration complete for VMNAME!" -ForegroundColor Green
PSEOF

echo ""
echo "Configuring Windows VMs..."
echo ""

# Function to configure a VM
configure_vm() {
    local vm_name=$1
    local vm_ip=$2
    local dns_server=$3

    echo "----------------------------------------"
    echo "Configuring: $vm_name ($vm_ip)"
    echo "----------------------------------------"

    # Get current IP (DHCP assigned)
    current_ip=$(virsh domifaddr "$vm_name" | grep -oP '(\d+\.){3}\d+' | head -1)

    if [ -z "$current_ip" ]; then
        echo "ERROR: Could not detect IP for $vm_name"
        echo "Make sure the VM is running and has network connectivity"
        return 1
    fi

    echo "Current IP: $current_ip"
    echo "Target IP: $vm_ip"

    # Prepare the PowerShell script with actual values
    vm_setup_script="${SETUP_SCRIPT//IPADDRESS/$vm_ip}"
    vm_setup_script="${vm_setup_script//DNSSERVER/$dns_server}"
    vm_setup_script="${vm_setup_script//VMNAME/$vm_name}"

    # Execute via PowerShell remoting if available, otherwise save script and execute
    echo "Attempting to configure $vm_name..."

    # Try to execute the script using WinRM (if already enabled from a previous setup)
    if command -v python3 >/dev/null 2>&1; then
        # Use Python winrm to execute the script
        python3 - <<PYEOF
import winrm
import sys

try:
    s = winrm.Session('http://${current_ip}:5985/wsman', auth=('Administrator', '${WIN_PASSWORD}'), transport='ntlm')
    script = '''${vm_setup_script}'''
    result = s.run_ps(script)
    print(result.std_out.decode('utf-8'))
    if result.status_code != 0:
        print(result.std_err.decode('utf-8'), file=sys.stderr)
        sys.exit(1)
except Exception as e:
    print(f"Note: Could not connect via WinRM (this is expected on first run): {e}")
    print("You'll need to manually run the setup on this VM - see manual-setup.ps1")
    sys.exit(1)
PYEOF
        if [ $? -eq 0 ]; then
            echo "✓ $vm_name configured successfully"
            return 0
        fi
    fi

    echo "⚠ Could not auto-configure $vm_name"
    echo "  Please manually run the PowerShell script on $vm_name"
    echo "  Script saved to: manual-setup-${vm_name}.ps1"

    # Save script for manual execution
    vm_setup_manual="${vm_setup_script}"
    echo "$vm_setup_manual" > "manual-setup-${vm_name}.ps1"

    return 1
}

# Install Python winrm if not present
if ! python3 -c "import winrm" 2>/dev/null; then
    echo "Installing Python WinRM module..."
    pip3 install pywinrm --user || sudo pip3 install pywinrm
fi

# Configure each VM
failed_vms=()

# DC01 first (DNS points to itself)
if ! configure_vm "dc01" "${VMS[dc01]}" "127.0.0.1"; then
    failed_vms+=("dc01")
fi

# SQL nodes (DNS points to DC01)
for vm in sql01 sql02 sql03; do
    if ! configure_vm "$vm" "${VMS[$vm]}" "${VMS[dc01]}"; then
        failed_vms+=("$vm")
    fi
done

echo ""
echo "=========================================="
echo "Bootstrap Summary"
echo "=========================================="

if [ ${#failed_vms[@]} -eq 0 ]; then
    echo "✓ All VMs configured successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. SSH to ansible-control: ssh ansible@192.168.122.5"
    echo "  2. Run: ./deploy-lab.sh"
    echo ""
else
    echo "⚠ Some VMs require manual configuration:"
    for vm in "${failed_vms[@]}"; do
        echo "  - $vm: See manual-setup-${vm}.ps1"
    done
    echo ""
    echo "Manual setup instructions:"
    echo "  1. Open the VM in Virtual Machine Manager"
    echo "  2. Login as Administrator"
    echo "  3. Open PowerShell as Administrator"
    echo "  4. Copy and paste the contents of manual-setup-<vmname>.ps1"
    echo "  5. After all VMs are configured, run: ssh ansible@192.168.122.5"
    echo "  6. Then run: ./deploy-lab.sh"
fi

echo "=========================================="
