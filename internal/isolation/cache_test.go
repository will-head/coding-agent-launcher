// Package isolation provides VM isolation and management for CAL.
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
	tmpDir, err := os.MkdirTemp("", "cal-cache-test-*")
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
	tmpDir, err := os.MkdirTemp("", "cal-cache-test-*")
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
	tmpDir, err := os.MkdirTemp("", "cal-cache-test-*")
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
		tmpDir, err := os.MkdirTemp("", "cal-cache-test-*")
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
	tmpDir, err := os.MkdirTemp("", "cal-cache-test-*")
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

		// Verify commands contain expected operations
		commandsStr := strings.Join(commands, " ")
		if !strings.Contains(commandsStr, "mkdir -p ~/.cal-cache") {
			t.Fatalf("expected mkdir command in VM setup")
		}
		if !strings.Contains(commandsStr, "ln -sf") {
			t.Fatalf("expected symlink command in VM setup")
		}
		if !strings.Contains(commandsStr, "HOMEBREW_CACHE") {
			t.Fatalf("expected HOMEBREW_CACHE environment variable setup")
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

		expected := "cal-cache:~/.cal-cache"
		if mount != expected {
			t.Fatalf("expected mount spec %s, got %s", expected, mount)
		}
	})

	t.Run("GetHomebrewCacheHostPath returns correct host path", func(t *testing.T) {
		tmpDir, err := os.MkdirTemp("", "cal-cache-test-*")
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

		if !strings.Contains(hostPath, "cal-cache:") {
			t.Fatalf("expected 'cal-cache:' prefix in host path")
		}

		if !strings.Contains(hostPath, "homebrew") {
			t.Fatalf("expected 'homebrew' in host path")
		}
	})
}
