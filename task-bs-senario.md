Absolutely! Here’s a single file containing **both problem statements and their corresponding solution scripts**, nicely formatted for you to share with your students.

---

```bash
###############################################################
#                       BASH SCRIPTING LAB                    #
#                 Comprehensive Scenario-Based Tasks          #
###############################################################

# ===========================
# Scenario 1: System Info & User Greeting Script
# ===========================
# Problem Statement:
# Write a bash script named `system_report.sh` that:
# 1. Greets the user by asking their name and prints a welcome message.
# 2. Checks if a log file named system_report.log exists; if not, creates it.
# 3. Collects system information:
#    - Current date and time
#    - CPU usage
#    - Memory usage
#    - Network interface details
# 4. Writes this information into the log file with headings.
# 5. Use functions to modularize the script.
# 6. Include error handling.
# 7. Use conditionals to check command availability.
# 8. Use loops to iterate over network interfaces.
# 9. Use comments, shebang, variables, command substitution, comparison and logical operators.

# ===========================
# Solution: system_report.sh
# ===========================

#!/bin/bash
LOG_FILE="system_report.log"

# Function: greet user
greet_user() {
    echo "Enter your name:"
    read username
    echo "Welcome, $username!"
}

# Function: check and create log file
check_log_file() {
    if [ ! -f "$LOG_FILE" ]; then
        echo "Creating log file $LOG_FILE..."
        touch "$LOG_FILE"
        if [ $? -ne 0 ]; then
            echo "Error: Unable to create log file. Exiting."
            exit 1
        fi
    fi
}

# Function: collect and write date/time
write_datetime() {
    echo "=== Date and Time ===" >> "$LOG_FILE"
    echo "$(date)" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# Function: collect and write CPU usage
write_cpu_info() {
    echo "=== CPU Usage ===" >> "$LOG_FILE"
    if command -v top >/dev/null 2>&1; then
        top -bn1 | grep "Cpu(s)" >> "$LOG_FILE"
    else
        echo "Warning: 'top' command not found." >> "$LOG_FILE"
    fi
    echo "" >> "$LOG_FILE"
}

# Function: collect and write memory usage
write_mem_info() {
    echo "=== Memory Usage (MB) ===" >> "$LOG_FILE"
    if command -v free >/dev/null 2>&1; then
        free -m >> "$LOG_FILE"
    else
        echo "Warning: 'free' command not found." >> "$LOG_FILE"
    fi
    echo "" >> "$LOG_FILE"
}

# Function: collect and write network info
write_network_info() {
    echo "=== Network Interfaces ===" >> "$LOG_FILE"
    if command -v ip >/dev/null 2>&1; then
        interfaces=$(ip -o link show | awk -F': ' '{print $2}')
        for iface in $interfaces; do
            echo "Interface: $iface" >> "$LOG_FILE"
            ip addr show "$iface" >> "$LOG_FILE"
            echo "" >> "$LOG_FILE"
        done
    else
        echo "Warning: 'ip' command not found." >> "$LOG_FILE"
    fi
}

# Main script flow
greet_user
check_log_file
write_datetime
write_cpu_info
write_mem_info
write_network_info

echo "System report has been written to $LOG_FILE."



###############################################################

# ===========================
# Scenario 2: Configuration File Reader & System Checker
# ===========================
# Problem Statement:
# Write a bash script named `config_checker.sh` that:
# 1. Reads a config file named system_config.cfg with keys:
#    username, min_memory, max_cpu, network_interface
# 2. Reads config values into variables.
# 3. Asks user for username and compares with config username.
# 4. Checks if:
#    - Free memory >= min_memory (in MB)
#    - CPU usage < max_cpu (%)
#    - Configured network interface exists and is UP
# 5. Prints messages based on validations.
# 6. Use functions for modularity.
# 7. Use loops, conditionals, error handling.
# 8. Use comments and shebang line.

# ===========================
# Example system_config.cfg file:
# username=admin
# min_memory=2048
# max_cpu=80
# network_interface=eth0
# ===========================

# ===========================
# Solution: config_checker.sh
# ===========================

#!/bin/bash

CONFIG_FILE="system_config.cfg"

# Function: parse config file into variables
parse_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Config file $CONFIG_FILE not found."
        exit 1
    fi

    while IFS='=' read -r key value
    do
        case "$key" in
            username) config_username="$value" ;;
            min_memory) config_min_memory="$value" ;;
            max_cpu) config_max_cpu="$value" ;;
            network_interface) config_interface="$value" ;;
        esac
    done < "$CONFIG_FILE"
}

# Function: get current CPU usage percentage (integer)
get_cpu_usage() {
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk -F',' '{print $4}' | awk '{print $1}')
    cpu_usage=$(echo "100 - $cpu_idle" | bc)
    cpu_usage_int=${cpu_usage%.*}
    echo "$cpu_usage_int"
}

# Function: get free memory in MB
get_free_mem() {
    free_mem=$(free -m | awk '/^Mem:/ {print $7}')
    echo "$free_mem"
}

# Function: check if network interface is up
check_network_interface() {
    ip link show "$config_interface" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Interface $config_interface does not exist."
        return 1
    fi

    state=$(ip link show "$config_interface" | grep "state" | awk '{print $9}')
    if [ "$state" == "UP" ]; then
        return 0
    else
        echo "Interface $config_interface is down."
        return 1
    fi
}

# Main script flow
parse_config

echo "Enter your username:"
read input_username

if [ "$input_username" != "$config_username" ]; then
    echo "Access Denied: Username does not match."
    exit 1
fi

echo "Username verified."

free_mem=$(get_free_mem)
if [ "$free_mem" -lt "$config_min_memory" ]; then
    echo "Warning: Available memory ($free_mem MB) is less than minimum required ($config_min_memory MB)."
else
    echo "Memory check passed: $free_mem MB available."
fi

cpu_usage=$(get_cpu_usage)
if [ "$cpu_usage" -gt "$config_max_cpu" ]; then
    echo "Warning: CPU usage ($cpu_usage%) exceeds maximum allowed ($config_max_cpu%)."
else
    echo "CPU usage check passed: $cpu_usage%."
fi

check_network_interface
if [ $? -ne 0 ]; then
    echo "Network interface check failed."
else
    echo "Network interface $config_interface is up and running."
fi

echo "System validation complete."
```

---

**Usage:**

* Save the first script as `system_report.sh`, make executable (`chmod +x system_report.sh`) and run.
* Save the second script as `config_checker.sh` with a `system_config.cfg` file alongside, make executable, and run.

---

Let me know if you want me to help create lab instructions or slides based on these!
