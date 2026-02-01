package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLoadConfig(t *testing.T) {
	// Test loading config when file doesn't exist (should use defaults)
	t.Run("missing config file uses defaults", func(t *testing.T) {
		tmpDir := t.TempDir()
		configPath := filepath.Join(tmpDir, "config.yaml")

		cfg, err := LoadConfig(configPath, "")
		if err != nil {
			t.Fatalf("LoadConfig returned unexpected error: %v", err)
		}

		// Verify defaults are loaded
		if cfg.Isolation.Defaults.VM.CPU != 4 {
			t.Errorf("Expected CPU default 4, got %d", cfg.Isolation.Defaults.VM.CPU)
		}
		if cfg.Isolation.Defaults.VM.Memory != 8192 {
			t.Errorf("Expected Memory default 8192, got %d", cfg.Isolation.Defaults.VM.Memory)
		}
		if cfg.Isolation.Defaults.VM.DiskSize != 80 {
			t.Errorf("Expected DiskSize default 80, got %d", cfg.Isolation.Defaults.VM.DiskSize)
		}
		if cfg.Isolation.Defaults.VM.BaseImage != "ghcr.io/cirruslabs/macos-sequoia-base:latest" {
			t.Errorf("Expected BaseImage default 'ghcr.io/cirruslabs/macos-sequoia-base:latest', got %s", cfg.Isolation.Defaults.VM.BaseImage)
		}
		if cfg.Isolation.Defaults.Proxy.Mode != "auto" {
			t.Errorf("Expected Proxy mode default 'auto', got %s", cfg.Isolation.Defaults.Proxy.Mode)
		}
	})

	// Test loading config when both paths are empty (should use defaults)
	t.Run("empty paths use defaults", func(t *testing.T) {
		cfg, err := LoadConfig("", "")
		if err != nil {
			t.Fatalf("LoadConfig with empty paths returned unexpected error: %v", err)
		}

		// Verify defaults are loaded
		if cfg.Isolation.Defaults.VM.CPU != 4 {
			t.Errorf("Expected CPU default 4, got %d", cfg.Isolation.Defaults.VM.CPU)
		}
		if cfg.Isolation.Defaults.VM.Memory != 8192 {
			t.Errorf("Expected Memory default 8192, got %d", cfg.Isolation.Defaults.VM.Memory)
		}
	})

	// Test loading valid config file
	t.Run("valid config file loads correctly", func(t *testing.T) {
		tmpDir := t.TempDir()
		configPath := filepath.Join(tmpDir, "config.yaml")

		configContent := `
version: 1
isolation:
  defaults:
    vm:
      cpu: 8
      memory: 16384
      disk_size: 120
      base_image: "custom-image:latest"
    github:
      default_branch_prefix: "feature/"
    output:
      sync_dir: "~/my-output"
    proxy:
      mode: "on"
`
		if err := os.WriteFile(configPath, []byte(configContent), 0644); err != nil {
			t.Fatalf("Failed to write config file: %v", err)
		}

		cfg, err := LoadConfig(configPath, "")
		if err != nil {
			t.Fatalf("LoadConfig returned unexpected error: %v", err)
		}

		// Verify loaded values
		if cfg.Isolation.Defaults.VM.CPU != 8 {
			t.Errorf("Expected CPU 8, got %d", cfg.Isolation.Defaults.VM.CPU)
		}
		if cfg.Isolation.Defaults.VM.Memory != 16384 {
			t.Errorf("Expected Memory 16384, got %d", cfg.Isolation.Defaults.VM.Memory)
		}
		if cfg.Isolation.Defaults.VM.DiskSize != 120 {
			t.Errorf("Expected DiskSize 120, got %d", cfg.Isolation.Defaults.VM.DiskSize)
		}
		if cfg.Isolation.Defaults.VM.BaseImage != "custom-image:latest" {
			t.Errorf("Expected BaseImage 'custom-image:latest', got %s", cfg.Isolation.Defaults.VM.BaseImage)
		}
		if cfg.Isolation.Defaults.GitHub.DefaultBranchPrefix != "feature/" {
			t.Errorf("Expected DefaultBranchPrefix 'feature/', got %s", cfg.Isolation.Defaults.GitHub.DefaultBranchPrefix)
		}
		if cfg.Isolation.Defaults.Output.SyncDir != "~/my-output" {
			t.Errorf("Expected SyncDir '~/my-output', got %s", cfg.Isolation.Defaults.Output.SyncDir)
		}
		if cfg.Isolation.Defaults.Proxy.Mode != "on" {
			t.Errorf("Expected Proxy mode 'on', got %s", cfg.Isolation.Defaults.Proxy.Mode)
		}
	})

	// Test partial config file (some fields missing)
	t.Run("partial config file uses defaults for missing fields", func(t *testing.T) {
		tmpDir := t.TempDir()
		configPath := filepath.Join(tmpDir, "config.yaml")

		configContent := `
version: 1
isolation:
  defaults:
    vm:
      cpu: 8
      memory: 16384
`
		if err := os.WriteFile(configPath, []byte(configContent), 0644); err != nil {
			t.Fatalf("Failed to write config file: %v", err)
		}

		cfg, err := LoadConfig(configPath, "")
		if err != nil {
			t.Fatalf("LoadConfig returned unexpected error: %v", err)
		}

		// Verify loaded values
		if cfg.Isolation.Defaults.VM.CPU != 8 {
			t.Errorf("Expected CPU 8, got %d", cfg.Isolation.Defaults.VM.CPU)
		}
		if cfg.Isolation.Defaults.VM.Memory != 16384 {
			t.Errorf("Expected Memory 16384, got %d", cfg.Isolation.Defaults.VM.Memory)
		}
		// Verify defaults for missing fields
		if cfg.Isolation.Defaults.VM.DiskSize != 80 {
			t.Errorf("Expected DiskSize default 80, got %d", cfg.Isolation.Defaults.VM.DiskSize)
		}
		if cfg.Isolation.Defaults.VM.BaseImage != "ghcr.io/cirruslabs/macos-sequoia-base:latest" {
			t.Errorf("Expected BaseImage default, got %s", cfg.Isolation.Defaults.VM.BaseImage)
		}
	})

	// Test malformed YAML file (should return error)
	t.Run("malformed YAML returns error", func(t *testing.T) {
		tmpDir := t.TempDir()
		configPath := filepath.Join(tmpDir, "config.yaml")

		malformedContent := `
version: 1
isolation:
  defaults:
    vm:
      cpu: [this is not valid yaml syntax
`
		if err := os.WriteFile(configPath, []byte(malformedContent), 0644); err != nil {
			t.Fatalf("Failed to write malformed config: %v", err)
		}

		_, err := LoadConfig(configPath, "")
		if err == nil {
			t.Error("Expected error for malformed YAML, got nil")
		}
		if !strings.Contains(err.Error(), "failed to parse config file") {
			t.Errorf("Expected parse error message, got: %v", err)
		}
	})
}

func TestLoadVMConfig(t *testing.T) {
	// Test loading per-VM config
	t.Run("valid per-VM config overrides global config", func(t *testing.T) {
		tmpDir := t.TempDir()
		globalConfigPath := filepath.Join(tmpDir, "config.yaml")
		vmDir := filepath.Join(tmpDir, "vms", "test-vm")
		vmConfigPath := filepath.Join(vmDir, "vm.yaml")

		// Create global config
		globalConfigContent := `
version: 1
isolation:
  defaults:
    vm:
      cpu: 4
      memory: 8192
      disk_size: 80
`
		if err := os.WriteFile(globalConfigPath, []byte(globalConfigContent), 0644); err != nil {
			t.Fatalf("Failed to write global config: %v", err)
		}

		// Create VM config
		if err := os.MkdirAll(vmDir, 0755); err != nil {
			t.Fatalf("Failed to create VM directory: %v", err)
		}

		vmConfigContent := `
cpu: 8
memory: 16384
`
		if err := os.WriteFile(vmConfigPath, []byte(vmConfigContent), 0644); err != nil {
			t.Fatalf("Failed to write VM config: %v", err)
		}

		cfg, err := LoadConfig(globalConfigPath, vmConfigPath)
		if err != nil {
			t.Fatalf("LoadConfig returned unexpected error: %v", err)
		}

		// Verify VM config overrides global
		if cfg.Isolation.Defaults.VM.CPU != 8 {
			t.Errorf("Expected CPU 8 from VM config, got %d", cfg.Isolation.Defaults.VM.CPU)
		}
		if cfg.Isolation.Defaults.VM.Memory != 16384 {
			t.Errorf("Expected Memory 16384 from VM config, got %d", cfg.Isolation.Defaults.VM.Memory)
		}
		// Verify global default for missing field
		if cfg.Isolation.Defaults.VM.DiskSize != 80 {
			t.Errorf("Expected DiskSize 80 from global config, got %d", cfg.Isolation.Defaults.VM.DiskSize)
		}
	})

	// Test missing per-VM config (should use global/defaults)
	t.Run("missing per-VM config uses global config", func(t *testing.T) {
		tmpDir := t.TempDir()
		globalConfigPath := filepath.Join(tmpDir, "config.yaml")

		globalConfigContent := `
version: 1
isolation:
  defaults:
    vm:
      cpu: 8
      memory: 16384
`
		if err := os.WriteFile(globalConfigPath, []byte(globalConfigContent), 0644); err != nil {
			t.Fatalf("Failed to write global config: %v", err)
		}

		cfg, err := LoadConfig(globalConfigPath, "")
		if err != nil {
			t.Fatalf("LoadConfig returned unexpected error: %v", err)
		}

		// Verify global values are used
		if cfg.Isolation.Defaults.VM.CPU != 8 {
			t.Errorf("Expected CPU 8, got %d", cfg.Isolation.Defaults.VM.CPU)
		}
		if cfg.Isolation.Defaults.VM.Memory != 16384 {
			t.Errorf("Expected Memory 16384, got %d", cfg.Isolation.Defaults.VM.Memory)
		}
	})
}

func TestValidateConfig(t *testing.T) {
	t.Run("valid config passes validation", func(t *testing.T) {
		cfg := &Config{
			Version: 1,
			Isolation: IsolationConfig{
				Defaults: DefaultsConfig{
					VM: VMConfig{
						CPU:       4,
						Memory:    8192,
						DiskSize:  80,
						BaseImage: "ghcr.io/cirruslabs/macos-sequoia-base:latest",
					},
					Proxy: ProxyConfig{
						Mode: "auto",
					},
				},
			},
		}

		if err := cfg.Validate(""); err != nil {
			t.Errorf("Validate returned unexpected error: %v", err)
		}
	})

	t.Run("invalid CPU value fails validation", func(t *testing.T) {
		cfg := &Config{
			Version: 1,
			Isolation: IsolationConfig{
				Defaults: DefaultsConfig{
					VM: VMConfig{
						CPU: 0, // Invalid
					},
				},
			},
		}

		err := cfg.Validate("")
		if err == nil {
			t.Error("Expected validation error for invalid CPU, got nil")
		}
		expectedMsg := "Invalid CPU '0'"
		if err.Error()[:len(expectedMsg)] != expectedMsg {
			t.Errorf("Expected error message to start with '%s', got '%s'", expectedMsg, err.Error())
		}
	})

	t.Run("invalid memory value fails validation", func(t *testing.T) {
		cfg := &Config{
			Version: 1,
			Isolation: IsolationConfig{
				Defaults: DefaultsConfig{
					VM: VMConfig{
						CPU:    4,   // Valid
						Memory: 100, // Invalid (below 256 MB minimum)
					},
				},
			},
		}

		err := cfg.Validate("")
		if err == nil {
			t.Error("Expected validation error for invalid memory, got nil")
		}
		expectedMsg := "Invalid memory '100'"
		if err.Error()[:len(expectedMsg)] != expectedMsg {
			t.Errorf("Expected error message to start with '%s', got '%s'", expectedMsg, err.Error())
		}
	})

	t.Run("minimum valid memory passes validation", func(t *testing.T) {
		cfg := &Config{
			Version: 1,
			Isolation: IsolationConfig{
				Defaults: DefaultsConfig{
					VM: VMConfig{
						CPU:       4,
						Memory:    256, // Tart minimum (v2.4.3+)
						DiskSize:  80,
						BaseImage: "test-image",
					},
					Proxy: ProxyConfig{
						Mode: "auto",
					},
				},
			},
		}

		if err := cfg.Validate(""); err != nil {
			t.Errorf("Validate returned unexpected error for minimum valid memory: %v", err)
		}
	})

	t.Run("invalid disk size fails validation", func(t *testing.T) {
		cfg := &Config{
			Version: 1,
			Isolation: IsolationConfig{
				Defaults: DefaultsConfig{
					VM: VMConfig{
						CPU:      4,    // Valid
						Memory:   8192, // Valid
						DiskSize: 0,    // Invalid
					},
				},
			},
		}

		err := cfg.Validate("")
		if err == nil {
			t.Error("Expected validation error for invalid disk size, got nil")
		}
		expectedMsg := "Invalid disk_size '0'"
		if err.Error()[:len(expectedMsg)] != expectedMsg {
			t.Errorf("Expected error message to start with '%s', got '%s'", expectedMsg, err.Error())
		}
	})

	t.Run("invalid proxy mode fails validation", func(t *testing.T) {
		cfg := &Config{
			Version: 1,
			Isolation: IsolationConfig{
				Defaults: DefaultsConfig{
					VM: VMConfig{
						CPU:       4,                                              // Valid
						Memory:    8192,                                           // Valid
						DiskSize:  80,                                             // Valid
						BaseImage: "ghcr.io/cirruslabs/macos-sequoia-base:latest", // Valid
					},
					Proxy: ProxyConfig{
						Mode: "invalid", // Invalid
					},
				},
			},
		}

		err := cfg.Validate("")
		if err == nil {
			t.Error("Expected validation error for invalid proxy mode, got nil")
		}
		expectedMsg := "Invalid proxy mode 'invalid'"
		if err.Error()[:len(expectedMsg)] != expectedMsg {
			t.Errorf("Expected error message to start with '%s', got '%s'", expectedMsg, err.Error())
		}
	})

	t.Run("empty base image fails validation", func(t *testing.T) {
		cfg := &Config{
			Version: 1,
			Isolation: IsolationConfig{
				Defaults: DefaultsConfig{
					VM: VMConfig{
						CPU:       4,
						Memory:    8192,
						DiskSize:  80,
						BaseImage: "", // Invalid
					},
				},
			},
		}

		err := cfg.Validate("")
		if err == nil {
			t.Error("Expected validation error for empty base image, got nil")
		}
		expectedMsg := "Invalid base_image ''"
		if err.Error()[:len(expectedMsg)] != expectedMsg {
			t.Errorf("Expected error message to start with '%s', got '%s'", expectedMsg, err.Error())
		}
	})
}

func TestConfigPathValidation(t *testing.T) {
	t.Run("error message includes file path for global config", func(t *testing.T) {
		tmpDir := t.TempDir()
		configPath := filepath.Join(tmpDir, "config.yaml")

		cfg := &Config{
			Version: 1,
			Isolation: IsolationConfig{
				Defaults: DefaultsConfig{
					VM: VMConfig{
						CPU: 0,
					},
				},
			},
		}

		err := cfg.Validate(configPath)
		if err == nil {
			t.Error("Expected validation error, got nil")
		}
		if !strings.Contains(err.Error(), configPath) {
			t.Errorf("Expected error message to include config path '%s', got '%s'", configPath, err.Error())
		}
	})

	t.Run("error message includes file path for VM config", func(t *testing.T) {
		tmpDir := t.TempDir()
		vmConfigPath := filepath.Join(tmpDir, "vm.yaml")

		cfg := &Config{
			Version: 1,
			Isolation: IsolationConfig{
				Defaults: DefaultsConfig{
					VM: VMConfig{
						CPU: 0,
					},
				},
			},
		}

		err := cfg.Validate(vmConfigPath)
		if err == nil {
			t.Error("Expected validation error, got nil")
		}
		if !strings.Contains(err.Error(), vmConfigPath) {
			t.Errorf("Expected error message to include VM config path '%s', got '%s'", vmConfigPath, err.Error())
		}
	})
}
