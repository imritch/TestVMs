# Quick Start - Automated Lab Deployment

## The Absolute Minimum Commands

### Full Deployment (3 commands + manual Windows setup)

```bash
# 1. Provision VMs
terraform apply

# 2. Generate Windows setup scripts
./generate-manual-setup.sh

# 3. (Manual) For each Windows VM:
#    - Open in VMM
#    - Login as Administrator
#    - Open PowerShell as Admin
#    - Copy-paste contents of setup-<vmname>.ps1

# 4. Deploy Active Directory
ssh ansible@192.168.122.5
vim ~/lab-inventory.yml          # Change password on line 74
./deploy-lab.sh
```

---

## What This Achieves

After running the above:
- ✓ 5 VMs running (1 Ubuntu Ansible control, 4 Windows)
- ✓ Static IPs configured
- ✓ WinRM enabled for Ansible management
- ✓ DC01 promoted to Domain Controller
- ✓ Domain `sqllab.local` created
- ✓ SQL service accounts created

---

## Time Required

- **Terraform:** ~5 minutes
- **Windows setup:** ~10 minutes (copy-paste scripts)
- **AD deployment:** ~20 minutes (automated)
- **Total:** ~35 minutes

---

## Verification Commands

```bash
# Check VMs are running
virsh list

# Test Ansible connectivity
ssh ansible@192.168.122.5
ansible windows -m win_ping

# Verify AD domain
ansible domain_controller -m ansible.windows.win_shell \
  -a "Get-ADDomain | Select-Object Name"
```

---

## Next Steps

Join SQL nodes to domain:
```bash
# (From ansible-control)
ansible-playbook ~/playbooks/02-join-domain.yml
```

Create the other playbooks following `ANSIBLE_APPROACH.md`.

---

## Files Created

### On Host
- `setup-dc01.ps1` → Copy-paste into DC01
- `setup-sql01.ps1` → Copy-paste into SQL01
- `setup-sql02.ps1` → Copy-paste into SQL02
- `setup-sql03.ps1` → Copy-paste into SQL03

### On ansible-control
- `~/lab-inventory.yml` → Ansible inventory (edit password)
- `~/playbooks/01-setup-dc.yml` → AD setup playbook (auto-created)
- `~/deploy-lab.sh` → Master deployment script (auto-created)

---

## Troubleshooting

**Can't SSH to ansible-control?**
Wait 2-3 minutes for cloud-init, or check: `virsh console ansible-control`

**deploy-lab.sh fails?**
1. Check Windows VMs are running: `virsh list`
2. Verify you ran the PowerShell setup scripts on each VM
3. Confirm password is correct in `~/lab-inventory.yml`
4. Test: `ansible windows -m win_ping -vvv`

**Need more details?**
See `AUTOMATED_DEPLOYMENT.md` for comprehensive guide.
