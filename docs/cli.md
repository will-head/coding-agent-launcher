# CLI Reference

> Planned CLI commands (Phase 1 in progress). Current bootstrap commands are in [Bootstrap Guide](bootstrap.md).
> See [ADR-002 § Phase 1 Readiness](adr/ADR-002-tart-vm-operational-guide.md) for command mapping from calf-bootstrap.

```bash
calf isolation <command>    # or: calf iso <command>
```

## Workspace

```bash
init [--proxy auto|on|off] [--yes]
start [--headless]
stop [--force]
restart
gui                                # VNC experimental mode (bidirectional clipboard)
destroy
status
ssh [command]
```

## Git/GitHub

```bash
clone --repo <owner/repo> [--branch <b>] [--new-branch <b>]
commit --message <msg> [--push] [--pr]
pr --title <t> [--body <b>] [--base <branch>]
auth login [--token <t>]
auth status
auth logout
```

## Agent

```bash
run [--prompt <text>] [--agent <a>] [--autonomous]
agent list
agent install <agent>
agent use <agent>
agent update <agent>
```

**Supported agents:** claude, agent (Cursor), opencode, ccs, codex

## Snapshots

```bash
snapshot create <name>
snapshot restore <name>
snapshot list
snapshot delete <names...> [--force]       # Multiple names, --force skips git check
snapshot cleanup [--auto-only] [--older-than <duration>]
rollback                                   # Restore to session start
disk-usage
```

## Environments

```bash
env list
env install <env> [--variant <v>]
env remove <env>
env verify
env info <env>
env update <env>
```

## Artifacts

```bash
sync [--watch]
watch [--on-archive <cmd>]
logs [--follow] [--tail <n>]
sign --archive <path> --identity <id> --profile <path> [--output <path>]
cleanup [--all] [--cache] [--stopped]
```

## Global Flags

```bash
--yes, -y                  # Skip confirmation prompts
--proxy auto|on|off        # Control proxy mode
--clean                    # Force full script deployment (skip checksum optimization)
```

## Future: CAL Core

```bash
calf                                    # Launch TUI
calf quick --repo <r> --agent <a> --prompt <p>
calf list
calf status
```

## Command Mapping (calf-bootstrap -> calf isolation)

| calf-bootstrap | calf isolation |
|---------------|---------------|
| `--init` | `init` |
| `--run` | `start` |
| `--stop` | `stop` |
| `--restart` | `restart` |
| `--gui` | `gui` |
| `--status` | `status` |
| `-S list` | `snapshot list` |
| `-S create <name>` | `snapshot create <name>` |
| `-S restore <name>` | `snapshot restore <name>` |
| `-S delete <names...>` | `snapshot delete <names...>` |
