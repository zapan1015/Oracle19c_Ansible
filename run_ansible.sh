#!/bin/bash
# Helper script to run Ansible from inside rac-node1

set -e

echo "=== Oracle 19c RAC Automation Wrapper ==="

# 1. Install Ansible if not present
if ! command -v ansible &> /dev/null; then
    echo "[INFO] Installing Ansible..."
    sudo dnf install -y epel-release
    sudo dnf install -y ansible-core python3-netaddr
else
    echo "[INFO] Ansible is already installed."
fi

# 2. Install Collections
echo "[INFO] Installing Ansible Collections..."
ansible-galaxy collection install ansible.posix community.general

# 3. Run Playbook
echo "[INFO] Running Ansible Playbook..."
# /vagrant is standard mount point for project root in Vagrant
cd /vagrant
# Export ANSIBLE_CONFIG to force usage of our config to bypass world-writable warning
export ANSIBLE_CONFIG=/vagrant/ansible.cfg
# Explicitly pass inventory file
ansible-playbook site.yml -i inventory/hosts "$@"

