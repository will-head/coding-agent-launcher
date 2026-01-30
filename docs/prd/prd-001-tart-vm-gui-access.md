# PRD-001: GUI Access to macOS Tart Virtual Machines

## Status
Proposed

## Overview
We need reliable GUI access to macOS Tart VMs for the coding-agent-launcher project to enable safe execution of AI coding tools (Claude Code, Cursor, etc.) in an isolated environment. The primary use case is running these tools with full GUI capabilities for development work while maintaining security isolation from the host system.

Key requirements:
- Reliable GUI access to macOS VM
- Support for native macOS applications (Xcode, VS Code, etc.)
- Minimal latency for interactive development
- Compatible with AI coding agent workflows

### Evaluated Options

#### 1. VNC (Apple Remote Desktop/Screen Sharing)
**Pros:**
- Built into macOS (System Settings → Sharing → Screen Sharing)
- Native Apple protocol with optimizations
- Works with standard macOS Screen Sharing client

**Cons:**
- Known reliability issues with Tart VMs as reported by user
- Experimental VNC support in Tart (`--vnc-experimental` flag)
- Performance can be inconsistent

#### 2. RDP (Remote Desktop Protocol)
**Pros:**
- Excellent performance and reliability on Windows/Linux
- Mature protocol

**Cons:**
- No native macOS RDP server support
- Third-party solutions (xrdp ports) are experimental and unreliable
- Not commonly used in macOS ecosystem
- Would require significant setup overhead

#### 3. SSH with X11 Forwarding
**Pros:**
- Reliable SSH connection
- Works for X11 applications

**Cons:**
- macOS apps are native Cocoa/AppKit, not X11
- Requires XQuartz installation
- Won't work for Xcode, VS Code, or most development tools
- Not a viable solution for macOS GUI apps

## Proposed Solution
**Use VS Code Remote-SSH with Tart Guest Agent for headless operation, supplemented by native Tart console for GUI when needed.**

This hybrid approach provides the best balance of reliability and functionality:

### Primary Method: VS Code Remote-SSH
1. Install Tart Guest Agent in the VM for enhanced functionality
2. Run VM with bridged networking: `tart run <vm-name> --net-bridged=en0`
3. Connect via VS Code Remote-SSH extension
4. Execute development workflows through VS Code's integrated terminal

### Secondary Method: Native Tart Console
When full GUI access is required:
- Use `tart run <vm-name>` without remote access flags
- Tart displays the VM directly through its native console
- Most reliable method since it's not remote access
- Use for tasks requiring native macOS GUI interaction

### Supporting Tools

#### Tart Guest Agent
Install in VM for enhanced capabilities:
```bash
brew install cirruslabs/cli/tart-guest-agent
```

Features provided:
- `tart exec` - Execute commands without SSH/networking
- Clipboard sharing between host and guest
- Automatic disk resizing

#### VS Code Remote-SSH Setup
```bash
# SSH config (~/.ssh/config)
Host tart-dev
  User admin
  HostName <VM-IP>
  IdentityFile ~/.ssh/id_rsa
  StrictHostKeyChecking no
```

Connection from VS Code:
- Install "Remote - SSH" extension
- Connect to host via Command Palette: "Remote-SSH: Connect to Host"
- Select tart-dev or enter admin@<VM-IP>

## Trade-offs

### Benefits
- VS Code Remote-SSH provides professional-grade remote development experience
- Full IntelliSense, debugging, and extension support in VS Code
- Tart Guest Agent enables command execution without networking dependencies
- Native console available as reliable fallback for full GUI needs
- Workflow aligns with modern remote development practices
- Can run AI coding tools in VM terminal via Remote-SSH
- Clipboard sharing between host and VM with guest agent

### Limitations
- Two different access methods needed (Remote-SSH + native console)
- Requires VM to have SSH enabled and configured
- Bridged networking exposes VM to local network (can use NAT if preferred, with port forwarding)
- Learning curve for developers unfamiliar with VS Code Remote-SSH
- Full GUI experience requires switching to native console

### Considerations
- Some AI coding tools may need to be run in terminal rather than as GUI apps
- Documentation needed for team on when to use each access method
- Network configuration flexibility (bridged vs NAT) allows security/convenience tradeoff

## Implementation Notes

### VM Setup Checklist
1. Create/clone Tart VM
2. Install Tart Guest Agent
3. Enable SSH (Remote Login in System Settings → Sharing)
4. Configure bridged networking or NAT with port forwarding
5. Set up SSH keys for passwordless access
6. Configure VS Code Remote-SSH

### When to Use Each Method
- **VS Code Remote-SSH**: Day-to-day development, running AI coding tools, terminal work
- **Native Tart Console**: Installing software, system configuration, tasks requiring native macOS GUI

### Example Workflow
```bash
# Start VM with bridged networking
tart run my-dev-vm --net-bridged=en0

# Get VM IP
tart ip my-dev-vm

# Connect via VS Code Remote-SSH
code --folder-uri "vscode-remote://ssh-remote+tart-dev/~/projects"

# Execute commands via guest agent (no SSH needed)
tart exec my-dev-vm open /Applications/Safari.app
```

## References
- [Snowflake Red Team: macOS CI/CD with Tart](https://medium.com/snowflake/macos-ci-cd-with-tart-d3c0e511f3c9) - Demonstrates VS Code + Tart integration
- [Tart Guest Agent Documentation](https://tart.run/blog/2025/06/01/bridging-the-gaps-with-the-tart-guest-agent/)
- [VS Code Remote-SSH Documentation](https://code.visualstudio.com/docs/remote/ssh)
- [Tart Official Documentation](https://tart.run/)

## Alternatives Considered But Rejected
- **NoMachine (NX protocol)**: Additional software overhead, not necessary given VS Code solution
- **Pure VNC/Screen Sharing**: Unreliable with Tart as reported
- **RDP via third-party**: Immature on macOS, unreliable
- **SSH + X11**: Incompatible with native macOS applications
