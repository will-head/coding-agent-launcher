#!/bin/bash
# CALF Cache Mount Script
# Mounts virtio-fs shares to their target locations
# Called by LaunchDaemon at boot and can be run manually

set -e
LOG_FILE="/tmp/calf-mount.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "$(date): Starting CALF mount script"

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

# Check if VM is in no-mount mode
NO_MOUNT=false
if [ -f "$HOME/.calf-vm-config" ]; then
    # Source the config file to read NO_MOUNT setting
    source "$HOME/.calf-vm-config"
fi

if [ "$NO_MOUNT" = true ]; then
    # No-mount mode: Create local cache directories instead of mounting
    echo "No-mount mode enabled: Creating local cache directories"
    mkdir -p "$HOME/.calf-cache"/{homebrew,npm,go,git}
    echo "Created local cache directories: $HOME/.calf-cache/{homebrew,npm,go,git}"
else
    # Shared cache mode: Mount from host
    echo "Shared cache mode: Mounting host cache"
    mount_share "calf-cache" "$HOME/.calf-cache" || true
fi

# Future: iOS code signing
# mount_share "cal-signing" "$HOME/Library/MobileDevice" || true

# Future: Additional mounts
# mount_share "cal-workspace" "$HOME/workspace" || true

echo "$(date): CALF mount script complete"
