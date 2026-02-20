# -*- mode: ruby -*-
# vi: set ft=ruby :

# Absolute path for shared ASM disks to ensure File.exist? works correctly
ASM_DISK_DIR = File.dirname(File.expand_path(__FILE__))

Vagrant.configure("2") do |config|
  config.vm.box = "island-oraclelinux8"
  config.vm.box_check_update = false

  # Define nodes
  nodes = [
    { name: "rac-node1", public_ip: "192.168.56.101", private_ip: "192.168.10.101" },
    { name: "rac-node2", public_ip: "192.168.56.102", private_ip: "192.168.10.102" },
  ]

  nodes.each_with_index do |node_cfg, index|
    config.vm.define node_cfg[:name] do |node|
      node.vm.hostname = node_cfg[:name]

      # Network:
      # eth0: NAT (Default)
      # eth1: Public (Host-only)
      node.vm.network "private_network", ip: node_cfg[:public_ip], netmask: "255.255.255.0", nic_type: "virtio"
      # eth2: Private Interconnect (Isolated network)
      node.vm.network "private_network", ip: node_cfg[:private_ip], netmask: "255.255.255.0", nic_type: "virtio", virtualbox__intnet: "rac-priv-net"

      node.vm.provider "virtualbox" do |vb|
        vb.memory = 6144  # 6GB RAM per node
        vb.cpus = 2       # 2 vCPUs
        vb.gui = false

        # Enable IO APIC (Required for 64-bit guests & SMP)
        vb.customize ["modifyvm", :id, "--ioapic", "on"]

        # Create Shared ASM Disks only on the FIRST node (they are shared between nodes)
        if index == 0
          (1..4).each do |i|
            disk_file = File.join(ASM_DISK_DIR, "asm_disk#{i}.vdi")
            unless File.exist?(disk_file)
              vb.customize ['createhd', '--filename', disk_file, '--size', '10240', '--format', 'VDI', '--variant', 'Fixed']
              vb.customize ['modifyhd', disk_file, '--type', 'shareable']
            end
          end
        end

        # Add a dedicated Storage Controller for ASM disks (SAS)
        vb.customize ['storagectl', :id, '--name', 'ASM_SAS', '--add', 'sas', '--controller', 'LSILogicSAS']

        # Attach shared ASM disks to each node
        (1..4).each do |i|
          disk_file = File.join(ASM_DISK_DIR, "asm_disk#{i}.vdi")
          vb.customize ['storageattach', :id, '--storagectl', 'ASM_SAS', '--port', i, '--device', 0, '--type', 'hdd', '--medium', disk_file, '--mtype', 'shareable']
        end
      end
    end
  end
end
