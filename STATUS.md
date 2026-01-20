# Transparent Proxy Migration Status

## Goal
Convert `scripts/cal-bootstrap` and `scripts/vm-setup.sh` from SOCKS+gost proxy to sshuttle transparent proxy.

## Status: COMPLETE (with bootstrap proxy solution)

All changes have been implemented, including a bootstrap proxy solution for `--init`.

## Changes Made

### `scripts/cal-bootstrap`
1. ✅ Changed `SOCKS_MODE` → `PROXY_MODE` and removed `SOCKS_PORT`/`HTTP_PROXY_PORT`
2. ✅ Added `check_host_python()` function (sshuttle needs Python on host)
3. ✅ Updated `setup_vm_ssh_key()` - removed restricted SSH key (sshuttle needs full SSH)
4. ✅ Replaced `start_http_proxy_bridge()` and `start_socks_tunnel()` with `start_transparent_proxy()`
5. ✅ Replaced `show_socks_cow()` with `show_proxy_cow()` (tests via normal curl, not --socks5)
6. ✅ Replaced `should_enable_socks()` with `should_enable_proxy()`
7. ✅ Updated `do_init()` Step 5 and Step 7.5 to use new functions
8. ✅ Updated `do_run()` to use `should_enable_proxy()` and `start_transparent_proxy()`
9. ✅ Updated `do_restart()` to use new proxy functions
10. ✅ Updated argument parsing: `--socks|--proxy` now sets `PROXY_MODE`
11. ✅ Updated help text to reflect `--proxy` option

### `scripts/vm-setup.sh`
1. ✅ Replaced SOCKS settings with transparent proxy settings (removed ports)
2. ✅ Removed all HTTP_PROXY/ALL_PROXY environment variable setup
3. ✅ Removed gost installation and HTTP bridge setup
4. ✅ Added `sshuttle` to brew packages
5. ✅ Replaced gost verification with sshuttle verification
6. ✅ Replaced SOCKS tunnel functions in .zshrc with sshuttle equivalents:
   - `proxy-start` → starts sshuttle
   - `proxy-stop` → stops sshuttle
   - `proxy-restart` → restarts sshuttle
   - `proxy-status` → shows proxy status
   - `proxy-log` → views proxy logs

### `scripts/vm-auth.sh`
1. ✅ Updated network check to use transparent proxy
2. ✅ Removed SOCKS proxy configuration and env vars
3. ✅ Updated proxy command hints

## Key Technical Details

### Bootstrap Proxy (during --init)
- **Problem**: sshuttle needs to be installed, but we need network to install it
- **Solution**: Use SSH `-D` SOCKS tunnel (built into SSH, no packages needed)
- **Command**: `ssh -D 1080 -f -N user@host` (started from VM)
- **Env vars**: `ALL_PROXY=socks5h://localhost:1080` passed to vm-setup.sh

### Transparent Proxy (after --init)
- **sshuttle command**: `sshuttle --dns -r user@192.168.64.1 0.0.0.0/0 -x 192.168.64.0/24`
- **Host requirements**: SSH server + Python3 (macOS has both)
- **VM requirements**: sshuttle via Homebrew
- **No env vars needed**: Apps work automatically (transparent at network level)

### Flow
1. `--init --proxy on`: Uses bootstrap SOCKS → installs sshuttle → switches to sshuttle
2. `--init` (no proxy): Direct connection for installation
3. `--run/--restart --proxy on`: Uses sshuttle directly (already installed)

## Files Modified

- `/Users/willhead/code/will-head/coding-agent-launcher/scripts/cal-bootstrap`
- `/Users/willhead/code/will-head/coding-agent-launcher/scripts/vm-setup.sh`
- `/Users/willhead/code/will-head/coding-agent-launcher/scripts/vm-auth.sh`

## Next Steps

1. ~~Test the changes by running `./scripts/cal-bootstrap --init` on a fresh VM~~ ✅ Done
2. ~~Verify sshuttle transparent proxy works correctly~~ ✅ Done (both --proxy on and off work)
3. ~~Update documentation~~ ✅ Done
   - Created `docs/proxy.md` (new transparent proxy docs)
   - Updated `docs/bootstrap.md` (--socks → --proxy, updated workflow)
   - Updated `docs/architecture.md` (transparent proxy description)
   - Deleted `docs/socks-proxy.md` (replaced by proxy.md)
4. Commit changes after testing
