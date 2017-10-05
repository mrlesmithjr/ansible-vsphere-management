#! /usr/bin/env bash

# Stop script on error in order to troubleshoot issues
set -e

####
# Beginning of variable definitions
####
# Define the directory to your Ansible inventory
ANSIBLE_INVENTORY_DIR="inventory"

# Define command or path to ansible-playbook command
ANSIBLE_PLAYBOOK_COMMAND="ansible-playbook"

# Define the directory to your Ansible playbooks
ANSIBLE_PLAYBOOKS_DIR="playbooks"

# Define the directory to store logs in
LOG_DIR="logs"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
####
# End of variable definitions
####


####
## Beginning of vSphere functions
####
cleanup()
{
  CLEANUP_FILES=(
    ".galaxy_install_info" \
    "*.retry" \
    "generated_inventory.inv" \
    "ssh_keys_distribution.yml" \
    "vsphere_bootstrap_vms.inv" \
    "vsphere_bootstrap_vms.json" \
    "vsphere_ddi_vms.inv" \
    "vsphere_ddi_vms.json" \
    "vsphere_dhcp_vms.inv" \
    "vsphere_dnsdist_vms.inv" \
    "vsphere_dnsdist_vms.json" \
    "vsphere_lb_vms.inv" \
    "vsphere_lb_vms.json" \
    "vsphere_samba_vms.inv" \
    "vsphere_samba_vms.json"
  )
  for cleanup in "${CLEANUP_FILES[@]}"
  do
    find $ANSIBLE_INVENTORY_DIR -type f -name $cleanup -exec rm -f {} \;
  done
}

deploy_all()
{
  vsphere_management
  vsphere_vms
  vsphere_dnsdist_vms
  vsphere_samba_phase_1
  vsphere_ddi_vms
  vsphere_lb_vms
  vsphere_dns
  vsphere_pdns
  vsphere_post_deployment_reboot
  vsphere_ssh_key_distribution
  vsphere_samba_phase_2
  vsphere_post_samba_deployment_reboot
  vsphere_samba_sysvol_replication
  vsphere_ad_domain
  exit 0
}

display_usage() {
  echo "vSphere Management Script"
  echo -e "\nThis script is for managing your vSphere environment in a holistic fashion.\n"
  echo -e "Twitter:\thttps://www.twitter.com/mrlesmithjr"
  echo -e "Blog:\t\thttp://www.everythingshouldbevirtual.com"
  echo -e "Blog:\t\thttp://mrlesmithjr.com"
  echo -e "Email:\t\tmrlesmithjr@gmail.com"
  echo -e "\nThis script requires one of the following arguments to be passed in order to perform a task."
  echo -e "\nUsage:\n\nvsphere_management.sh [arguments] \n"
  echo -e "\narguments:"
  echo -e "\tcleanup\t\t\t\t\tCleans up generated inventory, JSON data, and SSH key data"
  echo -e "\tdeploy_all\t\t\t\tDeploys whole environment"
  echo -e "\tvsphere_ad_domain\t\t\tManages vSphere hosts AD membership"
  echo -e "\tvsphere_ddi_vms\t\t\t\tManages DDI VMs"
  echo -e "\tvsphere_disable_ssh\t\t\tDisables vSphere hosts SSH"
  echo -e "\tvsphere_enable_ssh\t\t\tEnables vSphere hosts SSH"
  echo -e "\tvsphere_dns\t\t\t\tManages vSphere hosts DNS settings"
  echo -e "\tvsphere_dnsdist_vms\t\t\tManages DNSDist VMs"
  echo -e "\tvsphere_lb_vms\t\t\t\tManages Load Balancer VMs"
  echo -e "\tvsphere_maintenance_mode\t\tManages vSphere hosts maintenance mode"
  echo -e "\tvsphere_management\t\t\tManages ALL vSphere host settings"
  echo -e "\tvsphere_network\t\t\t\tManages vSphere hosts network settings"
  echo -e "\tvsphere_pdns\t\t\t\tManages PowerDNS zones, records, and etc."
  echo -e "\tvsphere_post_deployment_reboot\t\tPerforms a post deployment reboot (Only if not already performed)"
  echo -e "\tvsphere_post_samba_deployment_reboot\tPerforms a post Samba deployment reboot (Only if not already performed)"
  echo -e "\tvsphere_samba_phase_1\t\t\tManages Samba VMs Stage 1 tasks (Does not install Samba)"
  echo -e "\tvsphere_samba_phase_2\t\t\tManages Samba VMs Stage 2 tasks (Installs Samba and sets up AD)"
  echo -e "\tvsphere_samba_sysvol_replication\tManages Samba VMs AD SysVol Replication"
  echo -e "\tvsphere_samba_vms\t\t\tManages Samba VMs (Does not perform Phase 1, 2, or SysVol Replication)"
  echo -e "\tvsphere_ssh_key_distribution\t\tDistributes SSH Keys between VMs (Currently only Samba VMs)"
  echo -e "\tvsphere_vms\t\t\t\tManages ALL VMs (Does not perform any post provisioning tasks)"
  echo -e "\tvsphere_vms_info\t\t\tCollects info for ALL VMs and updates inventory and etc."
  echo -e "\n\nAll arguments support additional Ansible command line arguments to be passed. However, only the following"
  echo -e "support passing a --limit most of the tasks run against the power_cli_host so the task will be"
  echo -e "skipped as no hosts will be found that match."
  echo -e "\nUsage:\n\nvsphere_management.sh [arguments] [--argument]\n"
  echo -e "\nExample:\n\tvsphere_management.sh vsphere_maintenance_mode --extra-vars '{\"vsphere_enable_software_iscsi\": True}'"
  echo -e "\nadditional arguments which support --limit to be passed:\n"
  echo -e "\t\tvsphere_post_deployment_reboot"
  echo -e "\t\tvsphere_post_samba_deployment_reboot"
  echo -e "\t\tvsphere_samba_phase_1"
  echo -e "\t\tvsphere_samba_phase_2"
  echo -e "\t\tvsphere_samba_sysvol_replication"
  echo -e "\t\tvsphere_ssh_key_distribution"
  echo -e "\nExample:\n\tvsphere_management.sh vsphere_post_deployment_reboot --limit node0.vagrant.local\n"
}

generate_inventory()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/generate_inventory.yml
}

logging()
{
  if [ ! -d $LOG_DIR ]; then
    mkdir $LOG_DIR
  else [ -d $LOG_DIR ]
    echo "$LOG_DIR already exists"
  fi

  if [ -f $LOG_DIR/ansible.log ]; then
    mv $LOG_DIR/ansible.log $LOG_DIR/ansible.log.$TIMESTAMP
  fi
}

vsphere_ad_domain()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_management --tags vsphere_ad_domain
}

vsphere_ddi_vms()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_ddi_vms
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_ddi_vms_info
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_ddi.yml
}

vsphere_dns()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_dns
}

vsphere_dnsdist_vms()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_dnsdist_vms
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_dnsdist_vms_info
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_dnsdist.yml
}

vsphere_disable_ssh()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_ssh --extra-vars '{"vsphere_hosts_enable_ssh": False}'
}

vsphere_enable_ssh()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_ssh --extra-vars '{"vsphere_hosts_enable_ssh": True}'
}

vsphere_lb_vms()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_lb_vms
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_lb_vms_info
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_lb.yml
}

vsphere_maintenance_mode()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_maintenance_mode
}

vsphere_management()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_management
}

vsphere_network()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_network
}

vsphere_pdns()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/pdns.yml
}

vsphere_post_deployment_reboot()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/reboot.yml --tags post_deployment_reboot "$@"
}

vsphere_post_samba_deployment_reboot()
{
  # We need to reboot the Samba hosts after building AD to ensure everything is up clean and working
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/reboot.yml --tags post_samba_deployment_reboot "$@"
}

vsphere_samba_phase_1()
{
  # This phase does not install Samba or build domain...
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_samba.yml --tags samba_phase_1 "$@"
}

vsphere_samba_phase_2()
{
  # This phase will actually install Samba and build domain.
  # This needs to occur after reboot to ensure interfaces, dns, and everything
  # else in environment is up and functional.
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_samba.yml --tags samba_phase_2 "$@"
}

vsphere_samba_sysvol_replication()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_samba.yml --tags samba_sysvol_replication "$@"
}

vsphere_samba_vms()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_samba_vms
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_samba_vms_info
}

vsphere_ssh_key_distribution()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/ssh_key_distribution.yml "$@"
}

vsphere_udpates()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_udpates
}

vsphere_vms()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_vms
}

vsphere_vms_info()
{
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_management.yml --tags vsphere_vms_info
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_dnsdist.yml --tags vsphere_dnsdist_vms_info
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_samba.yml --tags vsphere_samba_vms_info
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_ddi.yml --tags vsphere_ddi_vms_info
  $ANSIBLE_PLAYBOOK_COMMAND -i $ANSIBLE_INVENTORY_DIR/ $ANSIBLE_PLAYBOOKS_DIR/vsphere_lb.yml --tags vsphere_lb_vms_info
}
####
## End of vSphere functions ####
####


####
# Beginning of script execution
####
if [[ "$1" == "--help" ]]
then
  display_usage
  exit 0
elif [[ $# -eq 0 ]]
then
  echo -e "This script REQUIRES an argument to be passed to perform certain tasks!\n"
  echo -e "To view help:\n\n\tvsphere_management.sh --help\n"
  exit 0
else
  logging
  "$@"
  exit 0
fi
####
# End of script execution
####
