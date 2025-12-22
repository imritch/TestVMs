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
  name = "sqlhost01"
  memory = 4096
  memory_unit = "MiB"
  vcpu = 2
  type = "kvm"

  os = {
    type = "hvm"
    type_arch = "x86_64"
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
            file = "/home/maxdop1/projects/sqlserverlab/images/windows-server-2022-base.qcow2"
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





