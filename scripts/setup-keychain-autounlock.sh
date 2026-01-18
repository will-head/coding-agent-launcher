#!/bin/zsh

# Solution: Auto-unlock keychain on login using LaunchAgent
# This creates a LaunchAgent that unlocks the keychain when the user logs in

set -e

VM_IP="${1:-}"
VM_USER="${VM_USER:-admin}"
VM_PASSWORD="${VM_PASSWORD:-admin}"

if [ -z "$VM_IP" ]; then
    echo "Usage: $0 <vm-ip>"
    echo ""
    echo "Example: $0 192.168.64.16"
    exit 1
fi

echo "Creating keychain auto-unlock LaunchAgent..."
echo ""

# Create the unlock script in VM
cat <<'UNLOCK_SCRIPT' | ssh "${VM_USER}@${VM_IP}" 'cat > /tmp/unlock-keychain.sh && chmod +x /tmp/unlock-keychain.sh'
#!/bin/zsh
# Unlock keychain on login
security unlock-keychain -p "admin" login.keychain
UNLOCK_SCRIPT

# Create LaunchAgent plist
cat <<'PLIST' | ssh "${VM_USER}@${VM_IP}" 'cat > /tmp/com.cal.unlock-keychain.plist'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cal.unlock-keychain</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/admin/unlock-keychain.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/unlock-keychain.err</string>
    <key>StandardOutPath</string>
    <string>/tmp/unlock-keychain.out</string>
</dict>
</plist>
PLIST

# Install the files
echo "Installing LaunchAgent..."
ssh "${VM_USER}@${VM_IP}" <<'INSTALL'
mkdir -p ~/Library/LaunchAgents
mv /tmp/unlock-keychain.sh ~/unlock-keychain.sh
mv /tmp/com.cal.unlock-keychain.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.cal.unlock-keychain.plist
echo "✓ LaunchAgent installed and loaded"
INSTALL

echo ""
echo "✓ Keychain will now auto-unlock on every login"
echo ""
echo "Test it:"
echo "1. Reboot the VM"
echo "2. SSH in and run: agent whoami"
echo "3. Should work without manual unlock"
