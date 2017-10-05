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

####
## Beginning of vSphere functions
####
function vsphere_ad_domain()
{
  ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_management --tags vsphere_ad_domain
}

function vsphere_management()
{
  ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_management
}

function vsphere_vms()
{
  ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_samba_vms
  ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_bootstrap_vms
  ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_dnsdist_vms
  ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_ddi_vms
  ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_dhcp_vms
  ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_lb_vms
}

function vsphere_vms_info()
{
  ansible-playbook -i inventory/ playbooks/vsphere_dnsdist.yml --tags vsphere_dnsdist_vms_info
  ansible-playbook -i inventory/ playbooks/vsphere_samba.yml --tags vsphere_samba_vms_info
  ansible-playbook -i inventory/ playbooks/vsphere_ddi.yml --tags vsphere_ddi_vms_info
  ansible-playbook -i inventory/ playbooks/vsphere_lb.yml --tags vsphere_lb_vms_info
}

function vsphere_ddi()
{
  ansible-playbook -i inventory/ playbooks/vsphere_ddi.yml
}

function vsphere_dns()
{
  ansible-playbook -i inventory/ playbooks/vsphere_management.yml --tags vsphere_dns
}

function vsphere_dnsdist()
{
  ansible-playbook -i inventory/ playbooks/vsphere_dnsdist.yml
}

function vsphere_lb()
{
  ansible-playbook -i inventory/ playbooks/vsphere_lb.yml
}

function vsphere_pdns()
{
  ansible-playbook -i inventory/ playbooks/pdns.yml
}

function vsphere_post_deployment_reboot()
{
  ansible-playbook -i inventory/ playbooks/reboot.yml --tags post_deployment_reboot
}

function vsphere_post_samba_deployment_reboot()
{
  # We need to reboot the Samba hosts after building AD to ensure everything is up clean and working
  ansible-playbook -i inventory/ playbooks/reboot.yml --tags post_samba_deployment_reboot
}

function vsphere_samba_phase_1()
{
  # This phase does not install Samba or build domain...
  ansible-playbook -i inventory/ playbooks/vsphere_samba.yml --tags samba_phase_1
}

function vsphere_samba_phase_2()
{
  # This phase will actually install Samba and build domain.
  # This needs to occur after reboot to ensure interfaces, dns, and everything
  # else in environment is up and functional.
  ansible-playbook -i inventory/ playbooks/vsphere_samba.yml --tags samba_phase_2
}

function vsphere_ssh_key_distribution()
{
  ansible-playbook -i inventory/ playbooks/ssh_key_distribution.yml
}
####
## End of vSphere functions ####
####

# If parameters are not passed every function below executes in the order that
# they are listed.
if [[ $# -eq 0 ]] ; then
  vsphere_management
  vsphere_vms
  vsphere_vms_info
  vsphere_dnsdist
  vsphere_samba_phase_1
  vsphere_ddi
  vsphere_lb
  vsphere_dns
  vsphere_vms_info
  vsphere_pdns
  vsphere_post_deployment_reboot
  vsphere_ssh_key_distribution
  vsphere_vms_info
  vsphere_samba_phase_2
  vsphere_post_samba_deployment_reboot
  vsphere_ad_domain
  # If a parameter is passed only that function executes.
else
  "$@"
fi
