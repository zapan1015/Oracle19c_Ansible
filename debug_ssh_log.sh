#!/bin/bash
CVU_DIR=$(ls -td /tmp/CVU* 2>/dev/null | head -n 1)
echo "CVU Dir: $CVU_DIR"
if [ ! -z "$CVU_DIR" ]; then
  # Find log file inside (recursive? or in scratch/?)
  # Usually in <CVU_DIR>/cvu_<node><date>.log?
  # Or simply cat all .log files in there.
  echo "--- CVU LOG CONTENT (grep SSH) ---"
  find $CVU_DIR -name "*.log" -exec grep -H "SSH" {} + | head -n 50
  
  echo "--- CVU LOG DETAILS (grep INS) ---"
  find $CVU_DIR -name "*.log" -exec grep -H "INS" {} + | head -n 50
fi

echo "--- KNOWN_HOSTS ---"
cat ~/.ssh/known_hosts
echo "--- HOSTNAME CHECK ---"
hostname
hostname -f
getent hosts rac-node1
getent hosts rac-node2
