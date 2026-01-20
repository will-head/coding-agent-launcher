# Transparent Proxy for CAL VMs

**Purpose:** Enable reliable network connectivity in restrictive corporate environments by tunneling VM traffic through the host.

## Overview

CAL VMs run in isolated virtual networks (192.168.64.x) which may not have direct internet access in corporate environments. The transparent proxy feature solves this using **sshuttle** - a tool that creates a VPN-like tunnel requiring no application configuration.

### Key Benefits

| Feature | Description |
|---------|-------------|
| **Truly Transparent** | No `HTTP_PROXY` env vars needed - all TCP traffic routes automatically |
| **Works with Everything** | Any application works without configuration |
| **DNS Handling** | DNS queries also route through the tunnel |
| **Simple** | One command starts the tunnel |
| **Conditional** | Auto mode enables proxy only when needed |

## When Do You Need This?

### ✅ **You NEED proxy if:**
- Your company network blocks direct VM internet access
- Corporate HTTP proxy is required but VM can't use it
- `curl https://github.com` fails inside the VM

### ❌ **You DON'T need proxy if:**
- VM has direct internet access (most home/office networks)
- `curl https://github.com` works inside the VM

The `--proxy auto` mode (default) automatically detects this and only enables proxy when needed.

---

## Prerequisites

### Required: SSH Server on Host Mac

The proxy requires SSH server running on the host Mac.

**Check if SSH is enabled:**
```bash
nc -z 192.168.64.1 22 && echo "✓ SSH ready" || echo "✗ SSH not accessible"
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

### Required: Python on Host Mac

sshuttle requires Python on the host (server side). macOS includes Python by default.

**Verify:**
```bash
python3 --version
```

---

## Usage

### Basic Usage

```bash
# Auto mode (default) - detects if proxy is needed
./scripts/cal-bootstrap --init

# Force proxy on
./scripts/cal-bootstrap --init --proxy on

# Force proxy off
./scripts/cal-bootstrap --init --proxy off

# Check current status in VM
ssh admin@$(tart ip cal-dev) proxy-status
```

### Proxy Modes

| Mode | Behavior | Use Case |
|------|----------|----------|
| `auto` (default) | Tests github.com connectivity, enables proxy only if needed | Recommended for all users |
| `on` | Always enable proxy | Corporate environments with known network issues |
| `off` | Never enable proxy | Direct internet access or troubleshooting |

**Examples:**
```bash
# Auto mode - recommended
./scripts/cal-bootstrap --run
# or explicitly:
./scripts/cal-bootstrap --run --proxy auto

# Always enable proxy
./scripts/cal-bootstrap --run --proxy on

# Disable proxy
./scripts/cal-bootstrap --run --proxy off
```

---

## How It Works

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              VM (cal-dev)                                   │
│                                                                             │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                      │
│  │ curl        │    │ npm/node    │    │ opencode    │  ... any app         │
│  │ (no config) │    │ (no config) │    │ (no config) │                      │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                      │
│         │                  │                  │                              │
│         └──────────────────┼──────────────────┘                              │
│                            ▼                                                 │
│                   ┌────────────────┐                                         │
│                   │   sshuttle     │  ← Intercepts TCP at network level     │
│                   │ (transparent)  │                                         │
│                   └────────┬───────┘                                         │
│                            │ SSH tunnel                                      │
└────────────────────────────┼────────────────────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                              Host (macOS)                                   │
│                                                                             │
│                   ┌────────────────┐                                        │
│                   │   SSH Server   │  ← Receives tunnel, runs Python        │
│                   │   + Python     │                                        │
│                   └────────┬───────┘                                        │
│                            │                                                │
│                            ▼                                                │
│                   ┌────────────────┐                                        │
│                   │    Internet    │  ← Full network access via host        │
│                   └────────────────┘                                        │
└────────────────────────────────────────────────────────────────────────────┘
```

### Components

1. **sshuttle** (in VM)
   - Intercepts all TCP traffic at the network level
   - Routes through SSH tunnel to host
   - Handles DNS transparently
   - Command: `sshuttle --dns -r user@host 0.0.0.0/0`

2. **SSH Server** (on Host)
   - Standard macOS Remote Login
   - No special configuration needed
   - Python required (included with macOS)

### Bootstrap Proxy (during --init)

During `--init`, sshuttle isn't installed yet. CAL uses a **bootstrap SOCKS proxy** (SSH `-D`) to install packages:

```
┌─────────────────────────────────────────────────────────────────┐
│  --init Flow                                                     │
│                                                                  │
│  1. Start VM                                                     │
│  2. Setup SSH keys                                               │
│  3. Start bootstrap SOCKS proxy (SSH -D 1080)                   │
│  4. Install packages with ALL_PROXY=socks5h://localhost:1080    │
│  5. Stop bootstrap proxy                                         │
│  6. Start sshuttle (now installed)                              │
└─────────────────────────────────────────────────────────────────┘
```

This solves the chicken-and-egg problem: we need network to install sshuttle, but SSH `-D` is built into SSH.

---

## VM Commands

Once inside the VM, you have these commands available:

### `proxy-start`
Start the transparent proxy manually.

```bash
proxy-start
```

**Output:**
```
Starting transparent proxy (sshuttle)...
✓ Transparent proxy started
```

### `proxy-stop`
Stop the transparent proxy.

```bash
proxy-stop
```

**Output:**
```
✓ Transparent proxy stopped
```

### `proxy-restart`
Restart the proxy (useful if connection drops).

```bash
proxy-restart
```

### `proxy-status`
Check proxy status and test connectivity.

```bash
proxy-status
```

**Output:**
```
Transparent Proxy Status:
  Mode: auto
  Host: admin@192.168.64.1

  Status: ✓ Running (PID: 1234)
  Connectivity: ✓ Working
```

### `proxy-log`
View proxy logs for troubleshooting.

```bash
proxy-log
```

---

## Troubleshooting

### Proxy won't start

**Check host SSH server:**
```bash
# On host Mac:
nc -z 192.168.64.1 22 && echo "✓ SSH ready" || echo "✗ SSH not accessible"

# If not accessible, enable Remote Login:
# System Settings → General → Sharing → Remote Login (ON)
```

**Check host has Python:**
```bash
# On host Mac:
python3 --version
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
proxy-log
# or:
tail -50 ~/.cal-proxy.log
```

### Proxy starts but connectivity fails

**Check sshuttle is running:**
```bash
# Inside VM:
pgrep -f sshuttle && echo "Running" || echo "Not running"
```

**Test direct connectivity:**
```bash
# Inside VM (with proxy stopped):
proxy-stop
curl -s --connect-timeout 5 -I https://github.com
```

**Check SSH connection:**
```bash
# Inside VM:
ssh -o ConnectTimeout=5 ${HOST_USER}@192.168.64.1 echo ok
```

### Auto-start not working

Check if auto-start is configured:
```bash
# Inside VM:
cat ~/.zshrc | grep "CAL Transparent Proxy"
# Should show function definitions

cat ~/.cal-proxy-config
# Should show proxy settings
```

**Re-run vm-setup.sh to fix:**
```bash
# Inside VM:
~/scripts/vm-setup.sh
```

---

## Security

### SSH Key Authentication

The VM's SSH key is added to the host's `~/.ssh/authorized_keys`. Unlike the old SOCKS approach, sshuttle requires full SSH access (to run Python on the server side).

**Mitigation:**
- The key is generated specifically for the VM
- Only accessible from the VM's local network (192.168.64.x)
- Host key verification is enabled (prevents MITM)

### Host Key Verification

The host's SSH key is pre-populated in the VM's `~/.ssh/known_hosts`:

```bash
# Inside VM:
ssh -o StrictHostKeyChecking=yes admin@192.168.64.1
# Uses strict checking - prevents MITM attacks
```

### Audit Trail

All proxy operations are logged:

```bash
# Host logs:
~/.cal-bootstrap.log

# VM logs:
~/.cal-proxy.log
```

---

## Comparison with Old SOCKS Approach

| Feature | Old (SOCKS + gost) | New (sshuttle) |
|---------|-------------------|----------------|
| App config needed | Yes (env vars) | No |
| Works with all apps | No (some ignore proxy) | Yes |
| DNS handling | Manual | Automatic |
| Setup complexity | Medium | Low |
| Host requirements | SSH only | SSH + Python |
| Extra packages in VM | gost | sshuttle |

---

## Advanced Configuration

### Custom Host Gateway

If your VM network uses a different gateway:

```bash
export HOST_GATEWAY=192.168.65.1
./scripts/cal-bootstrap --run --proxy on
```

### Persistent Configuration

Set in your shell profile (`.zshrc`):

```bash
export PROXY_MODE=on
export HOST_GATEWAY=192.168.64.1
```

---

## See Also

- [Bootstrap Documentation](bootstrap.md) - VM setup and management
- [Architecture Documentation](architecture.md) - Overall CAL design
- [ADR-001](adr/ADR-001-cal-isolation.md) - Original design decisions
