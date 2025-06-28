#!/bin/bash

# VM Health Check Script for CentOS 7 (Proxmox VM)
# Analyzes CPU, Memory, and Disk utilization.
# If any of the three resource usages > 60%, health is "Not Healthy", otherwise "Healthy".
# Use '--explain' argument to see detailed reasons.

EXPLAIN=0
if [[ "$1" == "--explain" ]]; then
    EXPLAIN=1
fi

# Get CPU Utilization (average over 1 minute)
CPU_IDLE=$(top -bn1 | grep "Cpu(s)" | awk -F'id,' -v prefix="$prefix" '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); print v }')
CPU_USAGE=$(echo "scale=2; 100 - $CPU_IDLE" | bc)

# Get Memory Utilization
MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/^Mem:/ {print $3}')
MEM_USAGE=$(echo "scale=2; $MEM_USED*100/$MEM_TOTAL" | bc)

# Get Disk Utilization (Root / partition)
DISK_USAGE=$(df -P / | awk 'END{print $(NF-1)}' | sed 's/%//')

HEALTHY=1
REASONS=()

if (( $(echo "$CPU_USAGE > 60" | bc -l) )); then
    HEALTHY=0
    REASONS+=("CPU usage is ${CPU_USAGE}% (> 60%)")
fi

if (( $(echo "$MEM_USAGE > 60" | bc -l) )); then
    HEALTHY=0
    REASONS+=("Memory usage is ${MEM_USAGE}% (> 60%)")
fi

if (( $(echo "$DISK_USAGE > 60" | bc -l) )); then
    HEALTHY=0
    REASONS+=("Disk usage is ${DISK_USAGE}% (> 60%)")
fi

if [[ $HEALTHY -eq 1 ]]; then
    STATUS="Healthy"
    [[ $EXPLAIN -eq 1 ]] && echo "The VM is healthy. All resource usages are below or equal to 60%."
else
    STATUS="Not Healthy"
    if [[ $EXPLAIN -eq 1 ]]; then
        echo "The VM is NOT healthy due to the following reasons:"
        for reason in "${REASONS[@]}"; do
            echo "- $reason"
        done
    fi
fi

echo "VM Health Status: $STATUS"
