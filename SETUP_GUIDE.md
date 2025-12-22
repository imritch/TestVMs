# Windows VM Setup Guide - Lessons Learned

## Success! 🎉

After troubleshooting, we successfully created a Windows Server 2022 VM using Terraform and libvirt.

---

## Issues Encountered and Solutions

### 1. **Graphics Console Not Available**
**Problem:** "Graphical Console not configured for guest" error in VMM.

**Root Cause:** The `graphics` configuration was missing from the VM definition.

**Solution:** Added VNC graphics configuration:
```hcl
graphics = [
  {
    vnc = {
      autoport = true
    }
  }
]
```

**Note:** The libvirt provider v0.9.1 has a bug with the nested `devices` structure. We added a lifecycle block to work around state management issues:
```hcl
lifecycle {
  ignore_changes = [devices]
}
```
*(We later removed this after fixing other issues)*

---

### 2. **Boot Failed: Not a Bootable Disk**
**Problem:** VM wouldn't boot, showing "not a bootable disk" error.

**Root Causes (Multiple):**

#### a) Wrong Disk Driver Type
- **Issue:** Disk driver was set to `raw` instead of `qcow2`
- **Impact:** VM couldn't read the qcow2 disk image properly
- **Solution:** Explicitly configured the driver:
```hcl
driver = {
  name = "qemu"
  type = "qcow2"
}
```

#### b) Incompatible Disk Bus
- **Issue:** Used `virtio` bus which requires drivers Windows doesn't have by default
- **Impact:** Windows couldn't see the disk at all
- **Solution:** Changed to SATA bus:
```hcl
target = {
  dev = "sda"
  bus = "sata"  # Changed from "virtio"
}
```

---

### 3. **Memory Error: "No physical memory available"**
**Problem:** Windows Boot Manager couldn't allocate memory.

**Root Cause:** Missing `memory_unit` parameter caused memory to default to **KiB instead of MiB**.
- Intended: 2048 MiB (2 GB)
- Actual: 2048 KiB (2 MB) 😱

**Solution:** Always specify memory_unit:
```hcl
memory = 4096
memory_unit = "MiB"  # Critical!
```

---

### 4. **Windows Stop Error 0xc0000225**
**Problem:** "Boot Configuration Data is missing or contains errors"

**Root Cause:** Machine type mismatch between original VM and new VM.

**Solution:** Match the exact machine type from the original sysprepped image:
```hcl
os = {
  type = "hvm"
  type_arch = "x86_64"
  type_machine = "pc-q35-8.2"  # Must match original!
}
```

---

## Final Working Configuration

```hcl
terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_domain" "vm1" {
  name        = "sqlhost01"
  memory      = 4096
  memory_unit = "MiB"  # IMPORTANT!
  vcpu        = 2
  type        = "kvm"

  # Match original VM's machine type
  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "pc-q35-8.2"
  }

  devices = {
    # Disk configuration
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"  # Match image format
        }
        source = {
          file = {
            file = "/home/maxdop1/projects/sqlserverlab/images/windows-server-2022-base.qcow2"
          }
        }
        target = {
          dev = "sda"
          bus = "sata"  # Windows-compatible, no drivers needed
        }
      }
    ]

    # Network configuration
    interfaces = [
      {
        model = {
          type = "virtio"  # OK for network, drivers usually available
        }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]

    # Graphics configuration
    graphics = [
      {
        vnc = {
          autoport = true
        }
      }
    ]
  }
}
```

---

## Best Practices for Creating More VMs

### 1. **Always Check the Source VM Configuration**
Before creating a new VM from a sysprepped image, inspect the original:

```bash
# Get the original VM's configuration
virsh dumpxml <original-vm-name> > original-config.xml

# Key things to match:
# - Machine type (pc-q35-x.x)
# - Disk bus type (sata/virtio/ide)
# - Memory configuration
# - Hyper-V enlightenments (if present)
```

### 2. **Memory Configuration**
```hcl
memory      = 4096      # The amount
memory_unit = "MiB"     # ALWAYS specify the unit!
```

**Units:**
- `MiB` = Mebibytes (1024-based) - Use this for GBs of RAM
- `KiB` = Kibibytes (1024-based) - Default if not specified ⚠️
- `GiB` = Gibibytes

### 3. **Disk Configuration Checklist**

✅ **Driver type must match image format:**
```hcl
driver = {
  name = "qemu"
  type = "qcow2"  # or "raw" if using raw images
}
```

✅ **Use SATA for Windows compatibility:**
```hcl
target = {
  dev = "sda"   # or sdb, sdc, etc.
  bus = "sata"  # Best for Windows without custom drivers
}
```

**Bus Type Guide:**
- `sata` - ✅ Best for Windows (native support, good performance)
- `virtio` - ⚠️ Requires VirtIO drivers (best performance if drivers available)
- `ide` - ✅ Universal compatibility (slower, legacy)

### 4. **Machine Type Matching**

When using sysprepped images, **always match the original machine type**:

```hcl
os = {
  type         = "hvm"
  type_arch    = "x86_64"
  type_machine = "pc-q35-8.2"  # Must match original!
}
```

**Why?** Windows stores hardware configuration in the registry. Changing machine types can cause boot failures.

### 5. **Graphics Configuration**

For desktop Windows or when you need console access:
```hcl
graphics = [
  {
    vnc = {
      autoport = true  # Automatically assign VNC port
    }
  }
]
```

**Alternatives:**
- `spice` - Better performance, but had bugs with this provider version
- `vnc` - Reliable, works everywhere

### 6. **Use Separate Disk Images Per VM**

**Don't** reuse the same qcow2 file for multiple VMs!

**Option A - Copy the disk manually:**
```bash
cp base-image.qcow2 vm1.qcow2
cp base-image.qcow2 vm2.qcow2
```

**Option B - Use libvirt volumes (better):**
```hcl
resource "libvirt_volume" "vm1_disk" {
  name             = "vm1.qcow2"
  base_volume_name = "windows-server-2022-base.qcow2"
  pool             = "default"
}
```

---

## Template for Additional VMs

To create more VMs for your SQL cluster, use this pattern:

```hcl
# AD Domain Controller
resource "libvirt_domain" "ad_dc" {
  name        = "ad-dc-01"
  memory      = 4096
  memory_unit = "MiB"
  vcpu        = 2
  type        = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "pc-q35-8.2"
  }

  devices = {
    disks = [{
      driver = { name = "qemu", type = "qcow2" }
      source = { file = { file = "/var/lib/libvirt/images/ad-dc-01.qcow2" } }
      target = { dev = "sda", bus = "sata" }
    }]

    interfaces = [{
      model  = { type = "virtio" }
      source = { network = { network = "default" } }
    }]

    graphics = [{
      vnc = { autoport = true }
    }]
  }
}

# SQL Server Node 1
resource "libvirt_domain" "sql01" {
  name        = "sql-node-01"
  memory      = 8192  # SQL needs more RAM
  memory_unit = "MiB"
  vcpu        = 4
  type        = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "pc-q35-8.2"
  }

  devices = {
    disks = [{
      driver = { name = "qemu", type = "qcow2" }
      source = { file = { file = "/var/lib/libvirt/images/sql-node-01.qcow2" } }
      target = { dev = "sda", bus = "sata" }
    }]

    interfaces = [{
      model  = { type = "virtio" }
      source = { network = { network = "default" } }
    }]

    graphics = [{
      vnc = { autoport = true }
    }]
  }
}

# Repeat for sql-node-02, sql-node-03, etc.
```

---

## Known Issues with libvirt Provider v0.9.1

1. **Nested `devices` structure bugs:**
   - Graphics state management issues
   - Some attributes cause "inconsistent result" errors
   - Workaround: Use lifecycle ignore_changes if needed

2. **Feature configuration limitations:**
   - Cannot configure Hyper-V enlightenments through Terraform
   - Must use virsh to manually add if needed
   - Consider using later provider versions

3. **XML customization not available:**
   - The `xml` block isn't supported in this version
   - For advanced features, consider manual XML editing with virsh

---

## Troubleshooting Checklist

If a VM won't boot:

- [ ] Is `memory_unit = "MiB"` specified?
- [ ] Does disk driver type match image format? (qcow2/raw)
- [ ] Is disk bus set to `sata` for Windows?
- [ ] Does `type_machine` match the original sysprepped VM?
- [ ] Is graphics configured for console access?
- [ ] Does the qcow2 file exist and have correct permissions?
- [ ] Check `virsh dumpxml <vm-name>` to verify actual libvirt config

---

## Next Steps for Your SQL Cluster Lab

1. **Prepare disk images:**
   ```bash
   cd /var/lib/libvirt/images
   sudo cp windows-server-2022-base.qcow2 ad-dc-01.qcow2
   sudo cp windows-server-2022-base.qcow2 sql-node-01.qcow2
   sudo cp windows-server-2022-base.qcow2 sql-node-02.qcow2
   sudo cp windows-server-2022-base.qcow2 sql-node-03.qcow2
   ```

2. **Create multiple VM resources** using the template above

3. **Consider adding:**
   - Additional networks for cluster heartbeat
   - Extra disks for SQL data/logs
   - Static IP assignments
   - Shared storage for cluster

4. **Post-provisioning:**
   - Use Ansible/PowerShell DSC for Windows configuration
   - Automate domain join
   - SQL Server installation
   - Failover cluster setup

---

## Useful Commands

```bash
# List all VMs
virsh list --all

# Start a VM
virsh start <vm-name>

# Stop a VM
virsh destroy <vm-name>

# View VM console
virt-viewer <vm-name>

# Get VM info
virsh dominfo <vm-name>

# Check disk configuration
virsh dumpxml <vm-name> | grep -A 8 "disk type"

# Check memory
virsh dominfo <vm-name> | grep -i memory

# Connect to VNC console
virsh vncdisplay <vm-name>
```

---

## Conclusion

Your Infrastructure as Code approach is **absolutely correct**! The challenges were due to:
- Provider bugs and limitations
- Specific Windows requirements
- Hardware configuration matching needs

Now that you have a working template, creating the rest of your AD + SQL cluster will be much smoother!

**Good luck with your SQL Server Availability Group lab!** 🚀
