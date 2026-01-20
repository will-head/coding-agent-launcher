# VM Detection for Coding Agents

CAL provides a simple, reliable method for coding agents to detect if they're running inside a CAL VM. This enables agents to adjust their behavior based on the execution environment.

## Detection Methods

### 1. Environment Variable (Quick Check)

The simplest method is to check the `CAL_VM` environment variable:

```bash
# In shell
if [ "$CAL_VM" = "true" ]; then
    echo "Running in CAL VM"
fi

# In Python
import os
if os.getenv('CAL_VM') == 'true':
    print("Running in CAL VM")

# In Node.js
if (process.env.CAL_VM === 'true') {
    console.log('Running in CAL VM');
}

# In Go
import "os"
if os.Getenv("CAL_VM") == "true" {
    fmt.Println("Running in CAL VM")
}
```

### 2. Info File (Detailed Information)

For more detailed VM information, read the `~/.cal-vm-info` file:

```bash
# Check if file exists
if [ -f ~/.cal-vm-info ]; then
    # Read VM info
    source ~/.cal-vm-info
    echo "VM Name: $CAL_VM_NAME"
    echo "Created: $CAL_VM_CREATED"
    echo "Version: $CAL_VERSION"
fi
```

**Info File Format:**
```bash
# CAL VM Information
CAL_VM=true
CAL_VM_NAME=cal-dev
CAL_VM_CREATED=2026-01-20T12:34:56Z
CAL_VERSION=0.1.0
```

### 3. Helper Functions (Shell)

CAL provides convenience functions in the shell:

```bash
# Check if running in VM (returns 0 if true, 1 if false)
is-cal-vm && echo "In VM"

# Display full VM info
cal-vm-info
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

if [ "$CAL_VM" != "true" ]; then
    echo "⚠️  WARNING: Not running in CAL VM!"
    echo "This script performs destructive operations."
    echo "It's recommended to run inside a CAL VM for safety."
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
if os.getenv('CAL_VM') == 'true':
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
const isCALVM = process.env.CAL_VM === 'true';

function log(message) {
    const prefix = isCALVM ? '[CAL-VM]' : '[HOST]';
    console.log(`${prefix} ${message}`);
}

log('Starting agent task...');
// [CAL-VM] Starting agent task...
```

## Implementation Details

### How It Works

1. During VM setup, `vm-setup.sh` creates `~/.cal-vm-info` with VM metadata
2. The `CAL_VM=true` environment variable is added to `~/.zshrc`
3. Helper functions are defined in `~/.zshrc` for easy detection
4. All new shell sessions automatically have `CAL_VM` set

### Version Management

The `CAL_VERSION` field in `~/.cal-vm-info` follows semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR** - Breaking changes to VM detection API or structure
- **MINOR** - New features or enhancements (backward compatible)
- **PATCH** - Bug fixes and minor improvements

**Current version:** 0.1.0

**Updating the version:**
To update the CAL version, edit `scripts/vm-setup.sh` and change the `CAL_VERSION` value in the `.cal-vm-info` creation section. The version is written to VMs during initial setup or when running `vm-setup.sh`.

### Files Modified

- `~/.cal-vm-info` - VM metadata file (created during setup)
- `~/.zshrc` - Shell configuration with CAL_VM export and helper functions

### Persistence

- VM detection persists across:
  - Shell sessions
  - SSH reconnections
  - VM reboots
  - Snapshots and restores

### Reliability

The detection is highly reliable:
- **File-based** - `~/.cal-vm-info` won't exist on non-VM systems
- **Environment variable** - Set on every shell startup
- **Non-intrusive** - Doesn't affect normal operations
- **Fail-safe** - If file or variable missing, defaults to "not a VM"

## Claude Code Integration

Claude Code can detect VM environment automatically:

```bash
# In CLAUDE.md or agent instructions
if [ "$CAL_VM" = "true" ]; then
    echo "Running in isolated CAL VM - safe to perform operations"
else
    echo "Running on host - extra caution advised"
fi
```

## Testing

Test VM detection after setup:

```bash
# SSH into VM
./scripts/cal-bootstrap --run

# In VM, test detection
echo $CAL_VM              # Should print: true
is-cal-vm && echo "VM"    # Should print: VM
cal-vm-info               # Should display VM info
cat ~/.cal-vm-info        # Should show VM metadata
```

## Troubleshooting

**CAL_VM not set:**
- Restart shell: `exec zsh`
- Re-run vm-setup: `~/scripts/vm-setup.sh`

**Info file missing:**
- Re-run vm-setup to recreate: `~/scripts/vm-setup.sh`

**Helper functions not found:**
- Source zshrc: `source ~/.zshrc`
- Check if functions added: `grep -A 5 'is-cal-vm' ~/.zshrc`
