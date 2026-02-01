#!/bin/bash

COLOR="${1:-white}"

# Read JSON input
input=$(cat)

# Extract all available fields
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
# Use current context window usage (not cumulative session tokens)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
remaining_pct=$(echo "$input" | jq -r '.context_window.remaining_percentage // 100')
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Format used percentage to 1 decimal place
used_pct=$(printf "%.1f" "$used_pct")

# Session duration (convert ms to readable format)
if [ $duration_ms -gt 0 ]; then
    duration_sec=$((duration_ms / 1000))
    duration_min=$((duration_sec / 60))
    duration_hour=$((duration_min / 60))

    if [ $duration_hour -gt 0 ]; then
        duration_str="${duration_hour}h$((duration_min % 60))m"
    elif [ $duration_min -gt 0 ]; then
        duration_str="${duration_min}m"
    else
        duration_str="${duration_sec}s"
    fi
else
    duration_str="0s"
fi

# Build simplified context status
context_status="${used_pct}%"

# Get used percentage as integer for color logic
used_pct_int=${used_pct%.*}

# Format cost display (2 decimal places)
cost_int=${cost%.*}
if [ "$cost_int" = "0" ] && [ "${cost#*.}" = "0000" ]; then
    cost_display="\$0"
else
    cost_display="\$$(printf '%.2f' $cost)"
fi

# Build full status line
status="🤖 $model 🧠 $context_status ⏱️ ${duration_str} 💰 ${cost_display}"

# Apply base color with context-based intensity
case "$COLOR" in
    blue)
        if [ $used_pct_int -gt 80 ]; then
            echo -e "\033[1;31m$status\033[0m"  # Red when >80%
        elif [ $used_pct_int -gt 50 ]; then
            echo -e "\033[1;33m$status\033[0m"  # Yellow when >50%
        else
            echo -e "\033[34m$status\033[0m"    # Blue normal
        fi
        ;;
    green)
        if [ $used_pct_int -gt 80 ]; then
            echo -e "\033[1;31m$status\033[0m"
        elif [ $used_pct_int -gt 50 ]; then
            echo -e "\033[1;33m$status\033[0m"
        else
            echo -e "\033[32m$status\033[0m"
        fi
        ;;
    yellow)
        if [ $used_pct_int -gt 80 ]; then
            echo -e "\033[1;31m$status\033[0m"
        else
            echo -e "\033[33m$status\033[0m"
        fi
        ;;
    orange)
        if [ $used_pct_int -gt 80 ]; then
            echo -e "\033[1;31m$status\033[0m"
        elif [ $used_pct_int -gt 50 ]; then
            echo -e "\033[1;33m$status\033[0m"
        else
            echo -e "\033[38;5;208m$status\033[0m"  # Orange normal
        fi
        ;;
    magenta)
        if [ $used_pct_int -gt 80 ]; then
            echo -e "\033[1;31m$status\033[0m"
        elif [ $used_pct_int -gt 50 ]; then
            echo -e "\033[1;33m$status\033[0m"
        else
            echo -e "\033[35m$status\033[0m"
        fi
        ;;
    cyan)
        if [ $used_pct_int -gt 80 ]; then
            echo -e "\033[1;31m$status\033[0m"
        elif [ $used_pct_int -gt 50 ]; then
            echo -e "\033[1;33m$status\033[0m"
        else
            echo -e "\033[36m$status\033[0m"
        fi
        ;;
    red)     echo -e "\033[31m$status\033[0m" ;;
    *)       echo "$status" ;;
esac
