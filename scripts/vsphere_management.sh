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

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_bootstrap_vms

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_dnsdist_vms

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_ddi_vms

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_dhcp_vms

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_lb_vms

ansible-playbook -i inventory/ playbooks/vsphere_dnsdist.yml --tags vsphere_dnsdist_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_ddi.yml --tags vsphere_ddi_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_lb.yml --tags vsphere_lb_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_dnsdist.yml

ansible-playbook -i inventory/ playbooks/vsphere_ddi.yml

ansible-playbook -i inventory/ playbooks/vsphere_lb.yml

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_dns

ansible-playbook -i inventory/ playbooks/vsphere_dnsdist.yml --tags vsphere_dnsdist_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_ddi.yml --tags vsphere_ddi_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_lb.yml --tags vsphere_lb_vms_info

ansible-playbook -i inventory/ playbooks/pdns.yml

ansible-playbook -i inventory/ playbooks/reboot.yml
