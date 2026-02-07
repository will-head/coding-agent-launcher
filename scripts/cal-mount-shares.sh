#!/bin/bash
# CAL Cache Mount Script
# Mounts virtio-fs shares to their target locations
# Called by LaunchDaemon at boot and can be run manually

set -e
LOG_FILE="/tmp/cal-mount.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "$(date): Starting CAL mount script"

# Maximum retries for mount operations (virtio-fs may not be ready immediately)
MAX_RETRIES=5
RETRY_DELAY=2

mount_share() {
    local tag="$1"
    local mountpoint="$2"
    local retries=0

    # Create mount point if needed
    mkdir -p "$mountpoint"

    # Skip if already mounted
    if mount | grep -q " on $mountpoint " 2>/dev/null; then
        echo "Already mounted: $mountpoint"
        return 0
    fi

    # Attempt mount with retries
    while [ $retries -lt $MAX_RETRIES ]; do
        if mount_virtiofs "$tag" "$mountpoint" 2>/dev/null; then
            echo "Mounted $tag to $mountpoint"
            return 0
        fi
        retries=$((retries + 1))
        echo "Mount attempt $retries failed, retrying in ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    done

    echo "ERROR: Failed to mount $tag to $mountpoint after $MAX_RETRIES attempts"
    return 1
}

# Mount CAL cache
mount_share "cal-cache" "$HOME/.cal-cache" || true

# Future: iOS code signing
# mount_share "cal-signing" "$HOME/Library/MobileDevice" || true

# Future: Additional mounts
# mount_share "cal-workspace" "$HOME/workspace" || true

echo "$(date): CAL mount script complete"
