# Tart VM Storage Investigation

**Date:** 2026-01-20
**Issue:** VMs showing 28-31GB each instead of expected CoW (copy-on-write) space savings

## Summary

Tart VMs are correctly using APFS copy-on-write cloning, but the space savings break down naturally as VMs diverge through normal use. The observed 170GB total disk usage for 6 VMs is expected behavior, not a bug.

## Current VM Disk Usage

```
VM Name                     Actual Size    Virtual Disk
----------------------------------------------------------
cal-clean                   30 GB          75 GB
cal-dev                     28 GB          75 GB
cal-dev-cal-dev-init-02     30 GB          75 GB
cal-dev-multi-test          29 GB          75 GB
cal-dev-test-restore        30 GB          75 GB
cal-init                    29 GB          75 GB
----------------------------------------------------------
Total                       170 GB
```

## How Tart Cloning Works

### Initial Clone Behavior

According to Tart documentation:

> "Due to copy-on-write magic in Apple File System, a cloned VM won't actually claim all the space right away. Only changes to a cloned disk will be written and claim new space. This also speeds up clones enormously."
>
> — `tart clone --help`

When you run `tart clone`, it uses APFS's copy-on-write capabilities:
- Initial clone is nearly instant
- Cloned VM initially shares data blocks with the source VM
- Only metadata is duplicated at creation time

### Why CoW Sharing Breaks Down

APFS clones work by sharing storage blocks until modifications occur. From [APFS Files and clones](https://eclecticlight.co/2024/03/20/apfs-files-and-clones/):

> "As the two files are changed by editing, they start to drift apart... the two cloned files may cease to share any common data, and become separate."

In the context of VM disk images, CoW sharing breaks down because:

1. **Active VM Use** - Every time a VM runs, it modifies its disk:
   - Installing packages (brew, agents, tools)
   - Creating files and directories
   - System logs and cache updates
   - Application data changes

2. **Setup Scripts** - The `cal-bootstrap --init` process runs extensive setup:
   - `vm-setup.sh` - Installs Homebrew, coding agents, tools
   - `vm-auth.sh` - Configures authentication
   - Creates `~/scripts/` directory
   - Modifies shell configuration (`.zshrc`)

3. **Different Configurations** - Each VM serves different purposes:
   - `cal-clean` - Base image, minimal modifications
   - `cal-dev` - Active development, most changes
   - `cal-init` - Post-setup snapshot
   - Snapshot VMs - Captured at different points in time

## Why 28-30GB Per VM is Expected

### Base Image Size
The macOS Sequoia base image from `ghcr.io/cirruslabs/macos-sequoia-base:latest` is approximately 25-30GB. This includes:
- macOS Sequoia operating system
- System files and frameworks
- Default applications

### Additional Space Usage
Each VM adds:
- Homebrew and packages (~2-3GB)
- Coding agents (Claude Code, opencode, Cursor) (~500MB-1GB)
- Go toolchain (~500MB)
- Development tools
- User data and configurations

### Natural Growth
- System logs and caches accumulate over time
- Temporary files from installations
- Each VM's unique history of file modifications

## Storage Efficiency Notes

### What IS Working
- **Sparse Files** - VM disk images are thin-provisioned (show as 75GB but use ~30GB)
- **OCI Cache Sharing** - Base images in `~/.tart/cache/OCIs/` (~30GB) are shared across pulls
- **Initial Clone Speed** - CoW makes cloning fast even if sharing doesn't persist

### What's NOT Working (By Design)
- **Long-term CoW Sharing** - Can't persist when VMs actively modify their disks
- **Space Deduplication** - APFS doesn't deduplicate after files diverge

## Verification Challenges

Confirming APFS clone relationships is technically difficult. From [How can you tell whether a file has been 'cloned' in APFS?](https://eclecticlight.co/2021/04/02/how-can-you-tell-whether-a-file-has-been-cloned-in-apfs/):

> "There's no practical distinction between the 'original' and its clones once they've been made... determining whether a file has been truly copied or cloned is extremely difficult using standard tools."

Standard tools like `du`, `ls`, and `stat` don't expose APFS clone metadata or shared block information.

## Recommendations

### Current Setup is Optimal
1. **Keep the Base Images** - Don't delete `cal-clean` or cached images. Tart docs warn:
   > "It's not recommended to delete the base image as it won't save disk space due to copy-on-write file system on macOS."

2. **Accept the Space Usage** - 170GB for 6 fully-functional development VMs is reasonable:
   - Average: 28GB per VM
   - Comparable to native macOS installations
   - Includes full OS + development environment

### Space Management Options
1. **Delete Unused Snapshots** - Remove snapshot VMs you don't need:
   ```bash
   ./scripts/cal-bootstrap --snapshot delete <name>
   ```

2. **Use Fewer Concurrent VMs** - Keep only:
   - `cal-clean` (base image)
   - `cal-dev` (active development)
   - `cal-init` (optional: known-good state)

3. **Leverage Tart's Auto-Pruning** - Tart automatically removes least-recently-used cached images when disk space is low

### If Space is Constrained
- Monitor with: `du -sh ~/.tart/vms/*`
- Target: Keep 2-3 VMs instead of 6 (~90GB total)
- Restore from `cal-clean` when needed (fast with CoW on initial clone)

## Conclusion

The observed disk usage is **correct and expected behavior**:
- Tart IS using APFS copy-on-write for initial clones
- Space savings ARE realized initially (fast cloning)
- Sharing naturally breaks down as VMs are used and modified
- 28-31GB per VM is appropriate for a full macOS development environment
- Total 170GB for 6 VMs is reasonable given their intended use

The "snapshot" terminology in `cal-bootstrap --snapshot list` refers to functional checkpoints for rollback, not storage-efficient snapshots. They are full VM clones that start with CoW but diverge over time.

## References

- [Tart Virtualization FAQ](https://tart.run/faq/)
- [Tart GitHub Repository](https://github.com/cirruslabs/tart)
- [APFS Files and clones – The Eclectic Light Company](https://eclecticlight.co/2024/03/20/apfs-files-and-clones/)
- [How can you tell whether a file has been 'cloned' in APFS?](https://eclecticlight.co/2021/04/02/how-can-you-tell-whether-a-file-has-been-cloned-in-apfs/)
- [Copy-on-write on APFS – Wade Tregaskis](https://wadetregaskis.com/copy-on-write-on-apfs/)
- [APFS in Detail: Space Efficiency and Clones](http://dtrace.org/blogs/ahl/2016/06/19/apfs-part3/)
