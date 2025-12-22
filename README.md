# Windows Server 2022 VM Lab - Terraform + Libvirt

Infrastructure as Code for creating Windows Server 2022 VMs using Terraform and libvirt on Ubuntu.

## Purpose

This project provisions Windows Server VMs for a lab environment featuring:
- Active Directory Domain Controller
- SQL Server Failover Cluster (3+ nodes)
- SQL Server Availability Groups

## Prerequisites

- Ubuntu Linux with KVM/libvirt installed
- Terraform installed
- libvirt provider v0.9.1+
- Windows Server 2022 base image (sysprepped)

## Quick Start

1. Prepare your base Windows Server 2022 qcow2 image
2. Update paths in `main.tf` to point to your base image
3. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Current Configuration

- **VM Name:** sqlhost01
- **Memory:** 4096 MiB
- **vCPU:** 2
- **Disk:** SATA (Windows-compatible)
- **Network:** Default libvirt network
- **Graphics:** VNC

## Important Notes

See [SETUP_GUIDE.md](SETUP_GUIDE.md) for:
- Complete troubleshooting steps
- Lessons learned
- Best practices for creating additional VMs
- Known issues and workarounds

## Files

- `main.tf` - Main Terraform configuration
- `vm-template.tf.example` - Template for creating additional VMs
- `SETUP_GUIDE.md` - Comprehensive setup and troubleshooting guide

## Creating Additional VMs

See `vm-template.tf.example` for a ready-to-use template.

## License

Personal lab project
