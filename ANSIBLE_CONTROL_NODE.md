# Ansible Control Node - Quick Start Guide

## ✅ What Was Created

You now have **5 VMs** running:

| VM Name | Role | IP Address | Memory | vCPU |
|---------|------|------------|--------|------|
| **ansible-control** | Ansible Control Node (Ubuntu 22.04) | 192.168.122.5 | 2 GB | 2 |
| **dc01** | Windows Domain Controller | 192.168.122.10 | 4 GB | 2 |
| **sql01** | SQL Server Node 1 | 192.168.122.11 | 8 GB | 2 |
| **sql02** | SQL Server Node 2 | 192.168.122.12 | 8 GB | 2 |
| **sql03** | SQL Server Node 3 | 192.168.122.13 | 8 GB | 2 |

**Total Resources:** 30 GB RAM, 10 vCPUs

---

## 🚀 Access the Ansible Control Node

### Option 1: SSH (Recommended)

Wait 2-3 minutes for cloud-init to complete, then:

```bash
ssh ansible@192.168.122.5
# Password: ansible123
```

### Option 2: Console via VMM

Open Virtual Machine Manager and double-click **ansible-control**

Default Login:
- Username: `ansible`
- Password: `ansible123`

---

## ⚙️ What's Pre-Installed

The Ansible control node comes with:

✅ **Ansible** - Latest version from Ubuntu repos
✅ **Python 3 + pywinrm** - For Windows management
✅ **Git** - Version control
✅ **Vim, curl, net-tools** - Utilities
✅ **Pre-configured inventory** - Ready to manage Windows VMs
✅ **Static IP** - 192.168.122.5/24

---

## 📋 Pre-Configured Files

All files are in `/home/ansible/`:

### 1. Ansible Configuration
**File:** `~/.ansible.cfg`
```ini
[defaults]
inventory = /home/ansible/lab-inventory.yml
host_key_checking = False
deprecation_warnings = False
interpreter_python = auto_silent
```

### 2. Inventory File
**File:** `~/lab-inventory.yml`

```yaml
all:
  children:
    windows:
      vars:
        ansible_user: Administrator
        ansible_password: CHANGEME  # ← UPDATE THIS!
        ansible_connection: winrm
        ansible_winrm_transport: basic
        ansible_winrm_server_cert_validation: ignore
        ansible_port: 5985

      children:
        domain_controller:
          hosts:
            dc01:
              ansible_host: 192.168.122.10

        sql_nodes:
          hosts:
            sql01:
              ansible_host: 192.168.122.11
            sql02:
              ansible_host: 192.168.122.12
            sql03:
              ansible_host: 192.168.122.13
```

### 3. Directory Structure
```
/home/ansible/
├── .ansible.cfg
├── lab-inventory.yml
├── playbooks/          (empty, ready for your playbooks)
├── group_vars/         (empty, ready for variables)
└── README.md
```

---

## 🔧 First Steps After Login

### 1. SSH into the Control Node
```bash
ssh ansible@192.168.122.5
```

### 2. Update the Windows Admin Password

**IMPORTANT:** Edit the inventory with the actual Windows administrator password:

```bash
vim ~/lab-inventory.yml
# Change ansible_password: CHANGEME to your actual password
```

### 3. Test Connectivity (After Configuring WinRM on Windows VMs)

```bash
# Test ping to all Windows hosts
ansible windows -m win_ping

# Test specific group
ansible domain_controller -m win_ping
ansible sql_nodes -m win_ping
```

---

## 🪟 Configure WinRM on Windows VMs

Before Ansible can manage the Windows VMs, you need to enable WinRM on each one.

### On Each Windows VM (DC01, SQL01, SQL02, SQL03):

1. Open **Virtual Machine Manager**
2. Double-click the VM to open console
3. Login as Administrator
4. Open **PowerShell as Administrator**
5. Run this script:

```powershell
# Enable WinRM for Ansible
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

# Download and run
(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file

# Configure network as Private
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

# Enable Basic Auth
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Restart WinRM
Restart-Service WinRM

Write-Host "WinRM configured for Ansible!" -ForegroundColor Green
```

### Alternative: Copy-Paste Friendly Version

If the above doesn't work (no internet on VMs), you can manually configure:

```powershell
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true
New-NetFirewallRule -DisplayName "WinRM HTTP" -Direction Inbound -LocalPort 5985 -Protocol TCP -Action Allow
Restart-Service WinRM
```

---

## 🧪 Verify Everything Works

### From Ansible Control Node:

```bash
# 1. Test connectivity to all Windows hosts
ansible windows -m win_ping

# 2. Get Windows version
ansible windows -m win_shell -a "systeminfo | findstr /C:'OS Name'"

# 3. Check disk space
ansible windows -m win_shell -a "wmic logicaldisk get caption,freespace,size"

# 4. List services
ansible sql_nodes -m win_service -a "name=W32Time"
```

If all these work, you're ready to run playbooks!

---

## 📚 Next Steps

### 1. Set Static IPs on Windows VMs

Currently, Windows VMs are using DHCP. Set static IPs to match inventory:

**PowerShell on each VM:**

```powershell
# DC01
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.122.10 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1

# SQL01
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.122.11 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.122.10

# SQL02
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.122.12 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.122.10

# SQL03
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.122.13 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.122.10
```

### 2. Create Your First Playbook

```bash
cd ~/playbooks
vim test-connection.yml
```

```yaml
---
- name: Test Windows Connection
  hosts: windows
  gather_facts: no

  tasks:
    - name: Ping Windows hosts
      win_ping:

    - name: Get computer name
      win_shell: hostname
      register: hostname_output

    - name: Display hostname
      debug:
        msg: "Computer name is: {{ hostname_output.stdout }}"
```

Run it:
```bash
ansible-playbook ~/playbooks/test-connection.yml
```

### 3. Set Up Domain Controller

Refer to `ANSIBLE_APPROACH.md` for playbooks to:
- Configure DC01 as Domain Controller
- Join SQL nodes to domain
- Create Windows Failover Cluster
- Install SQL Server 2025

---

## 🔑 Important Credentials

**Ansible Control Node:**
- IP: 192.168.122.5
- Username: ansible
- Password: ansible123
- Sudo: No password required

**Windows VMs:**
- Username: Administrator
- Password: (your Windows admin password)

**To Change Ansible User Password:**
```bash
sudo passwd ansible
```

---

## 🛠️ Useful Commands

### On Ubuntu Host:

```bash
# SSH to Ansible control node
ssh ansible@192.168.122.5

# Check all VMs status
virsh list

# Start Ansible control node
virsh start ansible-control

# Stop Ansible control node
virsh shutdown ansible-control
```

### On Ansible Control Node:

```bash
# List all managed hosts
ansible all --list-hosts

# Test connectivity
ansible windows -m win_ping

# Run ad-hoc commands
ansible windows -m win_shell -a "ipconfig"

# Run playbook
ansible-playbook playbooks/your-playbook.yml

# Check syntax
ansible-playbook playbooks/your-playbook.yml --syntax-check

# Dry run
ansible-playbook playbooks/your-playbook.yml --check
```

---

## 🔄 Cloud-Init Logs

If the Ansible control node doesn't boot properly, check cloud-init logs:

```bash
# Via console in VMM
sudo tail -f /var/log/cloud-init-output.log

# Check if setup completed
cat /home/ansible/setup-complete.txt
```

---

## 📊 Resource Summary

```
Network: 192.168.122.0/24 (libvirt default)

├── ansible-control (192.168.122.5)  [Ubuntu 22.04]
│   └── Manages all Windows VMs via WinRM
├── dc01 (192.168.122.10)             [Windows Server 2022]
├── sql01 (192.168.122.11)            [Windows Server 2022]
├── sql02 (192.168.122.12)            [Windows Server 2022]
└── sql03 (192.168.122.13)            [Windows Server 2022]
```

---

## 🎯 What You've Achieved

✅ Infrastructure as Code - Complete lab provisioned via Terraform
✅ Dedicated management node - Production-like setup
✅ Automated configuration - Cloud-init auto-setup of Ansible
✅ Ready for automation - Pre-configured inventory and tooling
✅ Scalable approach - Easy to add more VMs

---

## 📖 Related Documentation

- [ANSIBLE_APPROACH.md](ANSIBLE_APPROACH.md) - Complete Ansible strategy
- [VIRSH_COMMANDS.md](VIRSH_COMMANDS.md) - VM management reference
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Terraform troubleshooting guide

---

**You're now ready to automate your entire Windows SQL cluster setup using Ansible!** 🚀
