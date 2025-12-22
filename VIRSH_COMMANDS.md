# Virsh Command Reference Guide

## What is virsh?

**virsh** (virtualization shell) is the command-line interface for managing virtual machines through libvirt. It communicates with the libvirt API to control KVM/QEMU virtual machines.

```
User → virsh → libvirt API → QEMU/KVM → Virtual Machines
```

---

## VM Status and Listing

### List all VMs
```bash
# List running VMs
virsh list

# List all VMs (running and stopped)
virsh list --all

# List VMs with more details
virsh list --all --title
```

### Get detailed VM information
```bash
# Basic VM information
virsh dominfo dc01

# Show specific fields
virsh dominfo dc01 | grep -E "CPU|memory|State"

# Get VM ID
virsh domid dc01

# Get VM UUID
virsh domuuid dc01
```

### Check VM state
```bash
# Quick state check
virsh domstate dc01

# Check if VM is running
virsh list --state-running

# Check if VM is shut off
virsh list --state-shutoff
```

---

## VM Lifecycle Management

### Starting VMs
```bash
# Start a single VM
virsh start dc01

# Start multiple VMs
virsh start dc01 && virsh start sql01 && virsh start sql02 && virsh start sql03

# Start VM and connect to console
virsh start dc01 --console
```

### Stopping VMs
```bash
# Graceful shutdown (sends ACPI shutdown signal)
virsh shutdown dc01

# Shutdown multiple VMs
virsh shutdown dc01 sql01 sql02 sql03

# Force shutdown (like pulling the power plug)
virsh destroy dc01

# Destroy all running VMs (use with caution!)
virsh list --name | xargs -I {} virsh destroy {}
```

### Rebooting VMs
```bash
# Graceful reboot
virsh reboot dc01

# Force reboot
virsh reset dc01
```

### Suspending and Resuming
```bash
# Pause/suspend VM (freezes state)
virsh suspend dc01

# Resume suspended VM
virsh resume dc01

# Save VM state to disk (hibernation)
virsh save dc01 /var/lib/libvirt/save/dc01.save

# Restore saved VM
virsh restore /var/lib/libvirt/save/dc01.save
```

---

## VM Configuration and Details

### View VM XML configuration
```bash
# Show complete XML configuration
virsh dumpxml dc01

# Show XML with specific sections
virsh dumpxml dc01 | grep -A 10 "<os>"
virsh dumpxml dc01 | grep -A 8 "<disk"
virsh dumpxml dc01 | grep -A 5 "<interface"
virsh dumpxml dc01 | grep -A 3 "<graphics"

# Save XML to file
virsh dumpxml dc01 > dc01-config.xml
```

### Edit VM configuration
```bash
# Edit VM config (opens in editor)
virsh edit dc01

# Note: VM must be shut down for most changes
```

### Resource Information
```bash
# CPU information
virsh vcpuinfo dc01

# CPU count
virsh vcpucount dc01

# Memory usage
virsh dommemstat dc01

# Set memory (while running - only works if supported)
virsh setmem dc01 4096M

# Set max memory (requires VM shutdown)
virsh setmaxmem dc01 8192M --config

# Set vCPU count (requires VM shutdown)
virsh setvcpus dc01 4 --config
```

---

## Disk and Storage Management

### List disks
```bash
# Show disk devices for a VM
virsh domblklist dc01

# Show disk info with details
virsh domblklist dc01 --details

# Get block device stats
virsh domblkstat dc01 sda
```

### Manage disk images
```bash
# Show disk information
virsh domblkinfo dc01 sda

# List all storage pools
virsh pool-list --all

# List volumes in a pool
virsh vol-list default

# Get volume info
virsh vol-info --pool default dc01.qcow2

# Create new volume
virsh vol-create-as default sql04.qcow2 50G --format qcow2
```

### Attach/Detach disks
```bash
# Attach a disk (temporary - until reboot)
virsh attach-disk dc01 /path/to/disk.qcow2 sdb --cache none

# Attach permanently
virsh attach-disk dc01 /path/to/disk.qcow2 sdb --cache none --config

# Detach disk
virsh detach-disk dc01 sdb
```

---

## Network Management

### List network interfaces
```bash
# Show network interfaces for a VM
virsh domiflist dc01

# Show interface stats
virsh domifstat dc01 vnet0

# Get MAC address
virsh domiflist dc01 | grep -i virtio
```

### Network information
```bash
# List all networks
virsh net-list --all

# Show network details
virsh net-info default

# Show network DHCP leases
virsh net-dhcp-leases default

# Get IP addresses (if guest agent installed)
virsh domifaddr dc01
```

### Manage networks
```bash
# Start network
virsh net-start default

# Stop network
virsh net-destroy default

# Auto-start network on host boot
virsh net-autostart default

# View network XML
virsh net-dumpxml default
```

---

## Console Access

### Connect to VM console
```bash
# Connect to graphical console (VNC/Spice)
virt-viewer dc01

# Or use VNC directly
virsh vncdisplay dc01
# Then connect with: vncviewer 127.0.0.1:0

# Connect to serial console (text mode)
virsh console dc01

# Note: To exit console, press Ctrl + ]
```

---

## Snapshots (Very useful for labs!)

### Create snapshots
```bash
# Create snapshot
virsh snapshot-create-as dc01 snapshot1 "Before AD installation"

# Create snapshot with description
virsh snapshot-create-as dc01 clean-install "Fresh Windows install before any config"

# Create snapshot (VM must be shut off for consistency)
virsh shutdown dc01
virsh snapshot-create-as dc01 baseline "Baseline configuration"
```

### List and manage snapshots
```bash
# List all snapshots
virsh snapshot-list dc01

# Show snapshot details
virsh snapshot-info dc01 snapshot1

# Show current snapshot
virsh snapshot-current dc01
```

### Restore snapshots
```bash
# Revert to snapshot
virsh snapshot-revert dc01 snapshot1

# Revert and start VM
virsh snapshot-revert dc01 snapshot1 --running
```

### Delete snapshots
```bash
# Delete specific snapshot
virsh snapshot-delete dc01 snapshot1

# Delete all snapshots
virsh snapshot-list dc01 --name | xargs -I {} virsh snapshot-delete dc01 {}
```

---

## Cloning VMs

### Clone a VM
```bash
# Clone VM (VM must be shut off)
virt-clone --original dc01 --name dc02 --auto-clone

# Clone with specific disk location
virt-clone --original dc01 --name dc02 \
  --file /var/lib/libvirt/images/dc02.qcow2
```

---

## VM Deletion and Cleanup

### Remove a VM
```bash
# Undefine (remove) VM definition (keeps disks)
virsh undefine dc01

# Undefine and remove snapshots
virsh undefine dc01 --snapshots-metadata

# Undefine and remove all storage
virsh undefine dc01 --remove-all-storage

# Complete cleanup (stop, undefine, remove storage)
virsh destroy dc01
virsh undefine dc01 --remove-all-storage
```

---

## Autostart Configuration

### Set VM to start on host boot
```bash
# Enable autostart
virsh autostart dc01

# Disable autostart
virsh autostart --disable dc01

# Check autostart status
virsh dominfo dc01 | grep Autostart
```

---

## Performance and Monitoring

### CPU and Memory Stats
```bash
# Show CPU statistics
virsh cpu-stats dc01

# Show memory statistics
virsh dommemstat dc01

# Show all domain statistics
virsh domstats dc01

# Continuous monitoring (like top for VMs)
virt-top
```

### I/O Statistics
```bash
# Block device stats
virsh domblkstat dc01 sda

# Network interface stats
virsh domifstat dc01 vnet0

# Complete I/O stats
virsh domstats dc01 --block --interface
```

---

## Troubleshooting Commands

### Check VM configuration issues
```bash
# Validate XML configuration
virsh dumpxml dc01 > dc01.xml
virsh define dc01.xml  # Will show errors if invalid

# Check VM capabilities
virsh capabilities

# Show host information
virsh nodeinfo

# Show host free memory
virsh freecell
```

### View libvirt logs
```bash
# System logs
journalctl -u libvirtd

# VM-specific logs
tail -f /var/log/libvirt/qemu/dc01.log

# Real-time monitoring
watch -n 1 'virsh list && virsh domstats --cpu-total --balloon'
```

### Force unlock a VM
```bash
# If VM is stuck
virsh destroy dc01
virsh undefine dc01
virsh define dc01.xml
```

---

## Bulk Operations

### Start all VMs
```bash
# Start all shut-off VMs
virsh list --state-shutoff --name | xargs -I {} virsh start {}

# Start specific VMs
for vm in dc01 sql01 sql02 sql03; do
  virsh start $vm
done
```

### Stop all VMs
```bash
# Graceful shutdown all running VMs
virsh list --name | xargs -I {} virsh shutdown {}

# Force destroy all running VMs (emergency)
virsh list --name | xargs -I {} virsh destroy {}
```

### Get status of all VMs
```bash
# Simple list
virsh list --all

# Detailed status
for vm in dc01 sql01 sql02 sql03; do
  echo "=== $vm ==="
  virsh dominfo $vm | grep -E "State|CPU|memory"
  echo ""
done
```

---

## Quick Reference: Common Tasks

### Check if all lab VMs are running
```bash
virsh list | grep -E "dc01|sql0"
```

### Get IP addresses of all VMs (requires guest agent)
```bash
for vm in dc01 sql01 sql02 sql03; do
  echo "$vm: $(virsh domifaddr $vm)"
done
```

### Quick resource summary
```bash
echo "=== VM Resources ==="
for vm in dc01 sql01 sql02 sql03; do
  printf "%-10s: " $vm
  virsh dominfo $vm | grep "CPU(s)" | awk '{print $2 "vCPU"}'
  printf "%-10s  " ""
  virsh dominfo $vm | grep "Max memory" | awk '{print $3/1024 "MB"}'
done
```

### Create baseline snapshots for all VMs
```bash
# Shutdown all VMs
for vm in dc01 sql01 sql02 sql03; do virsh shutdown $vm; done

# Wait for shutdown
sleep 10

# Create snapshots
for vm in dc01 sql01 sql02 sql03; do
  virsh snapshot-create-as $vm baseline "Clean install before configuration"
done

# Start all VMs
for vm in dc01 sql01 sql02 sql03; do virsh start $vm; done
```

### Restore all VMs to baseline
```bash
for vm in dc01 sql01 sql02 sql03; do
  virsh destroy $vm
  virsh snapshot-revert $vm baseline
  virsh start $vm
done
```

---

## Useful One-Liners

```bash
# Count running VMs
virsh list | grep running | wc -l

# Total memory allocated to running VMs
virsh list --name | xargs -I {} virsh dominfo {} | grep "Max memory" | awk '{sum+=$3} END {print sum/1024/1024 " GB"}'

# Find VM by disk path
virsh list --all --name | xargs -I {} sh -c 'virsh domblklist {} | grep -q "dc01.qcow2" && echo {}'

# Show VMs with autostart enabled
virsh list --all --autostart

# Compact qcow2 disk images (reclaim space)
for vm in dc01 sql01 sql02 sql03; do
  virsh shutdown $vm
done
sleep 20
cd /home/maxdop1/projects/sqlserverlab/images/
for img in dc01.qcow2 sql01.qcow2 sql02.qcow2 sql03.qcow2; do
  qemu-img convert -O qcow2 $img ${img}.tmp
  mv ${img}.tmp $img
done
```

---

## Integration with Terraform

### Check Terraform-managed VMs
```bash
# List VMs created by Terraform
terraform show | grep "name"

# Compare Terraform state with actual VMs
virsh list --all
terraform state list
```

### After Terraform changes
```bash
# Terraform recreated VM - may need to restart
terraform apply
virsh list --all
virsh start <vm-name>
```

---

## Best Practices

1. **Always shutdown VMs before taking snapshots** for data consistency
2. **Use `shutdown` instead of `destroy`** when possible for clean shutdown
3. **Take snapshots before major changes** (AD installation, SQL installation, etc.)
4. **Monitor disk space** - snapshots and VMs consume significant space
5. **Document your snapshots** with meaningful names and descriptions
6. **Regular cleanup** - remove unused snapshots to save space
7. **Use autostart carefully** - only for critical VMs (like DC01)

---

## Additional Tools

### virt-manager (GUI)
```bash
# Launch Virtual Machine Manager
virt-manager
```

### virt-viewer (Console Viewer)
```bash
# Connect to VM console
virt-viewer dc01
```

### virt-top (Performance Monitor)
```bash
# Install if needed
sudo apt install virt-top

# Monitor all VMs
virt-top
```

### virt-install (Create VMs from CLI)
```bash
# Example: Create new VM from ISO
virt-install \
  --name test-vm \
  --memory 2048 \
  --vcpus 2 \
  --disk size=20 \
  --cdrom /path/to/windows.iso \
  --network network=default
```

---

## Resources

- [libvirt Documentation](https://libvirt.org/docs.html)
- [virsh Command Reference](https://libvirt.org/manpages/virsh.html)
- [KVM Management Tools](https://www.linux-kvm.org/page/Management_Tools)

---

## Quick Start Commands for This Lab

```bash
# Start lab environment
virsh start dc01 sql01 sql02 sql03

# Check all VMs are running
virsh list

# Stop lab environment
virsh shutdown dc01 sql01 sql02 sql03

# Create baseline snapshot (before AD/SQL config)
for vm in dc01 sql01 sql02 sql03; do
  virsh snapshot-create-as $vm pre-config "Before AD and SQL configuration"
done

# Restore to baseline
for vm in dc01 sql01 sql02 sql03; do
  virsh snapshot-revert $vm pre-config
done

# Clean teardown
terraform destroy -auto-approve
```

---

**Pro Tip:** Create bash aliases for common operations:

```bash
# Add to ~/.bashrc
alias lab-start='virsh start dc01 sql01 sql02 sql03'
alias lab-stop='virsh shutdown dc01 sql01 sql02 sql03'
alias lab-status='virsh list | grep -E "dc01|sql0"'
alias lab-destroy='virsh destroy dc01 sql01 sql02 sql03'

# Reload
source ~/.bashrc
```
