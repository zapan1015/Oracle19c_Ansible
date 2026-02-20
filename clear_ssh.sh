#!/bin/bash
# Populate known_hosts using unhashed RSA keys (ssh-keyscan without -H, with -t rsa)
for user in grid oracle; do
  echo "Processing user $user on $(hostname)..."
  sudo su - $user -c "
    echo 'clearing known_hosts...'
    rm -f ~/.ssh/known_hosts
    known_hosts_file=~/.ssh/known_hosts
    
    # Scan standard hostnames and IPs with RSA keys, NO HASHING
    ssh-keyscan -t rsa rac-node1 rac-node2 localhost 127.0.0.1 >> \$known_hosts_file 2>/dev/null
    ssh-keyscan -t rsa 192.168.56.101 192.168.56.102 >> \$known_hosts_file 2>/dev/null
    ssh-keyscan -t rsa $(hostname) >> \$known_hosts_file 2>/dev/null
    ssh-keyscan -t rsa $(hostname -f) >> \$known_hosts_file 2>/dev/null
    
    # Ensure correct permissions
    chmod 644 \$known_hosts_file
    
    echo 'known_hosts populated (unhashed, RSA):'
    wc -l \$known_hosts_file
    head -n 3 \$known_hosts_file
    
    # Verify connectivity
    ssh -o BatchMode=yes -o StrictHostKeyChecking=no rac-node1 date
    ssh -o BatchMode=yes -o StrictHostKeyChecking=no rac-node2 date
    ssh -o BatchMode=yes -o StrictHostKeyChecking=no localhost date
  "
done
