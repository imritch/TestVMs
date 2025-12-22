# Troubleshooting Guide

## Ansible Control Node Login Issues

### Issue: Cannot login with ansible/ansible123

**Likely Cause:** Cloud-init is still running or failed to complete.

#### Solution 1: Check Cloud-Init Status

```bash
# Access VM via VMM console
# Try to login as root (no password might be needed initially)

# Check cloud-init status
sudo cloud-init status

# View cloud-init logs
sudo tail -100 /var/log/cloud-init-output.log

# Check if setup completed
cat /home/ansible/setup-complete.txt
```

#### Solution 2: Reset Password Manually

**Via VMM Console (as root):**
```bash
# Set password for ansible user
passwd ansible
# Enter: ansible123

# Or create the user if it doesn't exist
useradd -m -s /bin/bash ansible
passwd ansible
usermod -aG sudo ansible

# Enable passwordless sudo
echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
```

#### Solution 3: Access via Root

```bash
# In VMM console, try logging in as root
# Cloud images often allow root login initially

# Then switch to ansible user
su - ansible

# Or create/fix the ansible user
```

#### Solution 4: Use virt-customize (from Ubuntu host)

```bash
# Reset the ansible user password
sudo virt-customize -d ansible-control --run-command "echo 'ansible:ansible123' | chpasswd"

# Or reset root password
sudo virt-customize -d ansible-control --root-password password:rootpass123

# Reboot VM
virsh reboot ansible-control
```

---

## Network Connectivity Issues

### Issue: Cannot ping 192.168.122.5

#### Check 1: VM Network Status

```bash
# In VMM console
ip addr show
ip route

# Should see:
# - IP: 192.168.122.5/24
# - Gateway: 192.168.122.1
```

#### Check 2: Netplan Configuration

```bash
# View current netplan config
cat /etc/netplan/50-cloud-init.yaml

# Apply netplan
sudo netplan apply

# Check again
ip addr show
```

#### Check 3: Firewall

```bash
# Check if UFW is blocking
sudo ufw status

# Disable if needed (lab environment)
sudo ufw disable
```

---

## Windows VM - WinRM Not Working

### Issue: ansible windows -m win_ping fails

#### Solution 1: Verify WinRM is Running

**On Windows VM (PowerShell as Admin):**
```powershell
# Check WinRM service
Get-Service WinRM

# If not running
Start-Service WinRM

# Check listeners
winrm enumerate winrm/config/listener

# Test WinRM
Test-WSMan -ComputerName localhost
```

#### Solution 2: Reconfigure WinRM

**On Windows VM:**
```powershell
# Complete reset and reconfigure
winrm quickconfig -force

# Enable Basic Auth
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Configure firewall
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow

# Restart
Restart-Service WinRM
```

#### Solution 3: Test from Ansible Control Node

```bash
# Test WinRM connectivity
curl -u "Administrator:YourPassword" http://192.168.122.10:5985/wsman

# Should get XML response, not connection refused
```

---

## Common Terraform Issues

### Issue: "Cannot access storage file"

#### Solution:
```bash
# Check if disk images exist
ls -la /home/maxdop1/projects/sqlserverlab/images/

# Destroy and recreate
terraform destroy -auto-approve
terraform apply -auto-approve
```

### Issue: VMs not starting

```bash
# Check VM status
virsh list --all

# Start individual VM
virsh start ansible-control

# Check logs
sudo tail /var/log/libvirt/qemu/ansible-control.log
```

---

## Quick Diagnostics

### Check All VMs Status
```bash
virsh list --all
```

### Check Network
```bash
virsh net-list
virsh net-info default
```

### Recreate Ansible Control Node Only
```bash
# If ansible-control is broken, recreate just that VM
terraform destroy -target=libvirt_domain.ansible_control -auto-approve
terraform destroy -target=libvirt_cloudinit_disk.ansible_init -auto-approve
terraform apply -auto-approve
```

---

## Emergency Reset

If everything is broken:

```bash
# Full teardown
terraform destroy -auto-approve

# Clean libvirt
virsh list --all
virsh destroy <vm-name>  # for any running VMs
virsh undefine <vm-name>

# Recreate everything
terraform apply -auto-approve
```

---

## Useful Debug Commands

### Check Cloud-Init on ansible-control
```bash
# Via VMM console
sudo cloud-init status --long
sudo cloud-init analyze show
sudo cat /var/log/cloud-init.log
```

### Check Ansible Installation
```bash
# Via VMM console as ansible user
ansible --version
python3 --version
pip3 list | grep winrm
```

### Check Pre-created Files
```bash
# Via VMM console as ansible user
ls -la ~/
cat ~/.ansible.cfg
cat ~/lab-inventory.yml
cat ~/README.md
```

---

## Contact Points When Resuming

1. ✅ All 5 VMs created via Terraform
2. ✅ Pushed to Git
3. ⏸️ Need to access ansible-control VM
4. ⏸️ Then configure WinRM on Windows VMs
5. ⏸️ Then start Ansible automation

---

## Next Session Checklist

- [ ] Access ansible-control VM (troubleshoot if needed)
- [ ] Verify Ansible is installed (`ansible --version`)
- [ ] Update inventory with Windows admin password
- [ ] Configure WinRM on all Windows VMs
- [ ] Set static IPs on Windows VMs
- [ ] Test connectivity: `ansible windows -m win_ping`
- [ ] Start creating playbooks!

---

**Don't worry - the hard part (Terraform infrastructure) is done! The ansible VM access is a minor hurdle.** 🚀
