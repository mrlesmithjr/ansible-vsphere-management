#! /usr/bin/env bash

LOG_DIR=logs

if [ ! -d $LOG_DIR ]; then
  mkdir $LOG_DIR
else [ -d $LOG_DIR ]
  echo "$LOG_DIR already exists"
fi

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_management

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_bootstrap_vms

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_powerdns_vms

ansible-playbook -i inventory/ playbooks/vsphere_powerdns.yml --tags vsphere_powerdns_vms_info

ansible-playbook -i inventory/ playbooks/vsphere_powerdns.yml

ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_dns

ansible-playbook -i inventory/ playbooks/vsphere_powerdns.yml --tags vsphere_powerdns_vms_info

ansible-playbook -i inventory/ playbooks/pdns.yml
