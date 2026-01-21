# CLI Reference

> Future CLI commands. Current bootstrap commands are in [Bootstrap Guide](bootstrap.md).

```bash
cal isolation <command>    # or: cal iso <command>
```

## Workspace

```bash
init <name> [--template <t>] [--env <e>...] [--agent <a>] [--cpu N] [--memory N] [--disk N]
start <name> [--headless] [--vnc]
stop <name> [--force]
destroy <name>
status <name>
ssh <name> [command]
```

## Git/GitHub

```bash
clone <name> --repo <owner/repo> [--branch <b>] [--new-branch <b>]
commit <name> --message <msg> [--push] [--pr]
pr <name> --title <t> [--body <b>] [--base <branch>]
auth login <name> [--token <t>]
auth status <name>
auth logout <name>
```

## Agent

```bash
run <name> [--prompt <text>] [--agent <a>] [--autonomous]
agent list <name>
agent install <name> <agent>
agent use <name> <agent>
agent update <name> <agent>
```

## Snapshots

```bash
snapshot create <name> --name <s>
snapshot restore <name> --name <s>
snapshot list <name>
snapshot delete <name> --name <s>
snapshot cleanup <name> [--auto-only] [--older-than <duration>]
rollback <name>                        # restore to session start
disk-usage <name>
```

## Environments

```bash
env list <name>
env install <name> <env> [--variant <v>]
env remove <name> <env>
env verify <name>
env info <env>
env update <name> <env>
```

## Artifacts

```bash
sync <name> [--watch]
watch <name> [--on-archive <cmd>]
logs <name> [--follow] [--tail <n>]
sign <name> --archive <path> --identity <id> --profile <path> [--output <path>]
cleanup [--all] [--cache] [--stopped]
```

## Future: CAL Core

```bash
cal                                    # Launch TUI
cal quick <name> --repo <r> --agent <a> --prompt <p>
cal list
cal status
```
