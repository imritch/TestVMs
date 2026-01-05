# Automated SQL Server Lab Deployment

This guide provides a **fully automated** approach to deploying your SQL Server lab with minimal manual intervention.

## Overview

The automation handles:
- ✓ VM provisioning (Terraform)
- ✓ Ansible control node setup (cloud-init)
- ✓ Windows VM networking (automated or manual)
- ✓ Active Directory installation on DC01
- ✓ Domain join for SQL nodes (optional)
- ✓ Failover cluster setup (optional)

## Prerequisites

- KVM/libvirt installed on host
- Windows Server qcow2 images at `/home/maxdop1/projects/sqlserverlab/images/`
- SSH key pair generated
- Windows Administrator password (you'll need this)

## Deployment Steps

### Step 1: Provision Infrastructure

```bash
cd /home/maxdop1/projects/TestVMs

# Initialize Terraform (if not done already)
terraform init

# Apply configuration
terraform apply
```

This creates:
- 1x ansible-control (Ubuntu 22.04)
- 1x dc01 (Windows Server)
- 3x sql01/sql02/sql03 (Windows Server)

**Wait 2-3 minutes** for cloud-init to complete on ansible-control.

---

### Step 2: Configure Windows VMs

You have **two options** for this step:

#### Option A: Automated Bootstrap (Recommended)

```bash
# Make the script executable
chmod +x bootstrap-windows.sh

# Run the bootstrap script
./bootstrap-windows.sh
```

This script will:
- Attempt to connect to each Windows VM
- Configure static IP addresses
- Enable and configure WinRM
- Set up firewall rules

**If this works:** Skip to Step 3

**If this fails:** Use Option B below

#### Option B: Manual Configuration

If the automated bootstrap fails (likely on first run when WinRM isn't enabled):

```bash
# Generate PowerShell scripts
chmod +x generate-manual-setup.sh
./generate-manual-setup.sh
```

This creates 4 PowerShell scripts: `setup-dc01.ps1`, `setup-sql01.ps1`, etc.

**For each Windows VM:**

1. Open VM in Virtual Machine Manager (VMM)
2. Login as Administrator
3. Open PowerShell as Administrator
4. Open the corresponding `setup-*.ps1` file in a text editor on your host
5. Copy the entire contents
6. Paste into PowerShell window on the VM
7. Press Enter to execute

**Each script will:**
- Set the static IP address
- Configure DNS
- Enable WinRM for Ansible
- Configure firewall rules

---

### Step 3: Deploy Active Directory

Once all Windows VMs are configured:

```bash
# SSH to ansible-control
ssh ansible@192.168.122.5

# Update the Windows Administrator password in inventory
vim ~/lab-inventory.yml
# Change: ansible_password: CHANGEME
# To:     ansible_password: YourActualPassword

# Run the deployment script
./deploy-lab.sh
```

The `deploy-lab.sh` script will:
1. Test connectivity to all Windows VMs
2. Run the AD setup playbook on DC01
3. Install AD DS role
4. Promote DC01 to Domain Controller
5. Create domain `sqllab.local`
6. Create SQL service accounts

**This takes approximately 15-20 minutes** with automatic reboots.

---

## What Gets Automated

### Fully Automated (No Manual Steps)

- ✓ Ansible control node provisioning
- ✓ Ansible/Python/pywinrm installation
- ✓ Ansible inventory creation
- ✓ Variable files creation
- ✓ Playbook creation
- ✓ AD DS installation
- ✓ Domain Controller promotion
- ✓ DNS configuration
- ✓ Service account creation

### Semi-Automated (One-Time Manual Setup)

- ⚠ Windows VM static IP configuration (copy-paste PowerShell)
- ⚠ WinRM enablement (copy-paste PowerShell)
- ⚠ Password update in inventory file (edit one line)

### Why Not 100% Automated?

Windows VMs require initial configuration before Ansible can manage them:
- **Static IPs:** Windows doesn't support cloud-init by default
- **WinRM:** Disabled by default for security
- **Network Security:** Windows Firewall blocks remote management initially

**Future Enhancement:** You could create Windows images with WinRM pre-enabled and cloud-init support, achieving 100% automation.

---

## Complete Command Reference

### Minimal Command Set (Ideal Scenario)

```bash
# On your Ubuntu host
terraform apply                    # Provision all VMs
./bootstrap-windows.sh             # Configure Windows (if it works)
ssh ansible@192.168.122.5          # Connect to ansible-control
vim ~/lab-inventory.yml            # Update password (one line)
./deploy-lab.sh                    # Deploy AD and everything else
```

**Total commands: 5** (3 if bootstrap works perfectly)

### If Manual Windows Setup Needed

```bash
# On your Ubuntu host
terraform apply                    # Provision all VMs
./generate-manual-setup.sh         # Generate setup scripts

# Then for each VM (via VMM console):
# Copy-paste contents of setup-*.ps1 into PowerShell

# Back on host:
ssh ansible@192.168.122.5          # Connect to ansible-control
vim ~/lab-inventory.yml            # Update password
./deploy-lab.sh                    # Deploy everything
```

**Total commands: 4 + copy-paste steps**

---

## Verification Steps

### After Step 1 (Infrastructure Provisioning)

```bash
# Check all VMs are running
virsh list

# Should show:
#  ansible-control   running
#  dc01              running
#  sql01             running
#  sql02             running
#  sql03             running
```

### After Step 2 (Windows Configuration)

```bash
# From host
ssh ansible@192.168.122.5

# Test connectivity
ansible windows -m win_ping

# Should show success for all VMs
```

### After Step 3 (AD Deployment)

```bash
# From ansible-control
ansible domain_controller -m ansible.windows.win_shell -a "Get-ADDomain | Select-Object Name,Forest"

# Should show:
# Name: sqllab
# Forest: sqllab.local
```

---

## Troubleshooting

### Issue: Cannot SSH to ansible-control

**Solution:**
```bash
# Check cloud-init completion
virsh console ansible-control
# Login: ansible / ansible123 (if prompted)
cat /home/ansible/setup-complete.txt
```

### Issue: bootstrap-windows.sh fails to connect

**Cause:** WinRM not enabled yet (expected on first run)

**Solution:** Use Option B (manual PowerShell scripts)

### Issue: deploy-lab.sh says "Cannot connect to Windows VMs"

**Checklist:**
1. Did you run the Windows setup scripts?
2. Are all VMs running? (`virsh list`)
3. Can you ping the VMs? (`ping 192.168.122.10`)
4. Is the password correct in `~/lab-inventory.yml`?

**Debug:**
```bash
# From ansible-control
ansible dc01 -m win_ping -vvv
```

### Issue: AD promotion fails

**Common causes:**
- DNS not set correctly on DC01
- Hostname conflicts
- Insufficient resources

**Check:**
```bash
ansible domain_controller -m ansible.windows.win_shell -a "ipconfig /all"
ansible domain_controller -m ansible.windows.win_shell -a "hostname"
```

---

## Next Steps After AD Deployment

The lab now has a functioning Domain Controller. Next phases:

### Phase 2: Domain Join SQL Nodes

```bash
# From ansible-control
ansible-playbook ~/playbooks/02-join-domain.yml
```

### Phase 3: Create Failover Cluster

```bash
ansible-playbook ~/playbooks/03-configure-cluster.yml
```

### Phase 4: Install SQL Server

```bash
ansible-playbook ~/playbooks/04-install-sqlserver.yml
```

**Note:** Playbooks 02-04 are placeholders. You'll need to create them following the patterns in `ANSIBLE_APPROACH.md`.

---

## File Reference

### Host Scripts

| File | Purpose |
|------|---------|
| `bootstrap-windows.sh` | Automated Windows VM configuration |
| `generate-manual-setup.sh` | Generate manual PowerShell scripts |
| `setup-dc01.ps1` | Manual DC01 configuration |
| `setup-sql*.ps1` | Manual SQL node configuration |

### Ansible-Control Files (auto-created)

| File | Purpose |
|------|---------|
| `~/lab-inventory.yml` | Ansible inventory |
| `~/group_vars/all.yml` | Lab variables |
| `~/playbooks/01-setup-dc.yml` | AD setup playbook |
| `~/deploy-lab.sh` | Master orchestration script |

---

## Architecture Diagram

```
Ubuntu Host
├── Terraform
│   └── Provisions 5 VMs
├── bootstrap-windows.sh
│   └── Configures Windows VMs
└── SSH to ansible-control
    └── deploy-lab.sh
        ├── Tests connectivity
        └── Runs Ansible playbooks
            └── Installs AD on DC01

Network: 192.168.122.0/24
├── 192.168.122.5   ansible-control (Ubuntu)
├── 192.168.122.10  dc01 (Domain Controller)
├── 192.168.122.11  sql01 (SQL Server)
├── 192.168.122.12  sql02 (SQL Server)
└── 192.168.122.13  sql03 (SQL Server)
```

---

## Time Estimates

| Phase | Time |
|-------|------|
| Terraform apply | 2-5 minutes |
| Cloud-init (ansible-control) | 2-3 minutes |
| Windows configuration (manual) | 10 minutes |
| AD deployment (automated) | 15-20 minutes |
| **Total** | **~30-40 minutes** |

With practice and pre-configured images: **~10 minutes total**

---

## Summary

**Minimum manual steps required:**
1. Run `terraform apply`
2. Configure Windows VMs (copy-paste 4 PowerShell scripts, ~2 minutes each)
3. Update password in inventory (1 line edit)
4. Run `./deploy-lab.sh`

**Everything else is automated.**

The goal is to get from "nothing" to "functioning AD domain" in under 30 minutes with minimal typing.
