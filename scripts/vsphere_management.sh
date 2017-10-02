#! /usr/bin/env bash

# Stop script on error in order to troubleshoot issues
set -e

LOG_DIR=logs
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")


if [ ! -d $LOG_DIR ]; then
  mkdir $LOG_DIR
else [ -d $LOG_DIR ]
  echo "$LOG_DIR already exists"
fi

if [ -f $LOG_DIR/ansible.log ]; then
  mv $LOG_DIR/ansible.log $LOG_DIR/ansible.log.$timestamp
fi

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_management

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_samba_vms

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_bootstrap_vms

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_dnsdist_vms

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_ddi_vms

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_dhcp_vms

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_lb_vms

ansible-playbook -i inventory/ playbooks/vsphere_dnsdist.yml --tags vsphere_dnsdist_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_samba.yml --tags vsphere_samba_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_ddi.yml --tags vsphere_ddi_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_lb.yml --tags vsphere_lb_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_dnsdist.yml

# This phase does not install Samba or build domain...
ansible-playbook -i inventory/ playbooks/vsphere_samba.yml --tags samba_phase_1

ansible-playbook -i inventory/ playbooks/vsphere_ddi.yml

ansible-playbook -i inventory/ playbooks/vsphere_lb.yml

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_dns

ansible-playbook -i inventory/ playbooks/vsphere_dnsdist.yml --tags vsphere_dnsdist_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_samba.yml --tags vsphere_samba_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_ddi.yml --tags vsphere_ddi_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_lb.yml --tags vsphere_lb_vms_info

ansible-playbook -i inventory/ playbooks/pdns.yml

ansible-playbook -i inventory/ playbooks/reboot.yml --tags post_deployment_reboot

ansible-playbook -i inventory/ playbooks/ssh_key_distribution.yml

ansible-playbook -i inventory/ playbooks/vsphere_samba.yml --tags vsphere_samba_vms_info

# This phase will actually install Samba and build domain.
# This needs to occur after reboot to ensure interfaces, dns, and everything
# else in environment is up and functional.
ansible-playbook -i inventory/ playbooks/vsphere_samba.yml --tags samba_phase_2

# We need to reboot the Samba hosts after building AD to ensure everything is up clean and working
ansible-playbook -i inventory/ playbooks/reboot.yml --tags post_samba_deployment_reboot

