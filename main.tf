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

# Domain Controller VM
resource "libvirt_domain" "dc01" {
  name        = "dc01"
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
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          file = {
            file = "/home/maxdop1/projects/sqlserverlab/images/dc01.qcow2"
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]
    graphics = [
      {
        vnc = {
          autoport = true
        }
      }
    ]
  }
}

# SQL Server Node 1
resource "libvirt_domain" "sql01" {
  name        = "sql01"
  memory      = 8192
  memory_unit = "MiB"
  vcpu        = 2
  type        = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "pc-q35-8.2"
  }

  devices = {
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          file = {
            file = "/home/maxdop1/projects/sqlserverlab/images/sql01.qcow2"
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]
    graphics = [
      {
        vnc = {
          autoport = true
        }
      }
    ]
  }
}

# SQL Server Node 2
resource "libvirt_domain" "sql02" {
  name        = "sql02"
  memory      = 8192
  memory_unit = "MiB"
  vcpu        = 2
  type        = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "pc-q35-8.2"
  }

  devices = {
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          file = {
            file = "/home/maxdop1/projects/sqlserverlab/images/sql02.qcow2"
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]
    graphics = [
      {
        vnc = {
          autoport = true
        }
      }
    ]
  }
}

# SQL Server Node 3
resource "libvirt_domain" "sql03" {
  name        = "sql03"
  memory      = 8192
  memory_unit = "MiB"
  vcpu        = 2
  type        = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "pc-q35-8.2"
  }

  devices = {
    disks = [
      {
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        source = {
          file = {
            file = "/home/maxdop1/projects/sqlserverlab/images/sql03.qcow2"
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
          }
        }
      }
    ]
    graphics = [
      {
        vnc = {
          autoport = true
        }
      }
    ]
  }
}





