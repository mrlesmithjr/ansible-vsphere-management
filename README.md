<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [ansible-vsphere-management](#ansible-vsphere-management)
  - [Requirements](#requirements)
    - [Windows 2012R2/2016 Host](#windows-2012r22016-host)
    - [Software iSCSI](#software-iscsi)
  - [Deployment Host](#deployment-host)
    - [Spinning It Up](#spinning-it-up)
  - [Environment Deployment](#environment-deployment)
  - [Bootstrap VMs](#bootstrap-vms)
  - [DNSDist VMs](#dnsdist-vms)
  - [DDI VMs](#ddi-vms)
    - [Autostart DDI VMs](#autostart-ddi-vms)
    - [Defining DDI VMs](#defining-ddi-vms)
    - [Defining DNS Records](#defining-dns-records)
    - [Future DDI Functionality](#future-ddi-functionality)
  - [Role Variables](#role-variables)
  - [Dependencies](#dependencies)
  - [Example Playbook](#example-playbook)
  - [License](#license)
  - [Author Information](#author-information)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# ansible-vsphere-management

The purpose of this repo is to provide the automation of `vSphere` environments
using `Ansible`. Most of the tasks in this repo will be written initially as
`win_shell` tasks which require `Powershell` and `PowerCLI`. There are many
`Ansible` modules specific to [VMware Cloud Modules](http://docs.ansible.com/ansible/latest/list_of_cloud_modules.html#vmware)
however, the majority of them are lacking functionality or simply do not work. My
goal with this is to have the ability to build from scratch a `vSphere` environment
with many different options to define the infrastructure. Another focus on using
the `win_shell` module I wanted to ensure idempotency on tasks in order to not
just throw a bunch of `Powershell` and `PowerCLI` commands around. But rather
build the logic in to only do something when something truly needs to be done. The
issue currently with this is that some if not most of the `win_shell` tasks show
as changes however, if you watch your `vSphere` host tasks you will not see things
change unless something was required to change. This repo will be continually a
work in progress so do not expect perfection.

> Note: As this progresses you will notice that the focus around strict policy
> enforcement is growing. The reason behind that is because the goal should be
> that mostly everything in the environment should be defined as code. If manual
> changes occur outside of the code this can lead to an unmanaged environment.
> By enforcing strict policies, we can ensure that the environment is stable.
> This is something that should exist but unfortunately most environments do not
> follow this. Which means that this strict policy enforcement may not be suitable
> for each environment. Over time the ability to enable/disable enforcement will
> grow allowing for more flexibility.

## Requirements

### Windows 2012R2/2016 Host

Because most of the tasks in this repo use the `win_shell` module a `Windows 2012R2/2016`
host is required. The plus side to this is that I have already created the `Ansible`
roles to properly prep this host to get up and running quickly as well as a playbook.

-   [ansible-windows-powercli](https://github.com/mrlesmithjr/ansible-windows-powercli)
-   [ansible-windows-remote-desktop](https://github.com/mrlesmithjr/ansible-windows-remote-desktop)

```yaml
---
- hosts: powercli_host
  roles:
    - role: ansible-windows-powercli
    - role: ansible-windows-remote-desktop
    - role: ansible-vsphere-management
      when: inventory_hostname == groups['powercli_host'][0]
  tasks:
    - name: Install NET-Framework-Core
      win_feature:
        name: NET-Framework-Core
        state: present

    - name: Rebooting Server
      win_reboot:
        shutdown_timeout: 3600
        reboot_timeout: 3600
      when: ansible_reboot_pending

    - name: Install vmwarevsphereclient
      win_chocolatey:
        name: vmwarevsphereclient
        state: present
```

### Software iSCSI

Because we iterate over `groups[vsphere_management_hosts_group]` to capture
`hostvars` variables. The following variable `vsphere_enable_software_iscsi`
needs to be defined as one of the examples below.

> Note: By default defining this variable only in this roles `defaults/main.yml`
> does not have any effect on whether the iSCSI Software Adapter is enabled or
> not.

`host_vars/esxi-01/iscsi.yml`

```yaml
---
vsphere_enable_software_iscsi: true
```

`group_vars/vsphere_hosts/iscsi.yml`

```yaml
---
vsphere_enable_software_iscsi: true
```

## Deployment Host

Included is a `Vagrant` environment in which you can use for your deployments. It
is a working `Windows 2016` server which will be autoprovisioned on bootup. The
`Vagrantfile` is set to bring this up in headless mode but you will be able to
remote desktop to the server. The reason this is brought up in headless mode is
because it will allow the `Vagrant` environment to be spun up on a remote system.
This will provide the ability to still run `Powershell` and `PowerCLI` scripts
against it.

### Spinning It Up

```bash
cd /Vagrant
vagrant up
```

After all provisioning is complete use remote desktop and connect to `192.168.250.10`
and on the desktop double click `extend-trial.cmd` to extend the trial license,
otherwise the server will shutdown every 30 minutes or so. And then reboot.

## Environment Deployment

Currently there is a script which will provision everything after the [Deployment Host](#deployment_host)
is deployed. The script is [vsphere_management.sh](scripts/vsphere_management.sh).
This script will likely include the [Deployment Host](#deployment_host) deployment
at some point as well seeing as this deployment initially includes the Windows
Vagrant box to do all of the deployments.

## Bootstrap VMs

When spinning up a new environment you may want to spin up some initial VMs for
various functions to bootstrap your environment. This will be a work in progress
until the process becomes more sreamlined. As of right now I am using an `Ubuntu`
based `OVF` template which is stored on my `Deployment Host` which is used to
deploy these bootstrap vms.

> Note: The `Ubuntu` based `OVF` template is **NOT** included in this repo. I am
> still evaluating a solution around this. My instinct at the moment is to use
> `Packer` to build the `OVF` but not 100% sure at this point. This seems like a
> viable solution as I could include the build template and the scripting. But time
> will tell.

## DNSDist VMs

The option to spin up [PowerDNS DNSDist](https://dnsdist.org/) is available. These
VMs provide a set of DNS servers to use in the environment which will frontend
any and all DNS servers inside/outside this environment. DNSDist provides true DNS
load balancing and rule based DNS distribution. This is especially beneficial in
those environments where outside resources need to be accessed which already have
separate DNS servers and forwarding is not warranted on the DDI VMs. In addition
in environments where Active Directory is present. DNSDist can forward those
requests appropriately. In this project we will be adding Samba based Active
Directory functionality to alleviate the need for Windows based Active Directory.
The option to use Windows based Active Directory will eventually added at some
point. The additional benefit to using DNSDist is that you can freely change out
DNS servers on the backend without impacting clients and etc.

## DDI VMs

The option to spin up a multi-node DDI cluster is available.
[DHCP](https://www.isc.org/downloads/dhcp/), [DNS](https://www.powerdns.com/),
[IPAM](https://phpipam.net/), and NTP functionality exists on these VMs if deployed.
The VMs by default should be assigned an IP address in order to bootstrap the environment
for IP services where these constructs do not exist. The idea is that you would
be deploying from scratch an environment which needs this functionality provided
in an automated fashion. When these VMs spin up everything is automated from
beginning to end including DNS record registrations. Dynamic DNS is also enabled
in order to auto register DHCP clients.

> Note: Currently all of these services run on the DDI nodes and may eventually
> be separated out.
>
> Note: The `Ubuntu` based `OVF` template is **NOT** included in this repo. I am
> still evaluating a solution around this. My instinct at the moment is to use
> `Packer` to build the `OVF` but not 100% sure at this point. This seems like a
> viable solution as I could include the build template and the scripting. But time
> will tell.

### Autostart DDI VMs

The DDI VMs are set to autostart on host bootup with priories defined. This will
likely change a bit once vCenter is in place.

### Defining DDI VMs

Below is an example of the current DDI VM definitions in `inventory/group_vars/all/vsphere_ddi.yml`:

```yaml
---
# These define the IP addresses for the DDI VMs
vsphere_ddi_vm_ips:
  - 10.0.102.10
  - 10.0.102.11
  - 10.0.102.12

vsphere_ddi_vms_inventory_file: ../inventory/vsphere_ddi_vms.inv

vsphere_ddi_vms:
  - vm_name: "ddi_00.{{ vsphere_pri_domain_name }}"
    cpus: 1
    deploy: true
    datastore: Datastore_1
    gateway: 10.0.102.1
    ip: "{{ vsphere_ddi_vm_ips[0] }}"
    memory_mb: 1024
    netmask: 255.255.255.0
    netmask_cidr: 24
    network_name: VSS-VLAN-102
    vapp_source_path: C:\vagrant\vApps\ubuntu_16.04_template.ovf
  - vm_name: "ddi_01.{{ vsphere_pri_domain_name }}"
    cpus: 1
    deploy: true
    datastore: Datastore_1
    gateway: 10.0.102.1
    ip: "{{ vsphere_ddi_vm_ips[1] }}"
    memory_mb: 1024
    netmask: 255.255.255.0
    netmask_cidr: 24
    network_name: VSS-VLAN-102
    vapp_source_path: C:\vagrant\vApps\ubuntu_16.04_template.ovf
  - vm_name: "ddi_02.{{ vsphere_pri_domain_name }}"
    cpus: 1
    deploy: true
    datastore: Datastore_1
    gateway: 10.0.102.1
    ip: "{{ vsphere_ddi_vm_ips[2] }}"
    memory_mb: 1024
    netmask: 255.255.255.0
    netmask_cidr: 24
    network_name: VSS-VLAN-102
    vapp_source_path: C:\vagrant\vApps\ubuntu_16.04_template.ovf
```

### Defining DNS Records

Below is an example of the current DNS record definitions in `inventory/group_vars/all/pdns.yml`:

> NOTE: When creating a `CNAME` record type take not of the `.` at the end of the
> `content` variable. This is **REQUIRED** to ensure Canonical naming standards
> otherwise the record creation will fail.

```yaml
pdns_records:
  - hostname: lb
    content: "{{ vsphere_lb_vips[0] }}"
    domain: "{{ vsphere_pri_domain_name }}"
    ip: "{{ vsphere_lb_vips[0] }}"
    type: A
  - hostname: db
    content: "lb.{{ vsphere_pri_domain_name }}."
    domain: "{{ vsphere_pri_domain_name }}"
    ip: "{{ vsphere_lb_vips[0] }}"
    type: CNAME
  - hostname: dns_00
    content: "dnsdist_00.{{ vsphere_pri_domain_name }}."
    domain: "{{ vsphere_pri_domain_name }}"
    ip: "{{ vsphere_dnsdist_vm_ips[0] }}"
    type: CNAME
  - hostname: dns_01
    content: "dnsdist_01.{{ vsphere_pri_domain_name }}."
    domain: "{{ vsphere_pri_domain_name }}"
    ip: "{{ vsphere_dnsdist_vm_ips[1] }}"
    type: CNAME
  - hostname: ipam
    content: "lb.{{ vsphere_pri_domain_name }}."
    domain: "{{ vsphere_pri_domain_name }}"
    ip: "{{ vsphere_lb_vips[0] }}"
    type: CNAME
  - hostname: nas01
    content: 10.0.101.50
    domain: "{{ vsphere_pri_domain_name }}"
    ip: 10.0.101.50
    type: A
  - hostname: nas02
    content: 10.0.101.51
    domain: "{{ vsphere_pri_domain_name }}"
    ip: 10.0.101.51
    type: A
  - hostname: ntp_00
    content: "ddi_00.{{ vsphere_pri_domain_name }}."
    domain: "{{ vsphere_pri_domain_name }}"
    ip: "{{ vsphere_ddi_vm_ips[0] }}"
    type: CNAME
  - hostname: ntp_01
    content: "ddi_01.{{ vsphere_pri_domain_name }}."
    domain: "{{ vsphere_pri_domain_name }}"
    ip: "{{ vsphere_ddi_vm_ips[1] }}"
    type: CNAME
  - hostname: ntp_02
    content: "ddi_02.{{ vsphere_pri_domain_name }}."
    domain: "{{ vsphere_pri_domain_name }}"
    ip: "{{ vsphere_ddi_vm_ips[2] }}"
    type: CNAME
  - hostname: pdns_api
    content: "lb.{{ vsphere_pri_domain_name }}."
    domain: "{{ vsphere_pri_domain_name }}"
    ip: "{{ vsphere_lb_vips[0] }}"
    type: CNAME
```

### Future DDI Functionality

In the future the option to use `Windows` DNS and DHCP may be an option but not
in the current state.

## Role Variables

> Note: Update this once more complete. Too many changes to keep accurate.

[defaults/main.yml](defaults/main.yml)

## Dependencies

In order to properly deploy a single vSphere ESXi host should be stood up and have
at least a single NIC with an IP assigned for the management network. Everything
else will be deployed.

## Example Playbook

## License

MIT

## Author Information

Larry Smith Jr.

-   [@mrlesmithjr](https://www.twitter.com/mrlesmithjr)
-   [EverythingShouldBeVirtual](http://www.everythingshouldbevirtual.com)
-   [mrlesmithjr.com](http://mrlesmithjr.com)
-   mrlesmithjr [at] gmail.com
