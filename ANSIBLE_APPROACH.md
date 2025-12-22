# Ansible Automation Approach for Windows SQL Cluster Lab

## Overview

We'll use Ansible to automate the complete setup of your Windows Server lab:
1. Configure DC01 as Active Directory Domain Controller
2. Join SQL nodes to the domain
3. Create Windows Server Failover Cluster (WSFC)
4. Install SQL Server 2025 Developer Edition on all SQL nodes

---

## Architecture

```
Ubuntu Host (Ansible Control Node)
    |
    ├── Ansible Playbooks
    |   └── WinRM Connection
    |       ├── DC01 (Domain Controller)
    |       ├── SQL01 (Cluster Node 1)
    |       ├── SQL02 (Cluster Node 2)
    |       └── SQL03 (Cluster Node 3)
```

---

## Prerequisites

### 1. Ansible on Ubuntu Host
```bash
# Install Ansible
sudo apt update
sudo apt install ansible -y

# Install Windows support packages
sudo apt install python3-pip -y
pip3 install pywinrm

# Verify installation
ansible --version
```

### 2. Configure WinRM on Windows VMs

**WinRM** (Windows Remote Management) is how Ansible communicates with Windows hosts.

You'll need to run this PowerShell script on **each Windows VM** (DC01, SQL01, SQL02, SQL03):

```powershell
# Run this in PowerShell as Administrator on each Windows VM

# Enable WinRM and configure for Ansible
$url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
$file = "$env:temp\ConfigureRemotingForAnsible.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file

# Set network to Private (required for WinRM)
Get-NetConnectionProfile | Set-NetConnectionProfile -NetworkCategory Private

# Allow WinRM through firewall
Enable-PSRemoting -Force
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# Restart WinRM service
Restart-Service WinRM
```

**Alternative: Manual Setup**
1. Open each VM in Virtual Machine Manager
2. Log in as Administrator
3. Open PowerShell as Administrator
4. Copy-paste and run the above script

### 3. Set Static IPs (Before Ansible)

For networking to work properly, set static IPs on all VMs:

| VM | IP Address | Subnet | Gateway | DNS |
|----|------------|--------|---------|-----|
| DC01 | 192.168.122.10 | 255.255.255.0 | 192.168.122.1 | 127.0.0.1 (after DC setup) |
| SQL01 | 192.168.122.11 | 255.255.255.0 | 192.168.122.1 | 192.168.122.10 |
| SQL02 | 192.168.122.12 | 255.255.255.0 | 192.168.122.1 | 192.168.122.10 |
| SQL03 | 192.168.122.13 | 255.255.255.0 | 192.168.122.1 | 192.168.122.10 |

**PowerShell command to set static IP (run on each VM):**
```powershell
# Example for DC01
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.122.10 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1

# Example for SQL01
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.122.11 -PrefixLength 24 -DefaultGateway 192.168.122.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 192.168.122.10
```

---

## Project Structure

```
TestVMs/
├── ansible/
│   ├── inventory.yml                 # Ansible inventory with all hosts
│   ├── group_vars/
│   │   ├── all.yml                   # Variables for all hosts
│   │   ├── domain_controller.yml     # DC-specific variables
│   │   └── sql_nodes.yml             # SQL-specific variables
│   ├── playbooks/
│   │   ├── 01-setup-dc.yml          # Setup Domain Controller
│   │   ├── 02-join-domain.yml       # Join SQL nodes to domain
│   │   ├── 03-configure-cluster.yml # Setup WSFC
│   │   └── 04-install-sqlserver.yml # Install SQL Server
│   ├── roles/                        # Ansible roles (optional, advanced)
│   └── ansible.cfg                   # Ansible configuration
├── main.tf
├── SETUP_GUIDE.md
├── VIRSH_COMMANDS.md
└── ANSIBLE_APPROACH.md (this file)
```

---

## Implementation Phases

### Phase 1: Initial Setup (Manual/Preparation)
**Goal:** Get VMs ready for Ansible management

**Tasks:**
1. ✅ VMs created via Terraform (DONE)
2. Set static IP addresses on all VMs
3. Configure WinRM on all VMs
4. Test Ansible connectivity

**Estimated time:** 30-45 minutes

---

### Phase 2: Domain Controller Setup
**Goal:** Configure DC01 as Active Directory Domain Controller

**Playbook:** `01-setup-dc.yml`

**Tasks:**
1. Rename computer to DC01
2. Install AD DS role
3. Promote to Domain Controller
4. Create domain (e.g., `sqllab.local`)
5. Configure DNS
6. Create domain admin account for Ansible
7. Reboot and verify

**Key Ansible modules:**
- `win_hostname` - Rename computer
- `win_feature` - Install Windows features
- `win_domain` - Promote to DC
- `win_domain_user` - Create users
- `win_reboot` - Reboot handling

**Estimated time:** 15-30 minutes (automated)

---

### Phase 3: Domain Join SQL Nodes
**Goal:** Join SQL01, SQL02, SQL03 to the domain

**Playbook:** `02-join-domain.yml`

**Tasks:**
1. Rename computers (SQL01, SQL02, SQL03)
2. Set DNS to DC01 IP
3. Join domain (sqllab.local)
4. Reboot
5. Verify domain membership

**Key Ansible modules:**
- `win_hostname` - Rename computers
- `win_dns_client` - Configure DNS
- `win_domain_membership` - Join domain
- `win_reboot` - Reboot handling

**Estimated time:** 10-15 minutes (automated)

---

### Phase 4: Windows Server Failover Cluster
**Goal:** Create WSFC with all 3 SQL nodes

**Playbook:** `03-configure-cluster.yml`

**Prerequisites:**
- All nodes domain-joined
- Failover Clustering feature installed
- Shared storage (optional for this lab)

**Tasks:**
1. Install Failover Clustering feature on all nodes
2. Configure cluster networking
3. Create WSFC cluster
4. Add all nodes to cluster
5. Configure cluster quorum
6. Verify cluster status

**Key Ansible modules:**
- `win_feature` - Install Failover Clustering
- `win_powershell` - Run cluster creation scripts
- `win_shell` - Execute PowerShell commands

**Estimated time:** 20-30 minutes (automated)

---

### Phase 5: SQL Server Installation
**Goal:** Install SQL Server 2025 Developer Edition on all nodes

**Playbook:** `04-install-sqlserver.yml`

**Prerequisites:**
- SQL Server 2025 ISO downloaded
- ISO mounted or extracted on each node

**Tasks:**
1. Download SQL Server 2025 installer (or use local copy)
2. Create SQL service accounts
3. Install SQL Server with:
   - Database Engine
   - SQL Server Agent
   - Always On Availability Groups enabled
4. Configure SQL Server instances
5. Enable Always On AG
6. Configure firewall rules
7. Verify installation

**Key Ansible modules:**
- `win_get_url` - Download installer
- `win_package` - Install software
- `win_powershell` - Configuration scripts
- `win_firewall_rule` - Firewall configuration
- `win_service` - Service management

**Estimated time:** 30-45 minutes per node (automated, parallel)

---

## Detailed Step-by-Step Approach

### Step 1: Create Ansible Directory Structure

```bash
cd /home/maxdop1/projects/TestVMs
mkdir -p ansible/{playbooks,group_vars}
```

### Step 2: Create Ansible Configuration

**File:** `ansible/ansible.cfg`
```ini
[defaults]
inventory = inventory.yml
host_key_checking = False
deprecation_warnings = False
interpreter_python = auto_silent

[inventory]
enable_plugins = yaml
```

### Step 3: Create Inventory File

**File:** `ansible/inventory.yml`
```yaml
all:
  children:
    windows:
      vars:
        ansible_user: Administrator
        ansible_password: YourWindowsPassword  # Change this!
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

### Step 4: Create Variables Files

**File:** `ansible/group_vars/all.yml`
```yaml
---
# Domain configuration
domain_name: sqllab.local
domain_netbios_name: SQLLAB
safe_mode_password: P@ssw0rd123!  # Change this!

# Network configuration
domain_controller_ip: 192.168.122.10
dns_servers:
  - 192.168.122.10

# SQL Server configuration
sql_version: "2025"
sql_edition: Developer
sql_install_path: "C:\\SQLServer"
sql_data_path: "C:\\SQLData"
sql_log_path: "C:\\SQLLogs"

# Cluster configuration
cluster_name: SQLCLUSTER
cluster_ip: 192.168.122.20
```

**File:** `ansible/group_vars/domain_controller.yml`
```yaml
---
# Domain Controller specific variables
computer_name: DC01
forest_functional_level: WinThreshold
domain_functional_level: WinThreshold
```

**File:** `ansible/group_vars/sql_nodes.yml`
```yaml
---
# SQL nodes specific variables
sql_service_account: "{{ domain_netbios_name }}\\sqlservice"
sql_agent_account: "{{ domain_netbios_name }}\\sqlagent"
```

### Step 5: Test Connectivity

```bash
cd /home/maxdop1/projects/TestVMs/ansible

# Test ping to all Windows hosts
ansible windows -m win_ping

# Expected output:
# dc01 | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

---

## Playbook Examples

### Playbook 1: Setup Domain Controller

**File:** `ansible/playbooks/01-setup-dc.yml`

```yaml
---
- name: Configure DC01 as Active Directory Domain Controller
  hosts: domain_controller
  gather_facts: no

  tasks:
    - name: Set hostname to DC01
      win_hostname:
        name: DC01
      register: hostname_change

    - name: Reboot if hostname changed
      win_reboot:
      when: hostname_change.reboot_required

    - name: Install AD DS feature
      win_feature:
        name: AD-Domain-Services
        include_management_tools: yes
      register: adds_install

    - name: Reboot after AD DS installation
      win_reboot:
      when: adds_install.reboot_required

    - name: Promote to Domain Controller
      win_domain:
        dns_domain_name: "{{ domain_name }}"
        safe_mode_password: "{{ safe_mode_password }}"
        domain_netbios_name: "{{ domain_netbios_name }}"
      register: dc_promotion

    - name: Reboot after DC promotion
      win_reboot:
        msg: "Rebooting after Domain Controller promotion"
      when: dc_promotion.reboot_required

    - name: Wait for Active Directory Web Services
      win_service:
        name: ADWS
        state: started
      retries: 5
      delay: 10

    - name: Create SQL service accounts
      win_domain_user:
        name: "{{ item.name }}"
        password: "{{ item.password }}"
        state: present
        path: "CN=Users,DC=sqllab,DC=local"
        groups:
          - Domain Users
      loop:
        - { name: "sqlservice", password: "SQLService123!" }
        - { name: "sqlagent", password: "SQLAgent123!" }
        - { name: "sqlansible", password: "SQLAnsible123!" }
```

**Run:**
```bash
ansible-playbook playbooks/01-setup-dc.yml
```

---

### Playbook 2: Join SQL Nodes to Domain

**File:** `ansible/playbooks/02-join-domain.yml`

```yaml
---
- name: Join SQL nodes to domain
  hosts: sql_nodes
  gather_facts: no

  tasks:
    - name: Set hostname
      win_hostname:
        name: "{{ inventory_hostname }}"
      register: hostname_change

    - name: Configure DNS to point to DC
      win_dns_client:
        adapter_names: "*"
        dns_servers: "{{ domain_controller_ip }}"

    - name: Reboot if hostname changed
      win_reboot:
      when: hostname_change.reboot_required

    - name: Join domain
      win_domain_membership:
        dns_domain_name: "{{ domain_name }}"
        domain_admin_user: "{{ domain_netbios_name }}\\Administrator"
        domain_admin_password: "{{ ansible_password }}"
        state: domain
      register: domain_join

    - name: Reboot after domain join
      win_reboot:
        msg: "Rebooting after joining domain"
      when: domain_join.reboot_required
```

**Run:**
```bash
ansible-playbook playbooks/02-join-domain.yml
```

---

## Benefits of Using Ansible

### ✅ Advantages

1. **Infrastructure as Code** - All configuration is version-controlled
2. **Repeatability** - Can destroy and rebuild lab in minutes
3. **Idempotent** - Safe to run multiple times
4. **Documentation** - Playbooks serve as documentation
5. **Testing** - Can test on one node before rolling out to all
6. **Consistency** - All nodes configured identically
7. **Speed** - Parallel execution on multiple hosts

### ⚠️ Considerations

1. **Initial Setup** - WinRM configuration requires manual work first
2. **Learning Curve** - Need to learn Ansible syntax and Windows modules
3. **Debugging** - Windows errors can be cryptic
4. **Network** - Requires network connectivity to all VMs

---

## Alternative Approaches

If Ansible seems too complex initially, consider:

### 1. **PowerShell DSC (Desired State Configuration)**
- Native Windows automation
- Similar concept to Ansible
- Can be complex for beginners

### 2. **Manual + Documentation**
- Document all steps
- Create PowerShell scripts
- Faster initially, slower long-term

### 3. **Hybrid Approach**
- Use Ansible for some tasks (domain join, basic config)
- Manual for complex tasks (SQL AG configuration)

---

## Recommended Implementation Order

### Week 1: Foundation
1. ✅ VMs created (DONE)
2. Configure static IPs manually
3. Enable WinRM on all VMs
4. Install Ansible on Ubuntu host
5. Test connectivity

### Week 2: Domain Setup
1. Create Ansible inventory
2. Build DC setup playbook
3. Run DC promotion
4. Test domain functionality

### Week 3: Domain Join & Clustering
1. Build domain join playbook
2. Join SQL nodes
3. Build cluster setup playbook
4. Create WSFC

### Week 4: SQL Server
1. Download SQL Server 2025
2. Build SQL installation playbook
3. Install SQL on all nodes
4. Configure Always On AG

---

## Next Steps

### Immediate Action Items:

1. **Install Ansible on Ubuntu host**
   ```bash
   sudo apt install ansible python3-pip -y
   pip3 install pywinrm
   ```

2. **Create ansible directory structure**
   ```bash
   cd /home/maxdop1/projects/TestVMs
   mkdir -p ansible/{playbooks,group_vars}
   ```

3. **Set static IPs on all VMs** (via VMM console)

4. **Configure WinRM** on each VM

5. **Create initial inventory file** with your passwords

6. **Test connectivity**
   ```bash
   ansible windows -m win_ping
   ```

---

## Resources

- [Ansible Windows Guide](https://docs.ansible.com/ansible/latest/os_guide/windows_usage.html)
- [Windows Ansible Modules](https://docs.ansible.com/ansible/latest/collections/ansible/windows/index.html)
- [WinRM Setup Guide](https://docs.ansible.com/ansible/latest/os_guide/windows_setup.html)
- [SQL Server Installation Guide](https://learn.microsoft.com/en-us/sql/database-engine/install-windows/install-sql-server)

---

## Questions to Consider

Before we start building the playbooks:

1. **Domain name:** Is `sqllab.local` good, or different name?
2. **Passwords:** Will you use the same admin password on all VMs?
3. **SQL Server:** Do you have SQL Server 2025 ISO/installer already?
4. **Shared Storage:** Do you need shared storage for cluster, or node-local?
5. **Availability Group:** How many databases? Multi-subnet AG?

Let me know, and we can start building piece by piece! 🚀
