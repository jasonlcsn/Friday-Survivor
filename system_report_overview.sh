#!/usr/bin/env bash
# =============================================================================
# system_report_overview.sh
#
# Usage: ./system_report_overview.sh
# =============================================================================
 
# Print a section title
print_title() {
    printf '\n=== %s ===\n' "$1"
}
 
# Print one line of the report: label + value
print_line() {
    printf '  %-20s %s\n' "$1" "$2"
}
 
# -----------------------------------------------------------------------------
# General information
# -----------------------------------------------------------------------------
print_title "General"
print_line "Hostname"     "$(hostname)"
print_line "Date and time" "$(date)"
print_line "Kernel"       "$(uname -r)"
print_line "Current user" "$(whoami)"
 
# -----------------------------------------------------------------------------
# CPU usage:
# -----------------------------------------------------------------------------
read_cpu_ticks() {
    local user nice system idle iowait irq softirq steal
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    total_ticks=$((user + nice + system + idle + iowait + irq + softirq + steal))
    idle_ticks=$((idle + iowait))
}
 
print_title "CPU"
cores=$(nproc)
 
read_cpu_ticks
first_total=$total_ticks
first_idle=$idle_ticks
sleep 1
read_cpu_ticks
 
total_diff=$((total_ticks - first_total))
idle_diff=$((idle_ticks - first_idle))
cpu_percent=$((100 * (total_diff - idle_diff) / total_diff))
 
print_line "Cores"     "$cores"
print_line "CPU usage" "${cpu_percent}%"
 
# -----------------------------------------------------------------------------
# Uptime and load average
# -----------------------------------------------------------------------------
print_title "Uptime and Load"
read -r load1 load5 load15 _ < /proc/loadavg
print_line "Uptime"       "$(uptime -p)"
print_line "Load average" "$load1 (1 min), $load5 (5 min), $load15 (15 min)"
 
# ${load1%.*} removes the decimals, so 4.52 becomes 4
if [ "${load1%.*}" -ge "$cores" ]; then
    print_line "Load status" "HIGH (at or above the number of cores)"
else
    print_line "Load status" "OK"
fi
 
# -----------------------------------------------------------------------------
# Memory and swap
# -----------------------------------------------------------------------------
print_title "Memory"
mem_total=$(free -m | awk '/^Mem:/  {print $2}')
mem_used=$(free -m  | awk '/^Mem:/  {print $3}')
mem_avail=$(free -m | awk '/^Mem:/  {print $7}')
swap_total=$(free -m | awk '/^Swap:/ {print $2}')
swap_used=$(free -m  | awk '/^Swap:/ {print $3}')
 
print_line "Total"     "${mem_total} MB"
print_line "Used"      "${mem_used} MB"
print_line "Available" "${mem_avail} MB"
print_line "Swap used" "${swap_used} MB of ${swap_total} MB"
 
# -----------------------------------------------------------------------------
# Disk usage
# -----------------------------------------------------------------------------
print_title "Disk"
df -h -x tmpfs -x devtmpfs | awk '{printf "  %-24s %-6s used of %-6s (%s)\n", $6, $3, $2, $5}'
 
# -----------------------------------------------------------------------------
# Top 5 processes by CPU and by memory
# -----------------------------------------------------------------------------
print_title "Top 5 Processes by CPU"
ps -eo pid,pcpu,pmem,comm --sort=-pcpu | head -n 6
 
print_title "Top 5 Processes by Memory"
ps -eo pid,pcpu,pmem,comm --sort=-pmem | head -n 6
 
# -----------------------------------------------------------------------------
# Network
# -----------------------------------------------------------------------------
print_title "Network"
print_line "IP addresses" "$(hostname -I)"
echo "  Listening ports:"
ss -tuln | awk 'NR > 1 {print "    " $1, $5}'
 
# -----------------------------------------------------------------------------
# Logged-in users
# -----------------------------------------------------------------------------
print_title "Logged-in Users"
who
