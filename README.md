<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [ansible-vsphere-management](#ansible-vsphere-management)
  - [Requirements](#requirements)
    - [Windows 2012R2/2016 Host](#windows-2012r22016-host)
    - [Software iSCSI](#software-iscsi)
  - [Deployment Host](#deployment-host)
    - [Spinning It Up](#spinning-it-up)
  - [Bootstrap VMs](#bootstrap-vms)
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

## Role Variables

## Dependencies

## Example Playbook

## License

MIT

## Author Information

Larry Smith Jr.

-   [@mrlesmithjr](https://www.twitter.com/mrlesmithjr)
-   [EverythingShouldBeVirtual](http://www.everythingshouldbevirtual.com)
-   [mrlesmithjr.com](http://mrlesmithjr.com)
-   mrlesmithjr [at] gmail.com
