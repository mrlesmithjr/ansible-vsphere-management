<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Role Name](#role-name)
  - [Requirements](#requirements)
    - [Software iSCSI](#software-iscsi)
  - [Role Variables](#role-variables)
  - [Dependencies](#dependencies)
  - [Example Playbook](#example-playbook)
  - [License](#license)
  - [Author Information](#author-information)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Role Name

## Requirements

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

## Role Variables

## Dependencies

## Example Playbook

## License

## Author Information
