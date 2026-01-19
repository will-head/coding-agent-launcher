# SOCKS Proxy for CAL VMs

**Purpose:** Enable reliable network connectivity in restrictive corporate environments by tunneling VM traffic through the host.

## Overview

CAL VMs run in isolated virtual networks (192.168.64.x) which may not have direct internet access in corporate environments with restrictive HTTP proxies. The SOCKS tunnel feature solves this by:

1. **VM → Host SSH Tunnel** - Creates an SSH SOCKS proxy from VM to host (port 1080)
2. **HTTP-to-SOCKS Bridge** - Runs `gost` to bridge HTTP/HTTPS to SOCKS (port 8080)
3. **Auto-Detection** - Tests connectivity and enables tunnel only when needed
4. **Security** - Uses restricted SSH keys that only allow tunneling, not shell access

## When Do You Need This?

### ✅ **You NEED SOCKS if:**
- Your company network blocks direct VM internet access
- Corporate HTTP proxy is required but VM can't use it
- `curl https://github.com` fails inside the VM

### ❌ **You DON'T NEED SOCKS if:**
- VM has direct internet access (most home/office networks)
- `curl https://github.com` works inside the VM

The `--socks auto` mode (default) automatically detects this and only enables SOCKS when needed.

---

## Prerequisites

### Required: SSH Server on Host Mac

SOCKS tunnel requires SSH server running on the host Mac to tunnel through.

**Check if SSH is enabled:**
```bash
sudo launchctl list | grep com.openssh.sshd
# If output shows "com.openssh.sshd", SSH is enabled
```

**Enable SSH server** (requires admin privileges):

**Option 1: System Settings (GUI)**
1. Open **System Settings**
2. Go to **General → Sharing**
3. Toggle **Remote Login** to **ON**

**Option 2: Command Line**
```bash
sudo systemsetup -setremotelogin on
```

**Verify SSH is accessible:**
```bash
nc -z 192.168.64.1 22 && echo "✓ SSH ready" || echo "✗ SSH not accessible"
```

⚠️ **If you don't have admin privileges:** SOCKS tunnel will not work. Use `--socks off` or contact your IT admin to enable Remote Login.

---

## Usage

### Basic Usage

```bash
# Auto mode (default) - detects if SOCKS is needed
./scripts/cal-bootstrap --init

# Force SOCKS on
./scripts/cal-bootstrap --init --socks on

# Force SOCKS off
./scripts/cal-bootstrap --init --socks off

# Check current status in VM
ssh admin@$(tart ip cal-dev) socks_status
```

### SOCKS Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `auto` (default) | Tests github.com connectivity, enables SOCKS only if needed | Recommended for all users |
| `on` | Always enable SOCKS tunnel | Corporate environments with known proxy issues |
| `off` | Never enable SOCKS tunnel | Direct internet access or troubleshooting |

**Examples:**
```bash
# Auto mode - recommended
./scripts/cal-bootstrap --run
# or explicitly:
./scripts/cal-bootstrap --run --socks auto

# Always enable SOCKS
./scripts/cal-bootstrap --run --socks on

# Disable SOCKS
./scripts/cal-bootstrap --run --socks off
```

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Host Mac (192.168.64.1)                                 │
│                                                          │
│  ┌─────────────────────┐                               │
│  │ SSH Server :22      │←─────────────────┐            │
│  │ (Remote Login)      │                  │            │
│  └─────────────────────┘                  │            │
│           ↓                                │            │
│  Internet Connection                      │            │
│  (corporate proxy, etc.)                  │            │
└───────────────────────────────────────────┼────────────┘
                                            │
                          SSH SOCKS Tunnel  │
                          (restricted key)  │
                                            │
┌───────────────────────────────────────────┼────────────┐
│ VM (cal-dev) 192.168.64.x                 │            │
│                                            │            │
│  ┌────────────────────────────────────────┴──────────┐ │
│  │ SSH Client (SOCKS -D 1080)                        │ │
│  │ ssh -D 1080 -N user@192.168.64.1                  │ │
│  └────────────────────────────────────────┬──────────┘ │
│                                            ↓            │
│  ┌─────────────────────────────────────────────────┐   │
│  │ gost HTTP Bridge :8080 → SOCKS :1080           │   │
│  └─────────────────────────────────────────────────┘   │
│           ↓                                            │
│  ┌─────────────────────────────────────────────────┐   │
│  │ Applications (curl, npm, claude, opencode, etc.)│   │
│  │ Use: SOCKS :1080 or HTTP :8080                  │   │
│  └─────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────┘
```

### Components

1. **SSH SOCKS Tunnel** (VM → Host)
   - VM runs: `ssh -D 1080 -N user@192.168.64.1`
   - Creates SOCKS5 proxy on VM port 1080
   - All traffic tunnels through host's internet connection

2. **HTTP-to-SOCKS Bridge** (`gost`)
   - Runs on VM: `gost -L http://:8080 -F socks5://localhost:1080`
   - Bridges HTTP/HTTPS to SOCKS for tools that don't support SOCKS directly
   - Node.js tools (opencode, npm) can use `http_proxy=http://localhost:8080`

3. **Restricted SSH Keys** (Security)
   - VM's SSH key on host has restrictions:
     ```
     restrict,port-forwarding,command="/usr/bin/true" ssh-ed25519 AAAA...
     ```
   - Can ONLY create port forwarding (SOCKS tunnel)
   - CANNOT execute commands or get shell access to host

---

## VM Commands

Once inside the VM, you have these commands available:

### `start_socks`
Start the SOCKS tunnel manually.

```bash
start_socks
```

**Output:**
```
Starting SOCKS tunnel (VM→Host on port 1080)...
✓ SOCKS tunnel started
✓ HTTP bridge started
```

### `stop_socks`
Stop the SOCKS tunnel and HTTP bridge.

```bash
stop_socks
```

**Output:**
```
Stopping SOCKS tunnel (PID: 1234)...
✓ SOCKS tunnel stopped
```

### `restart_socks`
Restart the tunnel (useful if connection drops).

```bash
restart_socks
```

### `socks_status`
Check tunnel status and test connectivity.

```bash
socks_status
```

**Output:**
```
SOCKS Tunnel Status:
  Mode: auto
  SOCKS port: 1080
  HTTP proxy port: 8080
  Host: claude@192.168.64.1

  Status: ✓ Running (PID: 1234)
  Connectivity: ✓ Working

  HTTP Bridge: ✓ Running (PID: 5678)
```

---

## Using SOCKS in Applications

### Environment Variables (Automatic)

When SOCKS is enabled, these environment variables are automatically set in the VM:

```bash
export ALL_PROXY="socks5://localhost:1080"
export HTTP_PROXY="http://localhost:8080"
export HTTPS_PROXY="http://localhost:8080"
```

Most tools respect these and will automatically use the proxy.

### Manual Configuration

**curl:**
```bash
# Via SOCKS
curl --socks5-hostname localhost:1080 https://api.github.com

# Via HTTP bridge
curl --proxy http://localhost:8080 https://api.github.com

# Automatic (uses HTTP_PROXY env var)
curl https://api.github.com
```

**npm:**
```bash
# Automatic (uses HTTP_PROXY)
npm install

# Or explicit:
npm config set proxy http://localhost:8080
npm config set https-proxy http://localhost:8080
```

**git:**
```bash
# Automatic (uses ALL_PROXY)
git clone https://github.com/user/repo.git

# Or explicit:
git config --global http.proxy http://localhost:8080
```

**opencode:**
```bash
# Uses HTTP_PROXY automatically
opencode chat
```

---

## Troubleshooting

### SOCKS tunnel won't start

**Check host SSH server:**
```bash
# On host Mac:
sudo launchctl list | grep com.openssh.sshd

# Should show: com.openssh.sshd
# If not, enable Remote Login (see Prerequisites)
```

**Check VM can reach host:**
```bash
# Inside VM:
nc -z 192.168.64.1 22 && echo "✓ Can reach host SSH" || echo "✗ Cannot reach host"
```

**Check logs:**
```bash
# On host:
tail -50 ~/.cal-bootstrap.log

# Inside VM:
tail -50 ~/.cal-socks.log
tail -50 ~/.cal-http-proxy.log
```

### Tunnel starts but connectivity fails

**Test SOCKS directly:**
```bash
# Inside VM:
curl --socks5-hostname localhost:1080 -I https://www.google.com
```

**Test HTTP bridge:**
```bash
# Inside VM:
curl --proxy http://localhost:8080 -I https://www.google.com
```

**Check if gost is running:**
```bash
# Inside VM:
ps aux | grep gost
lsof -i :8080
```

### Port already in use

**Check what's using the port:**
```bash
# Inside VM:
lsof -i :1080  # SOCKS port
lsof -i :8080  # HTTP bridge port
```

**Kill stale processes:**
```bash
# Inside VM:
stop_socks
pkill -f "ssh -D 1080"
pkill gost
start_socks
```

### SSH key authentication fails

**Check authorized_keys on host:**
```bash
# On host Mac:
grep "restrict,port-forwarding" ~/.ssh/authorized_keys
# Should show the VM's restricted key
```

**Check VM's SSH key:**
```bash
# Inside VM:
ls -la ~/.ssh/id_ed25519*
# Should show private key (id_ed25519) and public key (id_ed25519.pub)
```

**Re-run setup:**
```bash
# On host:
./scripts/cal-bootstrap --restart --socks on
# This will re-run setup_vm_ssh_key (idempotent)
```

### Auto-start not working

Check if auto-start is configured:
```bash
# Inside VM:
cat ~/.zshrc | grep "CAL SOCKS"
# Should show function definitions

cat ~/.cal-socks-config
# Should show SOCKS environment variables
```

**Re-run vm-setup.sh to fix:**
```bash
# From host:
ssh admin@$(tart ip cal-dev)
# Inside VM:
~/vm-setup.sh
```

---

## Security

### Restricted SSH Keys

The VM's SSH key is added to the host's `~/.ssh/authorized_keys` with strict restrictions:

```
restrict,port-forwarding,command="/usr/bin/true" ssh-ed25519 AAAA...
```

**What this means:**
- ✅ **CAN:** Create port forwarding (SOCKS tunnel)
- ❌ **CANNOT:** Execute commands on host
- ❌ **CANNOT:** Get shell access to host
- ❌ **CANNOT:** Read host files
- ❌ **CANNOT:** Access host beyond creating the tunnel

**Testing restrictions:**
```bash
# Inside VM - try to execute command (should fail):
ssh claude@192.168.64.1 'ls'
# Expected: Connection closes immediately or "PTY allocation request failed"

# Inside VM - try to get shell (should fail):
ssh claude@192.168.64.1
# Expected: Connection closes immediately

# Inside VM - create tunnel (should succeed):
ssh -D 1080 -N claude@192.168.64.1
# Expected: Tunnel works
```

### Host Key Verification

The host's SSH key is pre-populated in the VM's `~/.ssh/known_hosts`:

```bash
# Inside VM:
ssh -o StrictHostKeyChecking=yes claude@192.168.64.1
# Uses strict checking - prevents MITM attacks
```

### Audit Trail

All SOCKS operations are logged:

```bash
# Host logs:
~/.cal-bootstrap.log

# VM logs:
~/.cal-socks.log        # Tunnel errors
~/.cal-http-proxy.log   # gost bridge errors
```

---

## Advanced Configuration

### Custom Ports

Set environment variables before running cal-bootstrap:

```bash
export SOCKS_PORT=9050
export HTTP_PROXY_PORT=9080
./scripts/cal-bootstrap --run --socks on
```

### Custom Host Gateway

If your VM network uses a different gateway:

```bash
export HOST_GATEWAY=192.168.65.1
./scripts/cal-bootstrap --run --socks on
```

### Persistent Configuration

Set in your shell profile (`.zshrc` or `.bash_profile`):

```bash
export SOCKS_MODE=on
export SOCKS_PORT=1080
export HTTP_PROXY_PORT=8080
```

---

## Uninstalling

### Remove VM Key from Host

```bash
# On host Mac:
# Find the VM's key line
grep "restrict,port-forwarding.*cal-vm-socks" ~/.ssh/authorized_keys

# Remove it
sed -i '' '/restrict,port-forwarding.*cal-vm-socks/d' ~/.ssh/authorized_keys
```

### Disable Auto-Start in VM

```bash
# Inside VM:
# Remove SOCKS functions from .zshrc
sed -i '' '/# CAL SOCKS Tunnel Functions/,/^fi$/d' ~/.zshrc

# Remove config file
rm ~/.cal-socks-config

# Reload shell
exec zsh
```

### Disable Remote Login on Host

If you only enabled SSH for CAL and want to disable it:

```bash
# On host Mac:
sudo systemsetup -setremotelogin off
```

---

## FAQ

### Q: Why not use HTTP_PROXY directly?

**A:** Many corporate proxies require authentication or have complex rules. The VM doesn't have access to corporate credentials or proxy PAC files. Tunneling through the host's connection bypasses all of this.

### Q: Does this work with VPNs?

**A:** Yes! If your host Mac is connected to a corporate VPN, the tunnel will route through the VPN automatically.

### Q: What's the performance impact?

**A:** Minimal. Traffic goes:
- VM → SOCKS (localhost) → Host SSH → Internet
- Extra latency: ~1-5ms (local SSH hop)
- Bandwidth: Matches host's connection

### Q: Can multiple VMs share one tunnel?

**A:** Each VM creates its own tunnel. They don't interfere with each other.

### Q: Why does auto mode test github.com?

**A:** GitHub is essential for AI coding agents (cloning repos, etc.). If the VM can reach github.com directly, SOCKS isn't needed. If it can't, SOCKS is enabled automatically.

### Q: What if I don't have admin access to enable SSH?

**A:** Contact your IT administrator and request Remote Login be enabled. Explain you need it for development in isolated VMs. If they decline, you can't use SOCKS tunnel. Try `--socks off` and see if direct access works.

### Q: Can I use this for production?

**A:** CAL is designed for **development only**. Don't use it for production workloads or sensitive data processing.

---

## See Also

- [Bootstrap Documentation](bootstrap.md) - Manual Tart setup and VM management
- [Architecture Documentation](architecture.md) - Overall CAL design
- [ADR-001](adr/ADR-001-cal-isolation.md) - Original design decisions
