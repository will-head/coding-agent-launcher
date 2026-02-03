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
	Path       string
	Size       int64
	Available  bool
	LastAccess time.Time
}

const (
	homebrewCacheDir     = "homebrew"
	homebrewDownloadsDir = "downloads"
	homebrewCaskDir      = "Cask"
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

// SetupHomebrewCache sets up the Homebrew cache directory on the host.
// Creates the cache directory structure with graceful degradation on errors.
func (c *CacheManager) SetupHomebrewCache() error {
	if c.homeDir == "" {
		return fmt.Errorf("home directory not available")
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
