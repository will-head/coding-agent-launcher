// Package isolation provides VM isolation and management for CAL.
package isolation

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

// CacheManager manages package download caches for CAL VMs.
type CacheManager struct {
	homeDir        string
	cacheBaseDir   string
	sharedCacheDir string
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
	// sharedCacheMount is the Tart directory mount specification for cache sharing.
	sharedCacheMount = "cal-cache:~/.cal-cache"
)

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

	var size int64
	err = filepath.Walk(cachePath, func(path string, fi os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !fi.IsDir() {
			size += fi.Size()
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("failed to calculate cache size: %w", err)
	}

	return &CacheInfo{
		Path:       cachePath,
		Size:       size,
		Available:  true,
		LastAccess: info.ModTime(),
	}, nil
}

// Status displays cache status information to the writer.
func (c *CacheManager) Status(w io.Writer) error {
	homebrewInfo, err := c.GetHomebrewCacheInfo()
	if err != nil {
		return fmt.Errorf("failed to get Homebrew cache info: %w", err)
	}

	fmt.Fprintf(w, "Cache Status:\n")
	fmt.Fprintf(w, "\n")
	fmt.Fprintf(w, "Homebrew:\n")
	fmt.Fprintf(w, "  Location: %s\n", homebrewInfo.Path)
	fmt.Fprintf(w, "  Status: ")
	if homebrewInfo.Available {
		fmt.Fprintf(w, "✓ Ready\n")
		fmt.Fprintf(w, "  Size: %s\n", formatBytes(homebrewInfo.Size))
		if !homebrewInfo.LastAccess.IsZero() {
			fmt.Fprintf(w, "  Last access: %s\n", homebrewInfo.LastAccess.Format(time.RFC3339))
		}
	} else {
		fmt.Fprintf(w, "✗ Not configured\n")
	}
	fmt.Fprintf(w, "\n")

	return nil
}

// formatBytes formats a byte count into a human-readable string.
func formatBytes(b int64) string {
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
