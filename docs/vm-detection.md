# VM Detection for Coding Agents

> See also: [ADR-002](adr/ADR-002-tart-vm-operational-guide.md) § VM Detection

CALF provides a simple, reliable method for coding agents to detect if they're running inside a CALF VM. This enables agents to adjust their behavior based on the execution environment.

## Detection Methods

### 1. Environment Variable (Quick Check)

The simplest method is to check the `CALF_VM` environment variable:

```bash
# In shell
if [ "$CALF_VM" = "true" ]; then
    echo "Running in CALF VM"
fi

# In Python
import os
if os.getenv('CALF_VM') == 'true':
    print("Running in CALF VM")

# In Node.js
if (process.env.CALF_VM === 'true') {
    console.log('Running in CALF VM');
}

# In Go
import "os"
if os.Getenv("CALF_VM") == "true" {
    fmt.Println("Running in CALF VM")
}
```

### 2. Info File (Detailed Information)

For more detailed VM information, read the `~/.calf-vm-info` file:

```bash
# Check if file exists
if [ -f ~/.calf-vm-info ]; then
    # Read VM info
    source ~/.calf-vm-info
    echo "VM Name: $CALF_VM_NAME"
    echo "Created: $CALF_VM_CREATED"
    echo "Version: $CALF_VERSION"
fi
```

**Info File Format:**
```bash
# CALF VM Information
CALF_VM=true
CALF_VM_NAME=calf-dev
CALF_VM_CREATED=2026-01-20T12:34:56Z
CALF_VERSION=0.1.0
```

### 3. Helper Functions (Shell)

CALF provides convenience functions in the shell:

```bash
# Check if running in VM (returns 0 if true, 1 if false)
is-calf-vm && echo "In VM"

# Display full VM info
calf-vm-info
```

## Use Cases

### Adjust Agent Behavior

Coding agents can use VM detection to:

1. **Enable safety features** - More cautious when running outside VM
2. **Adjust resource usage** - Different limits for VM vs host
3. **Change output format** - VM-specific logging or reporting
4. **Skip certain operations** - Some operations only make sense in VM

### Example: Safety Check in Agent

```bash
#!/bin/bash
# Agent script that performs destructive operations

if [ "$CALF_VM" != "true" ]; then
    echo "⚠️  WARNING: Not running in CALF VM!"
    echo "This script performs destructive operations."
    echo "It's recommended to run inside a CALF VM for safety."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Proceed with operations...
```

### Example: Resource Limits

```python
import os

# Adjust resource limits based on environment
if os.getenv('CALF_VM') == 'true':
    # VM environment - use conservative limits
    MAX_THREADS = 4
    MAX_MEMORY_MB = 4096
else:
    # Host environment - can use more resources
    MAX_THREADS = 8
    MAX_MEMORY_MB = 8192

print(f"Max threads: {MAX_THREADS}")
print(f"Max memory: {MAX_MEMORY_MB}MB")
```

### Example: Logging and Reporting

```javascript
const isCALFVM = process.env.CALF_VM === 'true';

function log(message) {
    const prefix = isCALFVM ? '[CALF-VM]' : '[HOST]';
    console.log(`${prefix} ${message}`);
}

log('Starting agent task...');
// [CALF-VM] Starting agent task...
```

## Implementation Details

### How It Works

1. During VM setup, `vm-setup.sh` creates `~/.calf-vm-info` with VM metadata
2. The `CALF_VM=true` environment variable is added to `~/.zshrc`
3. Helper functions are defined in `~/.zshrc` for easy detection
4. All new shell sessions automatically have `CALF_VM` set

### Version Management

The `CALF_VERSION` field in `~/.calf-vm-info` follows semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR** - Breaking changes to VM detection API or structure
- **MINOR** - New features or enhancements (backward compatible)
- **PATCH** - Bug fixes and minor improvements

**Current version:** 0.1.0

**Updating the version:**
To update the CALF version, edit `scripts/vm-setup.sh` and change the `CALF_VERSION` value in the `.calf-vm-info` creation section. The version is written to VMs during initial setup or when running `vm-setup.sh`.

### Files Modified

- `~/.calf-vm-info` - VM metadata file (created during setup)
- `~/.zshrc` - Shell configuration with CALF_VM export and helper functions

### Persistence

- VM detection persists across:
  - Shell sessions
  - SSH reconnections
  - VM reboots
  - Snapshots and restores

### Reliability

The detection is highly reliable:
- **File-based** - `~/.calf-vm-info` won't exist on non-VM systems
- **Environment variable** - Set on every shell startup
- **Non-intrusive** - Doesn't affect normal operations
- **Fail-safe** - If file or variable missing, defaults to "not a VM"

## Claude Code Integration

Claude Code can detect VM environment automatically:

```bash
# In CLAUDE.md or agent instructions
if [ "$CALF_VM" = "true" ]; then
    echo "Running in isolated CALF VM - safe to perform operations"
else
    echo "Running on host - extra caution advised"
fi
```

## Testing

Test VM detection after setup:

```bash
# SSH into VM
./scripts/calf-bootstrap --run

# In VM, test detection
echo $CALF_VM              # Should print: true
is-calf-vm && echo "VM"    # Should print: VM
calf-vm-info               # Should display VM info
cat ~/.calf-vm-info        # Should show VM metadata
```

## Troubleshooting

**CALF_VM not set:**
- Restart shell: `exec zsh`
- Re-run vm-setup: `~/scripts/vm-setup.sh`

**Info file missing:**
- Re-run vm-setup to recreate: `~/scripts/vm-setup.sh`

**Helper functions not found:**
- Source zshrc: `source ~/.zshrc`
- Check if functions added: `grep -A 5 'is-calf-vm' ~/.zshrc`
