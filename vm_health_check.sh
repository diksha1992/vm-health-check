#!/bin/bash
#
# VM Health Check Script for CentOS 7
# ▶ Checks CPU, memory, and root‑disk utilisation.
# ▶ Anything > 60 % ⇒ “Not Healthy”.
# ▶ Use  --explain  to always print the detailed metrics.

THRESHOLD=60
EXPLAIN=0
[[ "$1" == "--explain" ]] && EXPLAIN=1

# ---------- CPU ----------
# Example ‘top’ line:  %Cpu(s):  7.0 us,  2.0 sy,  0.0 ni, 89.9 id,  0.9 wa,  0.0 hi,  0.2 si,  0.0 st
CPU_IDLE=$(top -bn1 | awk -F',' '/%Cpu/{for(i=1;i<=NF;i++) if($i~" id") {gsub(/[^0-9.]/,"",$i); print $i}}')
CPU_USAGE=$(echo "scale=1; 100 - $CPU_IDLE" | bc)

# ---------- Memory ----------
read MEM_TOTAL MEM_USED < <(free -m | awk '/^Mem:/ {print $2,$3}')
MEM_USAGE=$(echo "scale=1; $MEM_USED*100/$MEM_TOTAL" | bc)

# ---------- Disk ( / ) ----------
DISK_USAGE=$(df -P / | awk 'END{gsub(/%/,"",$5);print $5}')

# ---------- Health logic ----------
REASONS=()

(( $(echo "$CPU_USAGE > $THRESHOLD" | bc -l) )) && \
  REASONS+=("CPU usage ${CPU_USAGE}% (> ${THRESHOLD}%)")

(( $(echo "$MEM_USAGE > $THRESHOLD" | bc -l) )) && \
  REASONS+=("Memory usage ${MEM_USAGE}% (> ${THRESHOLD}%)")

(( DISK_USAGE > THRESHOLD )) && \
  REASONS+=("Disk usage ${DISK_USAGE}% (> ${THRESHOLD}%)")

if [[ ${#REASONS[@]} -eq 0 ]]; then
    echo "VM Health Status: Healthy"
    [[ $EXPLAIN -eq 1 ]] && printf "All resource usages ≤ %s%%\n" "$THRESHOLD"
else
    echo "VM Health Status: Not Healthy"
    # Always show real values when unhealthy
    printf "Reasons:\n"
    for r in "${REASONS[@]}"; do
        printf "  • %s\n" "$r"
    done
fi
