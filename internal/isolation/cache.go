// Package isolation provides VM isolation and management for CAL.
package isolation

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// CacheManager manages package download caches for CAL VMs.
type CacheManager struct {
	homeDir      string
	cacheBaseDir string
}

// CacheInfo contains information about a cache.
type CacheInfo struct {
	// Path is the filesystem path to the cache directory.
	Path string
	// Size is the total size of the cache in bytes.
	Size int64
	// Available indicates whether the cache is configured and ready to use.
	Available bool
	// LastAccess is the last modification time of the cache directory.
	LastAccess time.Time
}

const (
	// homebrewCacheDir is the directory name for Homebrew cache under .cal-cache.
	homebrewCacheDir = "homebrew"
	// homebrewDownloadsDir is the subdirectory for Homebrew package downloads.
	homebrewDownloadsDir = "downloads"
	// homebrewCaskDir is the subdirectory for Homebrew Cask downloads.
	homebrewCaskDir = "Cask"
	// npmCacheDir is the directory name for npm cache under .cal-cache.
	npmCacheDir = "npm"
	// goCacheDir is the directory name for Go cache under .cal-cache.
	goCacheDir = "go"
	// gitCacheDir is the directory name for git cache under .cal-cache.
	gitCacheDir = "git"
	// sharedCacheMount is the Tart directory mount specification for cache sharing.
	sharedCacheMount = "cal-cache:~/.cal-cache"
)

// getDiskUsage returns the disk usage in bytes for a path using du -sk.
// Returns 0 if path doesn't exist or on error.
func getDiskUsage(path string) int64 {
	cmd := exec.Command("du", "-sk", path)
	output, err := cmd.Output()
	if err != nil {
		return 0
	}

	parts := strings.Fields(string(output))
	if len(parts) == 0 {
		return 0
	}

	size, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return 0
	}

	// du -sk returns size in kilobytes, convert to bytes
	return size * 1024
}

// NewCacheManager creates a new CacheManager with default paths.
func NewCacheManager() *CacheManager {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		homeDir = ""
	}
	return &CacheManager{
		homeDir:      homeDir,
		cacheBaseDir: filepath.Join(homeDir, ".cal-cache"),
	}
}

// getHomebrewCachePath returns the host path for Homebrew cache.
func (c *CacheManager) getHomebrewCachePath() string {
	return filepath.Join(c.cacheBaseDir, homebrewCacheDir)
}

// GetSharedCacheMount returns the Tart directory mount specification for cache sharing.
func (c *CacheManager) GetSharedCacheMount() string {
	return sharedCacheMount
}

// GetHomebrewCacheHostPath returns the host path for Homebrew cache mounting.
func (c *CacheManager) GetHomebrewCacheHostPath() string {
	return fmt.Sprintf("cal-cache:%s", c.getHomebrewCachePath())
}

// getNpmCachePath returns the host path for npm cache.
func (c *CacheManager) getNpmCachePath() string {
	return filepath.Join(c.cacheBaseDir, npmCacheDir)
}

// getGoCachePath returns the host path for Go cache.
func (c *CacheManager) getGoCachePath() string {
	return filepath.Join(c.cacheBaseDir, goCacheDir)
}

// SetupHomebrewCache sets up the Homebrew cache directory on the host.
// Creates the cache directory structure with graceful degradation on errors.
func (c *CacheManager) SetupHomebrewCache() error {
	if c.homeDir == "" {
		fmt.Fprintf(os.Stderr, "Warning: home directory not available, continuing without Homebrew cache\n")
		return nil
	}

	hostCacheDir := c.getHomebrewCachePath()

	if err := os.MkdirAll(hostCacheDir, 0755); err != nil {
		return fmt.Errorf("failed to create host cache directory: %w", err)
	}

	downloadsDir := filepath.Join(hostCacheDir, homebrewDownloadsDir)
	if err := os.MkdirAll(downloadsDir, 0755); err != nil {
		return fmt.Errorf("failed to create downloads directory: %w", err)
	}

	caskDir := filepath.Join(hostCacheDir, homebrewCaskDir)
	if err := os.MkdirAll(caskDir, 0755); err != nil {
		return fmt.Errorf("failed to create Cask directory: %w", err)
	}

	return nil
}

// SetupVMHomebrewCache returns shell commands to set up Homebrew cache in the VM.
// The commands create a symlink from the VM home directory to the shared cache volume
// and configure the HOMEBREW_CACHE environment variable.
// Returns nil if host cache is not available.
func (c *CacheManager) SetupVMHomebrewCache() []string {
	if c.homeDir == "" {
		return nil
	}

	hostCacheDir := c.getHomebrewCachePath()
	if _, err := os.Stat(hostCacheDir); os.IsNotExist(err) {
		return nil
	}

	vmCacheDir := "~/.cal-cache/homebrew"
	sharedCachePath := "\"/Volumes/My Shared Files/cal-cache/homebrew\""

	commands := []string{
		"mkdir -p ~/.cal-cache",
		fmt.Sprintf("ln -sf %s %s", sharedCachePath, vmCacheDir),
		fmt.Sprintf("touch ~/.zshrc && grep -q 'HOMEBREW_CACHE' ~/.zshrc || echo 'export HOMEBREW_CACHE=%s' >> ~/.zshrc", vmCacheDir),
	}

	return commands
}

// GetHomebrewCacheInfo returns information about the Homebrew cache.
func (c *CacheManager) GetHomebrewCacheInfo() (*CacheInfo, error) {
	cachePath := c.getHomebrewCachePath()

	info, err := os.Stat(cachePath)
	if err != nil {
		if os.IsNotExist(err) {
			return &CacheInfo{
				Path:      cachePath,
				Size:      0,
				Available: false,
			}, nil
		}
		return nil, fmt.Errorf("failed to stat cache directory: %w", err)
	}

	size := getDiskUsage(cachePath)

	return &CacheInfo{
		Path:       cachePath,
		Size:       size,
		Available:  true,
		LastAccess: info.ModTime(),
	}, nil
}

// SetupNpmCache sets up the npm cache directory on the host.
// Creates the cache directory with graceful degradation on errors.
func (c *CacheManager) SetupNpmCache() error {
	if c.homeDir == "" {
		fmt.Fprintf(os.Stderr, "Warning: home directory not available, continuing without npm cache\n")
		return nil
	}

	hostCacheDir := c.getNpmCachePath()

	if err := os.MkdirAll(hostCacheDir, 0755); err != nil {
		return fmt.Errorf("failed to create host npm cache directory: %w", err)
	}

	return nil
}

// SetupVMNpmCache returns shell commands to set up npm cache in the VM.
// The commands create a symlink from the VM home directory to the shared cache volume
// and configure the npm cache directory.
// Returns nil if host cache is not available.
func (c *CacheManager) SetupVMNpmCache() []string {
	if c.homeDir == "" {
		return nil
	}

	hostCacheDir := c.getNpmCachePath()
	if _, err := os.Stat(hostCacheDir); os.IsNotExist(err) {
		return nil
	}

	vmCacheDir := "~/.cal-cache/npm"
	sharedCachePath := "\"/Volumes/My Shared Files/cal-cache/npm\""

	commands := []string{
		"mkdir -p ~/.cal-cache",
		fmt.Sprintf("ln -sf %s %s", sharedCachePath, vmCacheDir),
		fmt.Sprintf("npm config set cache %s", vmCacheDir),
	}

	return commands
}

// GetNpmCacheInfo returns information about the npm cache.
func (c *CacheManager) GetNpmCacheInfo() (*CacheInfo, error) {
	cachePath := c.getNpmCachePath()

	info, err := os.Stat(cachePath)
	if err != nil {
		if os.IsNotExist(err) {
			return &CacheInfo{
				Path:      cachePath,
				Size:      0,
				Available: false,
			}, nil
		}
		return nil, fmt.Errorf("failed to stat npm cache directory: %w", err)
	}

	size := getDiskUsage(cachePath)

	return &CacheInfo{
		Path:       cachePath,
		Size:       size,
		Available:  true,
		LastAccess: info.ModTime(),
	}, nil
}

// SetupGoCache sets up the Go cache directory on the host.
// Creates the cache directory structure with graceful degradation on errors.
func (c *CacheManager) SetupGoCache() error {
	if c.homeDir == "" {
		fmt.Fprintf(os.Stderr, "Warning: home directory not available, continuing without Go cache\n")
		return nil
	}

	hostCacheDir := c.getGoCachePath()

	if err := os.MkdirAll(hostCacheDir, 0755); err != nil {
		return fmt.Errorf("failed to create host Go cache directory: %w", err)
	}

	pkgModDir := filepath.Join(hostCacheDir, "pkg", "mod")
	if err := os.MkdirAll(pkgModDir, 0755); err != nil {
		return fmt.Errorf("failed to create pkg/mod directory: %w", err)
	}

	pkgSumdbDir := filepath.Join(hostCacheDir, "pkg", "sumdb")
	if err := os.MkdirAll(pkgSumdbDir, 0755); err != nil {
		return fmt.Errorf("failed to create pkg/sumdb directory: %w", err)
	}

	return nil
}

// SetupVMGoCache returns shell commands to set up Go cache in the VM.
// The commands create a symlink from the VM home directory to the shared cache volume
// and configure the GOMODCACHE environment variable.
// Returns nil if host cache is not available.
func (c *CacheManager) SetupVMGoCache() []string {
	if c.homeDir == "" {
		return nil
	}

	hostCacheDir := c.getGoCachePath()
	if _, err := os.Stat(hostCacheDir); os.IsNotExist(err) {
		return nil
	}

	vmCacheDir := "~/.cal-cache/go"
	sharedCachePath := "\"/Volumes/My Shared Files/cal-cache/go\""
	gomodcachePath := "~/.cal-cache/go/pkg/mod"

	commands := []string{
		"mkdir -p ~/.cal-cache",
		fmt.Sprintf("ln -sf %s %s", sharedCachePath, vmCacheDir),
		fmt.Sprintf("touch ~/.zshrc && grep -q 'GOMODCACHE' ~/.zshrc || echo 'export GOMODCACHE=%s' >> ~/.zshrc", gomodcachePath),
	}

	return commands
}

// GetGoCacheInfo returns information about the Go cache.
func (c *CacheManager) GetGoCacheInfo() (*CacheInfo, error) {
	cachePath := c.getGoCachePath()

	info, err := os.Stat(cachePath)
	if err != nil {
		if os.IsNotExist(err) {
			return &CacheInfo{
				Path:      cachePath,
				Size:      0,
				Available: false,
			}, nil
		}
		return nil, fmt.Errorf("failed to stat Go cache directory: %w", err)
	}

	size := getDiskUsage(cachePath)

	return &CacheInfo{
		Path:       cachePath,
		Size:       size,
		Available:  true,
		LastAccess: info.ModTime(),
	}, nil
}

// getGitCachePath returns the host path for git cache.
func (c *CacheManager) getGitCachePath() string {
	return filepath.Join(c.cacheBaseDir, gitCacheDir)
}

// SetupGitCache sets up the git cache directory on the host.
// Creates the cache directory with graceful degradation on errors.
func (c *CacheManager) SetupGitCache() error {
	if c.homeDir == "" {
		fmt.Fprintf(os.Stderr, "Warning: home directory not available, continuing without git cache\n")
		return nil
	}

	hostCacheDir := c.getGitCachePath()

	if err := os.MkdirAll(hostCacheDir, 0755); err != nil {
		return fmt.Errorf("failed to create host git cache directory: %w", err)
	}

	return nil
}

// SetupVMGitCache returns shell commands to set up git cache in the VM.
// The commands create a symlink from the VM home directory to the shared cache volume.
// Returns nil if host cache is not available.
func (c *CacheManager) SetupVMGitCache() []string {
	if c.homeDir == "" {
		return nil
	}

	hostCacheDir := c.getGitCachePath()
	if _, err := os.Stat(hostCacheDir); os.IsNotExist(err) {
		return nil
	}

	vmCacheDir := "~/.cal-cache/git"
	sharedCachePath := "\"/Volumes/My Shared Files/cal-cache/git\""

	commands := []string{
		"mkdir -p ~/.cal-cache",
		fmt.Sprintf("ln -sf %s %s", sharedCachePath, vmCacheDir),
	}

	return commands
}

// GetGitCacheInfo returns information about the git cache.
func (c *CacheManager) GetGitCacheInfo() (*CacheInfo, error) {
	cachePath := c.getGitCachePath()

	info, err := os.Stat(cachePath)
	if err != nil {
		if os.IsNotExist(err) {
			return &CacheInfo{
				Path:      cachePath,
				Size:      0,
				Available: false,
			}, nil
		}
		return nil, fmt.Errorf("failed to stat git cache directory: %w", err)
	}

	size := getDiskUsage(cachePath)

	return &CacheInfo{
		Path:       cachePath,
		Size:       size,
		Available:  true,
		LastAccess: info.ModTime(),
	}, nil
}

// GetCachedGitRepos returns a list of git repository names that are cached.
func (c *CacheManager) GetCachedGitRepos() ([]string, error) {
	cachePath := c.getGitCachePath()

	entries, err := os.ReadDir(cachePath)
	if err != nil {
		if os.IsNotExist(err) {
			return []string{}, nil
		}
		return nil, fmt.Errorf("failed to read git cache directory: %w", err)
	}

	repos := []string{}
	for _, entry := range entries {
		if entry.IsDir() {
			repos = append(repos, entry.Name())
		}
	}

	return repos, nil
}

// CacheGitRepo clones a git repository to the cache directory.
// repoURL should be the full git URL (e.g., https://github.com/user/repo.git)
// repoName is the name for the cached repo directory (e.g., "repo")
// Returns true if cache was created/updated, false if repo already exists and is up to date.
func (c *CacheManager) CacheGitRepo(repoURL, repoName string) (bool, error) {
	if c.homeDir == "" {
		return false, fmt.Errorf("home directory not available")
	}

	repoCacheDir := filepath.Join(c.getGitCachePath(), repoName)

	if _, err := os.Stat(repoCacheDir); err == nil {
		return false, nil
	}

	if err := os.MkdirAll(filepath.Dir(repoCacheDir), 0755); err != nil {
		return false, fmt.Errorf("failed to create cache directory: %w", err)
	}

	cmd := exec.Command("git", "clone", repoURL, repoCacheDir)
	if err := cmd.Run(); err != nil {
		return false, fmt.Errorf("failed to clone repo %s: %w", repoURL, err)
	}

	return true, nil
}

// UpdateGitRepos updates all cached git repositories by running git fetch.
// Returns the number of repos updated and any errors encountered.
func (c *CacheManager) UpdateGitRepos() (int, error) {
	repos, err := c.GetCachedGitRepos()
	if err != nil {
		return 0, fmt.Errorf("failed to get cached repos: %w", err)
	}

	if len(repos) == 0 {
		return 0, nil
	}

	updated := 0
	for _, repo := range repos {
		repoPath := filepath.Join(c.getGitCachePath(), repo)
		cmd := exec.Command("git", "-C", repoPath, "fetch", "--all")
		if err := cmd.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "Warning: failed to update git cache for %s: %v\n", repo, err)
			continue
		}
		updated++
	}

	return updated, nil
}

// Status displays cache status information to the writer.
func (c *CacheManager) Status(w io.Writer) error {
	homebrewInfo, err := c.GetHomebrewCacheInfo()
	if err != nil {
		return fmt.Errorf("failed to get Homebrew cache info: %w", err)
	}

	npmInfo, err := c.GetNpmCacheInfo()
	if err != nil {
		return fmt.Errorf("failed to get npm cache info: %w", err)
	}

	goInfo, err := c.GetGoCacheInfo()
	if err != nil {
		return fmt.Errorf("failed to get Go cache info: %w", err)
	}

	gitInfo, err := c.GetGitCacheInfo()
	if err != nil {
		return fmt.Errorf("failed to get git cache info: %w", err)
	}

	fmt.Fprintf(w, "Cache Status:\n")
	fmt.Fprintf(w, "\n")
	fmt.Fprintf(w, "Homebrew:\n")
	fmt.Fprintf(w, "  Location: %s\n", homebrewInfo.Path)
	fmt.Fprintf(w, "  Status: ")
	if homebrewInfo.Available {
		fmt.Fprintf(w, "✓ Ready\n")
		fmt.Fprintf(w, "  Size: %s\n", FormatBytes(homebrewInfo.Size))
		if !homebrewInfo.LastAccess.IsZero() {
			fmt.Fprintf(w, "  Last access: %s\n", homebrewInfo.LastAccess.Format(time.RFC3339))
		}
	} else {
		fmt.Fprintf(w, "✗ Not configured\n")
	}
	fmt.Fprintf(w, "\n")
	fmt.Fprintf(w, "npm:\n")
	fmt.Fprintf(w, "  Location: %s\n", npmInfo.Path)
	fmt.Fprintf(w, "  Status: ")
	if npmInfo.Available {
		fmt.Fprintf(w, "✓ Ready\n")
		fmt.Fprintf(w, "  Size: %s\n", FormatBytes(npmInfo.Size))
		if !npmInfo.LastAccess.IsZero() {
			fmt.Fprintf(w, "  Last access: %s\n", npmInfo.LastAccess.Format(time.RFC3339))
		}
	} else {
		fmt.Fprintf(w, "✗ Not configured\n")
	}
	fmt.Fprintf(w, "\n")
	fmt.Fprintf(w, "Go:\n")
	fmt.Fprintf(w, "  Location: %s\n", goInfo.Path)
	fmt.Fprintf(w, "  Status: ")
	if goInfo.Available {
		fmt.Fprintf(w, "✓ Ready\n")
		fmt.Fprintf(w, "  Size: %s\n", FormatBytes(goInfo.Size))
		if !goInfo.LastAccess.IsZero() {
			fmt.Fprintf(w, "  Last access: %s\n", goInfo.LastAccess.Format(time.RFC3339))
		}
	} else {
		fmt.Fprintf(w, "✗ Not configured\n")
	}
	fmt.Fprintf(w, "\n")
	fmt.Fprintf(w, "Git:\n")
	fmt.Fprintf(w, "  Location: %s\n", gitInfo.Path)
	fmt.Fprintf(w, "  Status: ")
	if gitInfo.Available {
		fmt.Fprintf(w, "✓ Ready\n")
		fmt.Fprintf(w, "  Size: %s\n", FormatBytes(gitInfo.Size))
		if !gitInfo.LastAccess.IsZero() {
			fmt.Fprintf(w, "  Last access: %s\n", gitInfo.LastAccess.Format(time.RFC3339))
		}
		repos, err := c.GetCachedGitRepos()
		if err == nil && len(repos) > 0 {
			fmt.Fprintf(w, "  Cached repos: %d\n", len(repos))
			for _, repo := range repos {
				fmt.Fprintf(w, "    - %s\n", repo)
			}
		}
	} else {
		fmt.Fprintf(w, "✗ Not configured\n")
	}
	fmt.Fprintf(w, "\n")

	return nil
}

// FormatBytes formats a byte count into a human-readable string.
func FormatBytes(b int64) string {
	const unit = 1024
	if b < unit {
		return fmt.Sprintf("%d B", b)
	}
	div, exp := int64(unit), 0
	for n := b / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(b)/float64(div), "KMGTPE"[exp])
}

// removeAllWithPermFix removes a directory tree, fixing permissions as needed.
// Go module cache files may have read-only permissions that prevent deletion.
// This function makes all files and directories writable before attempting to delete.
func removeAllWithPermFix(path string) error {
	// First, try the fast path - works for most caches
	err := os.RemoveAll(path)
	if err == nil {
		return nil
	}

	// If we got a permission error, walk the tree and fix permissions
	if os.IsPermission(err) {
		// Make everything in the tree writable
		filepath.Walk(path, func(p string, info os.FileInfo, walkErr error) error {
			if walkErr != nil {
				// Ignore walk errors - we'll try to delete what we can
				return nil
			}
			// Make writable: add owner write permission (0200)
			// Ignore chmod errors - we'll try to delete anyway
			os.Chmod(p, info.Mode()|0200)
			return nil
		})

		// Try removing again after fixing permissions
		err = os.RemoveAll(path)
	}

	return err
}

// Clear removes the specified cache type and recreates an empty cache directory.
// cacheType must be one of: "homebrew", "npm", "go", "git"
// dryRun if true, simulates clearing without actually deleting files
// Returns true if cache was cleared (or would be cleared in dry run), false if cache didn't exist
func (c *CacheManager) Clear(cacheType string, dryRun bool) (bool, error) {
	if c.homeDir == "" {
		return false, fmt.Errorf("home directory not available")
	}

	var cachePath string
	var setupFunc func() error

	switch cacheType {
	case "homebrew":
		cachePath = c.getHomebrewCachePath()
		setupFunc = c.SetupHomebrewCache
	case "npm":
		cachePath = c.getNpmCachePath()
		setupFunc = c.SetupNpmCache
	case "go":
		cachePath = c.getGoCachePath()
		setupFunc = c.SetupGoCache
	case "git":
		cachePath = c.getGitCachePath()
		setupFunc = c.SetupGitCache
	default:
		return false, fmt.Errorf("invalid cache type: %s (must be homebrew, npm, go, or git)", cacheType)
	}

	info, err := os.Stat(cachePath)
	if err != nil {
		if os.IsNotExist(err) {
			return false, nil
		}
		return false, fmt.Errorf("failed to check cache directory: %w", err)
	}

	if !info.IsDir() {
		return false, fmt.Errorf("cache path is not a directory: %s", cachePath)
	}

	if !dryRun {
		if err := removeAllWithPermFix(cachePath); err != nil {
			return false, fmt.Errorf("failed to remove cache directory: %w", err)
		}
		if err := setupFunc(); err != nil {
			return false, fmt.Errorf("failed to recreate cache directory: %w", err)
		}
	}

	return true, nil
}
