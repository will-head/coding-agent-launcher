# Debug SOCKS Proxy Issues

Run these commands to diagnose what's failing:

## 1. Check if SOCKS tunnel is running IN the VM

```bash
# SSH into cal-dev
ssh admin@$(tart ip cal-dev)

# Inside VM - check if SOCKS tunnel is listening
lsof -i :1080
# Should show: ssh process listening on port 1080

# If nothing, tunnel isn't running
```

## 2. Test SOCKS tunnel manually

```bash
# Inside VM - test SOCKS proxy directly
curl --socks5-hostname localhost:1080 -I https://github.com
# Should return: HTTP/2 200

# If this works, SOCKS is fine and problem is with environment vars
```

## 3. Check environment variables

```bash
# Inside VM during vm-setup.sh
echo $ALL_PROXY      # Should be: socks5://localhost:1080
echo $HTTP_PROXY     # Should be: socks5://localhost:1080  
echo $HTTPS_PROXY    # Should be: socks5://localhost:1080

# Check if tools see the vars
env | grep -i proxy
```

## 4. Test if Homebrew respects proxy

```bash
# Inside VM - test brew with explicit proxy
ALL_PROXY=socks5://localhost:1080 brew update --verbose

# Look for error messages about connectivity
```

## 5. Check host SSH server

```bash
# On HOST Mac - check if SSH is accessible from VM network
nc -z 192.168.64.1 22 && echo "SSH server reachable"

# Check if Remote Login is enabled
sudo launchctl list | grep com.openssh.sshd
```

## 6. Check VM can reach host

```bash
# Inside VM - test connectivity to host
ping -c 3 192.168.64.1

# Try SSH from VM to host
ssh $(whoami)@192.168.64.1 'echo ok'
# Should work if keys are set up correctly
```

## 7. Check cal-bootstrap logs

```bash
# On host - check logs for errors
tail -100 ~/.cal-bootstrap.log | grep -i "error\|fail\|tunnel"
```

## Common Issues

### Issue: Tunnel not running in VM
**Symptom:** `lsof -i :1080` shows nothing

**Fix:** Restart tunnel manually:
```bash
# Inside VM
ssh -D 1080 -f -N $(whoami)@192.168.64.1
```

### Issue: Host SSH not accessible
**Symptom:** Cannot SSH from VM to host

**Fix:** Enable Remote Login on host:
```bash
# On host
sudo systemsetup -setremotelogin on
```

### Issue: Homebrew doesn't support socks5:// in HTTP_PROXY
**Symptom:** Tunnel works with curl --socks5 but not with HTTP_PROXY

**Solution:** Use ALL_PROXY only (not HTTP_PROXY/HTTPS_PROXY)

### Issue: Tunnel dies after setup
**Symptom:** Tunnel runs during init but not later

**Fix:** Check if SSH connection stays alive
```bash
# Inside VM - check SSH processes
ps aux | grep "ssh -D"
```

## What to report back

Please run the diagnostic commands above and tell me:
1. Is the SOCKS tunnel actually running? (`lsof -i :1080`)
2. Does manual curl with --socks5 work?
3. What error does `brew update` show?
4. Can the VM SSH to the host?
5. Any errors in ~/.cal-bootstrap.log?

This will help me identify the exact problem.
