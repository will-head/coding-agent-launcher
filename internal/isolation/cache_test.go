// Package isolation provides VM isolation and management for CALF.
package isolation

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestCacheManager_HomebrewSetup(t *testing.T) {
	// Create a temporary directory for testing
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("SetupHomebrewCache creates host cache directory", func(t *testing.T) {
		err := cm.SetupHomebrewCache()
		if err != nil {
			t.Fatalf("SetupHomebrewCache failed: %v", err)
		}

		hostCacheDir := filepath.Join(cm.cacheBaseDir, "homebrew")
		info, err := os.Stat(hostCacheDir)
		if err != nil {
			t.Fatalf("host cache directory not created: %v", err)
		}
		if !info.IsDir() {
			t.Fatalf("host cache is not a directory")
		}

		// Verify subdirectories exist
		downloadsDir := filepath.Join(hostCacheDir, "downloads")
		if _, err := os.Stat(downloadsDir); err != nil {
			t.Fatalf("downloads subdirectory not created: %v", err)
		}

		caskDir := filepath.Join(hostCacheDir, "Cask")
		if _, err := os.Stat(caskDir); err != nil {
			t.Fatalf("Cask subdirectory not created: %v", err)
		}
	})

	t.Run("SetupHomebrewCache is idempotent", func(t *testing.T) {
		// First setup
		err := cm.SetupHomebrewCache()
		if err != nil {
			t.Fatalf("first SetupHomebrewCache failed: %v", err)
		}

		// Second setup should not fail
		err = cm.SetupHomebrewCache()
		if err != nil {
			t.Fatalf("second SetupHomebrewCache failed: %v", err)
		}
	})
}

func TestCacheManager_GetHomebrewCacheInfo(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("GetHomebrewCacheInfo returns zero size when cache doesn't exist", func(t *testing.T) {
		info, err := cm.GetHomebrewCacheInfo()
		if err != nil {
			t.Fatalf("GetHomebrewCacheInfo failed: %v", err)
		}

		if info.Size != 0 {
			t.Fatalf("expected size 0, got %d", info.Size)
		}

		if info.Path == "" {
			t.Fatalf("expected non-empty path")
		}
	})

	t.Run("GetHomebrewCacheInfo returns size when cache exists", func(t *testing.T) {
		// Setup cache
		err := cm.SetupHomebrewCache()
		if err != nil {
			t.Fatalf("SetupHomebrewCache failed: %v", err)
		}

		// Create a test file
		hostCacheDir := filepath.Join(cm.cacheBaseDir, "homebrew")
		testFile := filepath.Join(hostCacheDir, "test-file.bin")
		if err := os.WriteFile(testFile, []byte("test data"), 0644); err != nil {
			t.Fatalf("failed to create test file: %v", err)
		}

		info, err := cm.GetHomebrewCacheInfo()
		if err != nil {
			t.Fatalf("GetHomebrewCacheInfo failed: %v", err)
		}

		if info.Size == 0 {
			t.Fatalf("expected non-zero size")
		}

		if !info.Available {
			t.Fatalf("expected cache to be available")
		}
	})
}

func TestCacheManager_Status(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("Status displays Homebrew cache information", func(t *testing.T) {
		// Setup cache
		err := cm.SetupHomebrewCache()
		if err != nil {
			t.Fatalf("SetupHomebrewCache failed: %v", err)
		}

		var buf bytes.Buffer
		err = cm.Status(&buf)
		if err != nil {
			t.Fatalf("Status failed: %v", err)
		}

		output := buf.String()
		if output == "" {
			t.Fatalf("expected non-empty status output")
		}

		// Verify cache info is present
		if !strings.Contains(output, "Homebrew") {
			t.Fatalf("expected 'Homebrew' in status output")
		}
	})
}

func TestCacheManager_NewCacheManager(t *testing.T) {
	t.Run("NewCacheManager initializes with default paths", func(t *testing.T) {
		cm := NewCacheManager()

		if cm == nil {
			t.Fatalf("expected non-nil CacheManager")
		}

		if cm.homeDir == "" {
			t.Fatalf("expected homeDir to be set")
		}

		if cm.cacheBaseDir == "" {
			t.Fatalf("expected cacheBaseDir to be set")
		}
	})
}

func TestCacheManager_gracefulDegradation(t *testing.T) {
	t.Run("SetupHomebrewCache gracefully handles missing home directory", func(t *testing.T) {
		cm := &CacheManager{
			homeDir:      "",
			cacheBaseDir: "",
		}

		// Should not return error when home directory unavailable (graceful degradation)
		err := cm.SetupHomebrewCache()
		if err != nil {
			t.Fatalf("expected graceful degradation (nil error) when homeDir unavailable, got: %v", err)
		}
	})

	t.Run("SetupHomebrewCache handles permission errors gracefully", func(t *testing.T) {
		tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
		if err != nil {
			t.Fatalf("failed to create temp dir: %v", err)
		}
		defer os.RemoveAll(tmpDir)

		// Create a directory with read-only permissions
		readonlyDir := filepath.Join(tmpDir, "readonly")
		if err := os.Mkdir(readonlyDir, 0444); err != nil {
			t.Fatalf("failed to create readonly dir: %v", err)
		}
		defer os.Chmod(readonlyDir, 0755)

		cm := &CacheManager{
			homeDir:      tmpDir,
			cacheBaseDir: readonlyDir,
		}

		// Should return error for permission issues (not graceful degradation case)
		err = cm.SetupHomebrewCache()
		if err == nil {
			t.Fatalf("expected error for permission denied, got nil")
		}
	})
}

func TestCacheManager_VMCacheSetup(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("SetupVMHomebrewCache returns commands when host cache exists", func(t *testing.T) {
		// Setup host cache
		err := cm.SetupHomebrewCache()
		if err != nil {
			t.Fatalf("SetupHomebrewCache failed: %v", err)
		}

		commands := cm.SetupVMHomebrewCache()
		if commands == nil {
			t.Fatalf("expected non-nil commands")
		}

		if len(commands) == 0 {
			t.Fatalf("expected at least one command")
		}

		// Verify commands contain expected operations (mount verification, not symlinks)
		commandsStr := strings.Join(commands, " ")
		if !strings.Contains(commandsStr, "mount | grep -q \" on $HOME/.calf-cache \"") {
			t.Fatalf("expected mount verification in VM setup")
		}
		if !strings.Contains(commandsStr, "test -d") {
			t.Fatalf("expected cache directory verification in VM setup")
		}
		if !strings.Contains(commandsStr, "HOMEBREW_CACHE") {
			t.Fatalf("expected HOMEBREW_CACHE environment variable setup")
		}
		if !strings.Contains(commandsStr, "touch ~/.zshrc") {
			t.Fatalf("expected touch command to ensure .zshrc exists before grep")
		}
	})

	t.Run("SetupVMHomebrewCache returns nil when home directory unavailable", func(t *testing.T) {
		cmNoHome := &CacheManager{
			homeDir:      "",
			cacheBaseDir: "",
		}

		commands := cmNoHome.SetupVMHomebrewCache()
		if commands != nil {
			t.Fatalf("expected nil commands when homeDir unavailable, got: %v", commands)
		}
	})

	t.Run("SetupVMHomebrewCache returns nil when host cache doesn't exist", func(t *testing.T) {
		cmNoCache := &CacheManager{
			homeDir:      tmpDir,
			cacheBaseDir: filepath.Join(tmpDir, "nonexistent-cache"),
		}

		commands := cmNoCache.SetupVMHomebrewCache()
		if commands != nil {
			t.Fatalf("expected nil commands when host cache doesn't exist, got: %v", commands)
		}
	})
}

func TestCacheManager_SharedCacheMount(t *testing.T) {
	t.Run("GetSharedCacheMount returns correct mount specification", func(t *testing.T) {
		cm := NewCacheManager()
		mount := cm.GetSharedCacheMount()

		expected := "calf-cache:~/.calf-cache"
		if mount != expected {
			t.Fatalf("expected mount spec %s, got %s", expected, mount)
		}
	})

	t.Run("GetHomebrewCacheHostPath returns correct host path", func(t *testing.T) {
		tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
		if err != nil {
			t.Fatalf("failed to create temp dir: %v", err)
		}
		defer os.RemoveAll(tmpDir)

		cm := &CacheManager{
			homeDir:      tmpDir,
			cacheBaseDir: filepath.Join(tmpDir, "cache"),
		}

		hostPath := cm.GetHomebrewCacheHostPath()
		if hostPath == "" {
			t.Fatalf("expected non-empty host path")
		}

		if !strings.Contains(hostPath, "calf-cache:") {
			t.Fatalf("expected 'calf-cache:' prefix in host path")
		}

		if !strings.Contains(hostPath, "homebrew") {
			t.Fatalf("expected 'homebrew' in host path")
		}
	})
}

func TestFormatBytes(t *testing.T) {
	tests := []struct {
		name     string
		bytes    int64
		expected string
	}{
		{"zero bytes", 0, "0 B"},
		{"bytes only", 512, "512 B"},
		{"exactly 1 KB", 1024, "1.0 KB"},
		{"kilobytes", 1536, "1.5 KB"},
		{"megabytes", 1048576, "1.0 MB"},
		{"gigabytes", 1073741824, "1.0 GB"},
		{"terabytes", 1099511627776, "1.0 TB"},
		{"large size", 5368709120, "5.0 GB"},
		{"fractional MB", 2621440, "2.5 MB"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := FormatBytes(tt.bytes)
			if result != tt.expected {
				t.Errorf("FormatBytes(%d) = %s, expected %s", tt.bytes, result, tt.expected)
			}
		})
	}
}

func TestCacheManager_NpmSetup(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("SetupNpmCache creates host cache directory", func(t *testing.T) {
		err := cm.SetupNpmCache()
		if err != nil {
			t.Fatalf("SetupNpmCache failed: %v", err)
		}

		hostCacheDir := filepath.Join(cm.cacheBaseDir, "npm")
		info, err := os.Stat(hostCacheDir)
		if err != nil {
			t.Fatalf("host cache directory not created: %v", err)
		}
		if !info.IsDir() {
			t.Fatalf("host cache is not a directory")
		}
	})

	t.Run("SetupNpmCache is idempotent", func(t *testing.T) {
		err := cm.SetupNpmCache()
		if err != nil {
			t.Fatalf("first SetupNpmCache failed: %v", err)
		}

		err = cm.SetupNpmCache()
		if err != nil {
			t.Fatalf("second SetupNpmCache failed: %v", err)
		}
	})

	t.Run("SetupNpmCache gracefully handles missing home directory", func(t *testing.T) {
		cmNoHome := &CacheManager{
			homeDir:      "",
			cacheBaseDir: "",
		}

		err := cmNoHome.SetupNpmCache()
		if err != nil {
			t.Fatalf("expected graceful degradation (nil error) when homeDir unavailable, got: %v", err)
		}
	})
}

func TestCacheManager_GetNpmCacheInfo(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("GetNpmCacheInfo returns zero size when cache doesn't exist", func(t *testing.T) {
		info, err := cm.GetNpmCacheInfo()
		if err != nil {
			t.Fatalf("GetNpmCacheInfo failed: %v", err)
		}

		if info.Size != 0 {
			t.Fatalf("expected size 0, got %d", info.Size)
		}

		if info.Path == "" {
			t.Fatalf("expected non-empty path")
		}

		if info.Available {
			t.Fatalf("expected cache to be unavailable")
		}
	})

	t.Run("GetNpmCacheInfo returns size when cache exists", func(t *testing.T) {
		err := cm.SetupNpmCache()
		if err != nil {
			t.Fatalf("SetupNpmCache failed: %v", err)
		}

		hostCacheDir := filepath.Join(cm.cacheBaseDir, "npm")
		testFile := filepath.Join(hostCacheDir, "test-package.tar.gz")
		if err := os.WriteFile(testFile, []byte("test npm cache data"), 0644); err != nil {
			t.Fatalf("failed to create test file: %v", err)
		}

		info, err := cm.GetNpmCacheInfo()
		if err != nil {
			t.Fatalf("GetNpmCacheInfo failed: %v", err)
		}

		if info.Size == 0 {
			t.Fatalf("expected non-zero size")
		}

		if !info.Available {
			t.Fatalf("expected cache to be available")
		}
	})
}

func TestCacheManager_VMNpmCacheSetup(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("SetupVMNpmCache returns commands when host cache exists", func(t *testing.T) {
		err := cm.SetupNpmCache()
		if err != nil {
			t.Fatalf("SetupNpmCache failed: %v", err)
		}

		commands := cm.SetupVMNpmCache()
		if commands == nil {
			t.Fatalf("expected non-nil commands")
		}

		if len(commands) == 0 {
			t.Fatalf("expected at least one command")
		}

		commandsStr := strings.Join(commands, " ")
		if !strings.Contains(commandsStr, "mount | grep -q \" on $HOME/.calf-cache \"") {
			t.Fatalf("expected mount verification in VM setup")
		}
		if !strings.Contains(commandsStr, "test -d") {
			t.Fatalf("expected cache directory verification in VM setup")
		}
		if !strings.Contains(commandsStr, "npm config set cache") {
			t.Fatalf("expected npm cache configuration")
		}
	})

	t.Run("SetupVMNpmCache returns nil when home directory unavailable", func(t *testing.T) {
		cmNoHome := &CacheManager{
			homeDir:      "",
			cacheBaseDir: "",
		}

		commands := cmNoHome.SetupVMNpmCache()
		if commands != nil {
			t.Fatalf("expected nil commands when homeDir unavailable, got: %v", commands)
		}
	})

	t.Run("SetupVMNpmCache returns nil when host cache doesn't exist", func(t *testing.T) {
		cmNoCache := &CacheManager{
			homeDir:      tmpDir,
			cacheBaseDir: filepath.Join(tmpDir, "nonexistent-cache"),
		}

		commands := cmNoCache.SetupVMNpmCache()
		if commands != nil {
			t.Fatalf("expected nil commands when host cache doesn't exist, got: %v", commands)
		}
	})
}

func TestCacheManager_GoSetup(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("SetupGoCache creates host cache directory", func(t *testing.T) {
		err := cm.SetupGoCache()
		if err != nil {
			t.Fatalf("SetupGoCache failed: %v", err)
		}

		hostCacheDir := filepath.Join(cm.cacheBaseDir, "go")
		info, err := os.Stat(hostCacheDir)
		if err != nil {
			t.Fatalf("host cache directory not created: %v", err)
		}
		if !info.IsDir() {
			t.Fatalf("host cache is not a directory")
		}

		pkgModDir := filepath.Join(hostCacheDir, "pkg", "mod")
		if _, err := os.Stat(pkgModDir); err != nil {
			t.Fatalf("pkg/mod subdirectory not created: %v", err)
		}

		pkgSumdbDir := filepath.Join(hostCacheDir, "pkg", "sumdb")
		if _, err := os.Stat(pkgSumdbDir); err != nil {
			t.Fatalf("pkg/sumdb subdirectory not created: %v", err)
		}
	})

	t.Run("SetupGoCache is idempotent", func(t *testing.T) {
		err := cm.SetupGoCache()
		if err != nil {
			t.Fatalf("first SetupGoCache failed: %v", err)
		}

		err = cm.SetupGoCache()
		if err != nil {
			t.Fatalf("second SetupGoCache failed: %v", err)
		}
	})

	t.Run("SetupGoCache gracefully handles missing home directory", func(t *testing.T) {
		cmNoHome := &CacheManager{
			homeDir:      "",
			cacheBaseDir: "",
		}

		err := cmNoHome.SetupGoCache()
		if err != nil {
			t.Fatalf("expected graceful degradation (nil error) when homeDir unavailable, got: %v", err)
		}
	})
}

func TestCacheManager_GetGoCacheInfo(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("GetGoCacheInfo returns zero size when cache doesn't exist", func(t *testing.T) {
		info, err := cm.GetGoCacheInfo()
		if err != nil {
			t.Fatalf("GetGoCacheInfo failed: %v", err)
		}

		if info.Size != 0 {
			t.Fatalf("expected size 0, got %d", info.Size)
		}

		if info.Path == "" {
			t.Fatalf("expected non-empty path")
		}

		if info.Available {
			t.Fatalf("expected cache to be unavailable")
		}
	})

	t.Run("GetGoCacheInfo returns size when cache exists", func(t *testing.T) {
		err := cm.SetupGoCache()
		if err != nil {
			t.Fatalf("SetupGoCache failed: %v", err)
		}

		hostCacheDir := filepath.Join(cm.cacheBaseDir, "go", "pkg", "mod")
		testFile := filepath.Join(hostCacheDir, "test-module@v1.0.0")
		if err := os.WriteFile(testFile, []byte("test go module data"), 0644); err != nil {
			t.Fatalf("failed to create test file: %v", err)
		}

		info, err := cm.GetGoCacheInfo()
		if err != nil {
			t.Fatalf("GetGoCacheInfo failed: %v", err)
		}

		if info.Size == 0 {
			t.Fatalf("expected non-zero size")
		}

		if !info.Available {
			t.Fatalf("expected cache to be available")
		}
	})
}

func TestCacheManager_VMGoCacheSetup(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("SetupVMGoCache returns commands when host cache exists", func(t *testing.T) {
		err := cm.SetupGoCache()
		if err != nil {
			t.Fatalf("SetupGoCache failed: %v", err)
		}

		commands := cm.SetupVMGoCache()
		if commands == nil {
			t.Fatalf("expected non-nil commands")
		}

		if len(commands) == 0 {
			t.Fatalf("expected at least one command")
		}

		commandsStr := strings.Join(commands, " ")
		if !strings.Contains(commandsStr, "mount | grep -q \" on $HOME/.calf-cache \"") {
			t.Fatalf("expected mount verification in VM setup")
		}
		if !strings.Contains(commandsStr, "test -d") {
			t.Fatalf("expected cache directory verification in VM setup")
		}
		if !strings.Contains(commandsStr, "GOMODCACHE") {
			t.Fatalf("expected GOMODCACHE environment variable setup")
		}
		if !strings.Contains(commandsStr, "touch ~/.zshrc") {
			t.Fatalf("expected touch command to ensure .zshrc exists before grep")
		}
	})

	t.Run("SetupVMGoCache returns nil when home directory unavailable", func(t *testing.T) {
		cmNoHome := &CacheManager{
			homeDir:      "",
			cacheBaseDir: "",
		}

		commands := cmNoHome.SetupVMGoCache()
		if commands != nil {
			t.Fatalf("expected nil commands when homeDir unavailable, got: %v", commands)
		}
	})

	t.Run("SetupVMGoCache returns nil when host cache doesn't exist", func(t *testing.T) {
		cmNoCache := &CacheManager{
			homeDir:      tmpDir,
			cacheBaseDir: filepath.Join(tmpDir, "nonexistent-cache"),
		}

		commands := cmNoCache.SetupVMGoCache()
		if commands != nil {
			t.Fatalf("expected nil commands when host cache doesn't exist, got: %v", commands)
		}
	})
}

func TestCacheManager_GitSetup(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("SetupGitCache creates host cache directory", func(t *testing.T) {
		err := cm.SetupGitCache()
		if err != nil {
			t.Fatalf("SetupGitCache failed: %v", err)
		}

		hostCacheDir := filepath.Join(cm.cacheBaseDir, "git")
		info, err := os.Stat(hostCacheDir)
		if err != nil {
			t.Fatalf("host cache directory not created: %v", err)
		}
		if !info.IsDir() {
			t.Fatalf("host cache is not a directory")
		}
	})

	t.Run("SetupGitCache is idempotent", func(t *testing.T) {
		err := cm.SetupGitCache()
		if err != nil {
			t.Fatalf("first SetupGitCache failed: %v", err)
		}

		err = cm.SetupGitCache()
		if err != nil {
			t.Fatalf("second SetupGitCache failed: %v", err)
		}
	})

	t.Run("SetupGitCache gracefully handles missing home directory", func(t *testing.T) {
		cmNoHome := &CacheManager{
			homeDir:      "",
			cacheBaseDir: "",
		}

		err := cmNoHome.SetupGitCache()
		if err != nil {
			t.Fatalf("expected graceful degradation (nil error) when homeDir unavailable, got: %v", err)
		}
	})
}

func TestCacheManager_GetGitCacheInfo(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("GetGitCacheInfo returns zero size when cache doesn't exist", func(t *testing.T) {
		info, err := cm.GetGitCacheInfo()
		if err != nil {
			t.Fatalf("GetGitCacheInfo failed: %v", err)
		}

		if info.Size != 0 {
			t.Fatalf("expected size 0, got %d", info.Size)
		}

		if info.Path == "" {
			t.Fatalf("expected non-empty path")
		}

		if info.Available {
			t.Fatalf("expected cache to be unavailable")
		}
	})

	t.Run("GetGitCacheInfo returns size when cache exists", func(t *testing.T) {
		err := cm.SetupGitCache()
		if err != nil {
			t.Fatalf("SetupGitCache failed: %v", err)
		}

		repoCacheDir := filepath.Join(cm.cacheBaseDir, "git", "test-repo")
		if err := os.MkdirAll(repoCacheDir, 0755); err != nil {
			t.Fatalf("failed to create test repo cache: %v", err)
		}
		testFile := filepath.Join(repoCacheDir, "test-file.bin")
		if err := os.WriteFile(testFile, []byte("test git cache data"), 0644); err != nil {
			t.Fatalf("failed to create test file: %v", err)
		}

		info, err := cm.GetGitCacheInfo()
		if err != nil {
			t.Fatalf("GetGitCacheInfo failed: %v", err)
		}

		if info.Size == 0 {
			t.Fatalf("expected non-zero size")
		}

		if !info.Available {
			t.Fatalf("expected cache to be available")
		}
	})
}

func TestCacheManager_VMGitCacheSetup(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("SetupVMGitCache returns commands when host cache exists", func(t *testing.T) {
		err := cm.SetupGitCache()
		if err != nil {
			t.Fatalf("SetupGitCache failed: %v", err)
		}

		commands := cm.SetupVMGitCache()
		if commands == nil {
			t.Fatalf("expected non-nil commands")
		}

		if len(commands) == 0 {
			t.Fatalf("expected at least one command")
		}

		commandsStr := strings.Join(commands, " ")
		if !strings.Contains(commandsStr, "mount | grep -q \" on $HOME/.calf-cache \"") {
			t.Fatalf("expected mount verification in VM setup")
		}
		if !strings.Contains(commandsStr, "test -d") {
			t.Fatalf("expected cache directory verification in VM setup")
		}
	})

	t.Run("SetupVMGitCache returns nil when home directory unavailable", func(t *testing.T) {
		cmNoHome := &CacheManager{
			homeDir:      "",
			cacheBaseDir: "",
		}

		commands := cmNoHome.SetupVMGitCache()
		if commands != nil {
			t.Fatalf("expected nil commands when homeDir unavailable, got: %v", commands)
		}
	})

	t.Run("SetupVMGitCache returns nil when host cache doesn't exist", func(t *testing.T) {
		cmNoCache := &CacheManager{
			homeDir:      tmpDir,
			cacheBaseDir: filepath.Join(tmpDir, "nonexistent-cache"),
		}

		commands := cmNoCache.SetupVMGitCache()
		if commands != nil {
			t.Fatalf("expected nil commands when host cache doesn't exist, got: %v", commands)
		}
	})
}

func TestCacheManager_GetCachedGitRepos(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("GetCachedGitRepos returns empty list when cache doesn't exist", func(t *testing.T) {
		repos, err := cm.GetCachedGitRepos()
		if err != nil {
			t.Fatalf("GetCachedGitRepos failed: %v", err)
		}

		if len(repos) != 0 {
			t.Fatalf("expected empty list, got %d repos", len(repos))
		}
	})

	t.Run("GetCachedGitRepos returns list of cached repos", func(t *testing.T) {
		err := cm.SetupGitCache()
		if err != nil {
			t.Fatalf("SetupGitCache failed: %v", err)
		}

		repo1Dir := filepath.Join(cm.cacheBaseDir, "git", "repo1")
		repo2Dir := filepath.Join(cm.cacheBaseDir, "git", "repo2")
		if err := os.MkdirAll(repo1Dir, 0755); err != nil {
			t.Fatalf("failed to create repo1: %v", err)
		}
		if err := os.MkdirAll(repo2Dir, 0755); err != nil {
			t.Fatalf("failed to create repo2: %v", err)
		}

		repos, err := cm.GetCachedGitRepos()
		if err != nil {
			t.Fatalf("GetCachedGitRepos failed: %v", err)
		}

		if len(repos) != 2 {
			t.Fatalf("expected 2 repos, got %d", len(repos))
		}

		foundRepo1 := false
		foundRepo2 := false
		for _, repo := range repos {
			if repo == "repo1" {
				foundRepo1 = true
			}
			if repo == "repo2" {
				foundRepo2 = true
			}
		}

		if !foundRepo1 || !foundRepo2 {
			t.Fatalf("expected to find repo1 and repo2, got %v", repos)
		}
	})
}

func TestCacheManager_CacheGitRepo(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("CacheGitRepo returns false when repo already cached", func(t *testing.T) {
		err := cm.SetupGitCache()
		if err != nil {
			t.Fatalf("SetupGitCache failed: %v", err)
		}

		repoDir := filepath.Join(cm.cacheBaseDir, "git", "test-repo")
		if err := os.MkdirAll(repoDir, 0755); err != nil {
			t.Fatalf("failed to create test repo: %v", err)
		}

		created, err := cm.CacheGitRepo("https://example.com/repo.git", "test-repo")
		if err != nil {
			t.Fatalf("CacheGitRepo failed: %v", err)
		}

		if created {
			t.Fatalf("expected false when repo already exists, got true")
		}
	})

	t.Run("CacheGitRepo gracefully handles missing home directory", func(t *testing.T) {
		cmNoHome := &CacheManager{
			homeDir:      "",
			cacheBaseDir: "",
		}

		_, err := cmNoHome.CacheGitRepo("https://example.com/repo.git", "test-repo")
		if err == nil {
			t.Fatalf("expected error when homeDir unavailable")
		}
	})
}

func TestCacheManager_UpdateGitRepos(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("UpdateGitRepos returns 0 when no repos cached", func(t *testing.T) {
		updated, err := cm.UpdateGitRepos()
		if err != nil {
			t.Fatalf("UpdateGitRepos failed: %v", err)
		}

		if updated != 0 {
			t.Fatalf("expected 0 updates when no repos cached, got %d", updated)
		}
	})

	t.Run("UpdateGitRepos skips non-git directories gracefully", func(t *testing.T) {
		err := cm.SetupGitCache()
		if err != nil {
			t.Fatalf("SetupGitCache failed: %v", err)
		}

		repoDir := filepath.Join(cm.cacheBaseDir, "git", "not-a-repo")
		if err := os.MkdirAll(repoDir, 0755); err != nil {
			t.Fatalf("failed to create non-repo directory: %v", err)
		}

		updated, err := cm.UpdateGitRepos()
		if err != nil {
			t.Fatalf("UpdateGitRepos failed: %v", err)
		}

		if updated != 0 {
			t.Fatalf("expected 0 updates for non-git directory, got %d", updated)
		}
	})
}

func TestCacheManager_Clear(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "calf-cache-test-*")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	cm := &CacheManager{
		homeDir:      tmpDir,
		cacheBaseDir: filepath.Join(tmpDir, "cache"),
	}

	t.Run("Clear removes cache directory and recreates it", func(t *testing.T) {
		err := cm.SetupHomebrewCache()
		if err != nil {
			t.Fatalf("SetupHomebrewCache failed: %v", err)
		}

		hostCacheDir := filepath.Join(cm.cacheBaseDir, "homebrew")
		testFile := filepath.Join(hostCacheDir, "test-file.bin")
		if err := os.WriteFile(testFile, []byte("test data"), 0644); err != nil {
			t.Fatalf("failed to create test file: %v", err)
		}

		cleared, err := cm.Clear("homebrew", false)
		if err != nil {
			t.Fatalf("Clear failed: %v", err)
		}

		if !cleared {
			t.Fatalf("expected cleared=true, got false")
		}

		if _, err := os.Stat(testFile); !os.IsNotExist(err) {
			t.Fatalf("expected test file to be deleted, but it still exists")
		}

		info, err := os.Stat(hostCacheDir)
		if err != nil {
			t.Fatalf("expected cache directory to be recreated: %v", err)
		}
		if !info.IsDir() {
			t.Fatalf("expected cache directory to be a directory")
		}
	})

	t.Run("Clear with dryRun does not delete cache", func(t *testing.T) {
		err := cm.SetupHomebrewCache()
		if err != nil {
			t.Fatalf("SetupHomebrewCache failed: %v", err)
		}

		hostCacheDir := filepath.Join(cm.cacheBaseDir, "homebrew")
		testFile := filepath.Join(hostCacheDir, "test-file.bin")
		if err := os.WriteFile(testFile, []byte("test data"), 0644); err != nil {
			t.Fatalf("failed to create test file: %v", err)
		}

		cleared, err := cm.Clear("homebrew", true)
		if err != nil {
			t.Fatalf("Clear failed: %v", err)
		}

		if !cleared {
			t.Fatalf("expected cleared=true in dry run mode")
		}

		if _, err := os.Stat(testFile); os.IsNotExist(err) {
			t.Fatalf("expected test file to exist in dry run mode, but it was deleted")
		}
	})

	t.Run("Clear returns cleared=false when cache doesn't exist", func(t *testing.T) {
		freshTmpDir, err := os.MkdirTemp("", "calf-cache-clear-test-*")
		if err != nil {
			t.Fatalf("failed to create temp dir: %v", err)
		}
		defer os.RemoveAll(freshTmpDir)

		freshCm := &CacheManager{
			homeDir:      freshTmpDir,
			cacheBaseDir: filepath.Join(freshTmpDir, "cache"),
		}

		cleared, err := freshCm.Clear("homebrew", false)
		if err != nil {
			t.Fatalf("Clear failed: %v", err)
		}

		if cleared {
			t.Fatalf("expected cleared=false when cache doesn't exist")
		}
	})

	t.Run("Clear handles all cache types", func(t *testing.T) {
		testCases := []string{"homebrew", "npm", "go", "git"}

		for _, cacheType := range testCases {
			t.Run(cacheType, func(t *testing.T) {
				switch cacheType {
				case "homebrew":
					err := cm.SetupHomebrewCache()
					if err != nil {
						t.Fatalf("SetupHomebrewCache failed: %v", err)
					}
				case "npm":
					err := cm.SetupNpmCache()
					if err != nil {
						t.Fatalf("SetupNpmCache failed: %v", err)
					}
				case "go":
					err := cm.SetupGoCache()
					if err != nil {
						t.Fatalf("SetupGoCache failed: %v", err)
					}
				case "git":
					err := cm.SetupGitCache()
					if err != nil {
						t.Fatalf("SetupGitCache failed: %v", err)
					}
				}

				cleared, err := cm.Clear(cacheType, false)
				if err != nil {
					t.Fatalf("Clear failed for %s: %v", cacheType, err)
				}

				if !cleared {
					t.Fatalf("expected cleared=true for %s", cacheType)
				}
			})
		}
	})

	t.Run("Clear recreates Go cache subdirectories", func(t *testing.T) {
		err := cm.SetupGoCache()
		if err != nil {
			t.Fatalf("SetupGoCache failed: %v", err)
		}

		hostCacheDir := filepath.Join(cm.cacheBaseDir, "go")
		testFile := filepath.Join(hostCacheDir, "pkg", "mod", "test-file.bin")
		if err := os.WriteFile(testFile, []byte("test data"), 0644); err != nil {
			t.Fatalf("failed to create test file: %v", err)
		}

		cleared, err := cm.Clear("go", false)
		if err != nil {
			t.Fatalf("Clear failed: %v", err)
		}

		if !cleared {
			t.Fatalf("expected cleared=true, got false")
		}

		pkgModDir := filepath.Join(hostCacheDir, "pkg", "mod")
		if _, err := os.Stat(pkgModDir); err != nil {
			t.Fatalf("expected pkg/mod subdirectory to be recreated: %v", err)
		}
	})

	t.Run("Clear handles read-only files in Go cache", func(t *testing.T) {
		err := cm.SetupGoCache()
		if err != nil {
			t.Fatalf("SetupGoCache failed: %v", err)
		}

		// Create test files with read-only permissions (simulates Go module cache)
		hostCacheDir := filepath.Join(cm.cacheBaseDir, "go")
		modDir := filepath.Join(hostCacheDir, "pkg", "mod")
		testModuleDir := filepath.Join(modDir, "gopkg.in", "yaml.v3@v3.0.1")
		if err := os.MkdirAll(testModuleDir, 0755); err != nil {
			t.Fatalf("failed to create test module directory: %v", err)
		}

		// Create read-only files
		readOnlyFile := filepath.Join(testModuleDir, "decode_test.go")
		if err := os.WriteFile(readOnlyFile, []byte("package yaml"), 0444); err != nil {
			t.Fatalf("failed to create read-only test file: %v", err)
		}

		// Make parent directories read-only too
		if err := os.Chmod(testModuleDir, 0555); err != nil {
			t.Fatalf("failed to make test module directory read-only: %v", err)
		}
		parentDir := filepath.Join(modDir, "gopkg.in")
		if err := os.Chmod(parentDir, 0555); err != nil {
			t.Fatalf("failed to make parent directory read-only: %v", err)
		}

		// Ensure cleanup happens even if test fails
		defer func() {
			os.Chmod(parentDir, 0755)
			os.Chmod(testModuleDir, 0755)
			os.Chmod(readOnlyFile, 0644)
		}()

		// Clear should succeed despite read-only permissions
		cleared, err := cm.Clear("go", false)
		if err != nil {
			t.Fatalf("Clear failed with read-only files: %v", err)
		}

		if !cleared {
			t.Fatalf("expected cleared=true with read-only files")
		}

		// Verify cache directory was recreated
		if _, err := os.Stat(modDir); err != nil {
			t.Fatalf("expected pkg/mod subdirectory to be recreated: %v", err)
		}

		// Verify test file was actually deleted
		if _, err := os.Stat(readOnlyFile); !os.IsNotExist(err) {
			t.Fatalf("expected read-only test file to be deleted")
		}
	})

	t.Run("Clear preserves symlinks and clears target contents", func(t *testing.T) {
		// This simulates the VM scenario where ~/.calf-cache/{type} is a symlink
		// to /Volumes/My Shared Files/calf-cache/{type}

		// Create a directory structure simulating the shared volume
		sharedVolume := filepath.Join(tmpDir, "shared-volume")
		if err := os.MkdirAll(sharedVolume, 0755); err != nil {
			t.Fatalf("failed to create shared volume dir: %v", err)
		}

		// Create actual cache data in the shared volume
		sharedCacheDir := filepath.Join(sharedVolume, "npm")
		if err := os.MkdirAll(sharedCacheDir, 0755); err != nil {
			t.Fatalf("failed to create shared cache dir: %v", err)
		}

		// Create test files in the shared cache
		testFile1 := filepath.Join(sharedCacheDir, "package1.tgz")
		testFile2 := filepath.Join(sharedCacheDir, "package2.tgz")
		if err := os.WriteFile(testFile1, []byte("package data 1"), 0644); err != nil {
			t.Fatalf("failed to create test file 1: %v", err)
		}
		if err := os.WriteFile(testFile2, []byte("package data 2"), 0644); err != nil {
			t.Fatalf("failed to create test file 2: %v", err)
		}

		// Create CacheManager with default .calf-cache directory (required for symlink resolution)
		vmTmpDir, err := os.MkdirTemp("", "calf-vm-test-*")
		if err != nil {
			t.Fatalf("failed to create VM temp dir: %v", err)
		}
		defer os.RemoveAll(vmTmpDir)

		vmCm := &CacheManager{
			homeDir:      vmTmpDir,
			cacheBaseDir: filepath.Join(vmTmpDir, ".calf-cache"),
		}

		// Create the .calf-cache base directory
		if err := os.MkdirAll(vmCm.cacheBaseDir, 0755); err != nil {
			t.Fatalf("failed to create .calf-cache dir: %v", err)
		}

		// Create symlink from .calf-cache/npm to the shared volume
		symlinkPath := filepath.Join(vmCm.cacheBaseDir, "npm")
		if err := os.Symlink(sharedCacheDir, symlinkPath); err != nil {
			t.Fatalf("failed to create symlink: %v", err)
		}

		// Verify symlink exists and points to shared volume
		target, err := filepath.EvalSymlinks(symlinkPath)
		if err != nil {
			t.Fatalf("failed to resolve symlink: %v", err)
		}
		// Normalize paths for comparison (macOS adds /private prefix)
		expectedTarget, _ := filepath.EvalSymlinks(sharedCacheDir)
		if target != expectedTarget {
			t.Fatalf("symlink points to wrong target: got %s, want %s", target, expectedTarget)
		}

		// Clear the cache
		cleared, err := vmCm.Clear("npm", false)
		if err != nil {
			t.Fatalf("Clear failed: %v", err)
		}

		if !cleared {
			t.Fatalf("expected cleared=true")
		}

		// Verify symlink still exists
		info, err := os.Lstat(symlinkPath)
		if err != nil {
			t.Fatalf("symlink was removed: %v", err)
		}
		if info.Mode()&os.ModeSymlink == 0 {
			t.Fatalf("expected symlink to be preserved, but it's now a regular directory")
		}

		// Verify symlink still points to the same target
		newTarget, err := filepath.EvalSymlinks(symlinkPath)
		if err != nil {
			t.Fatalf("failed to resolve symlink after clear: %v", err)
		}
		if newTarget != expectedTarget {
			t.Fatalf("symlink target changed: got %s, want %s", newTarget, expectedTarget)
		}

		// Verify cache contents were deleted
		if _, err := os.Stat(testFile1); !os.IsNotExist(err) {
			t.Fatalf("expected test file 1 to be deleted")
		}
		if _, err := os.Stat(testFile2); !os.IsNotExist(err) {
			t.Fatalf("expected test file 2 to be deleted")
		}

		// Verify shared cache directory still exists (not removed)
		if _, err := os.Stat(sharedCacheDir); err != nil {
			t.Fatalf("shared cache directory was removed: %v", err)
		}

		// Verify directory is empty
		entries, err := os.ReadDir(sharedCacheDir)
		if err != nil {
			t.Fatalf("failed to read shared cache dir: %v", err)
		}
		if len(entries) != 0 {
			t.Fatalf("expected empty directory, found %d entries", len(entries))
		}
	})
}
