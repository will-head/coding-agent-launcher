// Package config provides configuration management for CALF.
// It supports loading from global (~/.calf/config.yaml) and per-VM
// (~/.calf/isolation/vms/{name}/vm.yaml) configuration files with
// proper precedence: hard-coded defaults → global config → per-VM config.
package config

import (
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

const (
	// Validation limits based on Tart's actual constraints.
	// Source: https://github.com/cirruslabs/tart/issues/692
	// Tart v2.4.3+ supports: CPU >= 1, Memory >= 256 MB
	//
	// Note: While Tart allows 256 MB minimum, practical macOS VMs
	// need 2GB+ memory. These are technical limits, not recommendations.
	minCPU      = 1     // Tart minimum (v2.4.3+)
	maxCPU      = 32    // Practical limit for M-series Max/Ultra
	minMemory   = 256   // Tart minimum in MB (v2.4.3+)
	maxMemory   = 65536 // 64 GB, practical limit
	minDiskSize = 10    // Reasonable minimum in GB
	maxDiskSize = 500   // Reasonable maximum in GB

	currentVersion = 1
)

// Config represents the top-level CALF configuration structure.
type Config struct {
	Version   int             `yaml:"version"`
	Isolation IsolationConfig `yaml:"isolation"`
}

// IsolationConfig contains isolation-specific settings.
type IsolationConfig struct {
	Defaults DefaultsConfig `yaml:"defaults"`
}

// DefaultsConfig holds default configuration values for various subsystems.
type DefaultsConfig struct {
	VM     VMConfig     `yaml:"vm"`
	GitHub GitHubConfig `yaml:"github"`
	Output OutputConfig `yaml:"output"`
	Proxy  ProxyConfig  `yaml:"proxy"`
}

// VMConfig specifies VM resource configuration.
type VMConfig struct {
	CPU       int    `yaml:"cpu"`       // Number of CPU cores
	Memory    int    `yaml:"memory"`    // Memory in MB
	DiskSize  int    `yaml:"disk_size"` // Disk size in GB
	BaseImage string `yaml:"base_image"`
}

// GitHubConfig contains GitHub-related settings.
type GitHubConfig struct {
	DefaultBranchPrefix string `yaml:"default_branch_prefix"`
}

// OutputConfig specifies output synchronization settings.
type OutputConfig struct {
	SyncDir string `yaml:"sync_dir"`
}

// ProxyConfig contains proxy mode settings.
type ProxyConfig struct {
	Mode string `yaml:"mode"` // One of: auto, on, off
}

// LoadConfig loads configuration from global and per-VM paths with proper precedence.
// If paths are empty or files don't exist, hard-coded defaults are used.
// Per-VM config overrides global config, which overrides defaults.
// Returns error if files exist but cannot be read/parsed, or if validation fails.
func LoadConfig(globalPath, vmPath string) (*Config, error) {
	cfg := &Config{
		Version: currentVersion,
		Isolation: IsolationConfig{
			Defaults: getHardcodedDefaults(),
		},
	}

	// Load global config if path provided
	if globalPath != "" {
		if err := loadConfigFile(cfg, globalPath); err != nil {
			return nil, err
		}
	}

	// Load per-VM config if path provided (overrides global)
	if vmPath != "" {
		if err := loadVMConfigFile(cfg, vmPath); err != nil {
			return nil, err
		}
	}

	// Use the most specific path for validation error messages
	validationPath := ""
	if vmPath != "" {
		validationPath = vmPath
	} else if globalPath != "" {
		validationPath = globalPath
	}

	if err := cfg.Validate(validationPath); err != nil {
		return nil, err
	}

	return cfg, nil
}

func getHardcodedDefaults() DefaultsConfig {
	return DefaultsConfig{
		VM: VMConfig{
			CPU:       4,
			Memory:    8192,
			DiskSize:  80,
			BaseImage: "ghcr.io/cirruslabs/macos-sequoia-base:latest",
		},
		GitHub: GitHubConfig{
			DefaultBranchPrefix: "agent/",
		},
		Output: OutputConfig{
			SyncDir: "~/calf-output",
		},
		Proxy: ProxyConfig{
			Mode: "auto",
		},
	}
}

func loadConfigFile(cfg *Config, path string) error {
	data, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("failed to read config file '%s': %w", path, err)
	}

	var loaded struct {
		Version   *int `yaml:"version"`
		Isolation struct {
			Defaults struct {
				VM struct {
					CPU       *int    `yaml:"cpu"`
					Memory    *int    `yaml:"memory"`
					DiskSize  *int    `yaml:"disk_size"`
					BaseImage *string `yaml:"base_image"`
				} `yaml:"vm"`
				GitHub struct {
					DefaultBranchPrefix *string `yaml:"default_branch_prefix"`
				} `yaml:"github"`
				Output struct {
					SyncDir *string `yaml:"sync_dir"`
				} `yaml:"output"`
				Proxy struct {
					Mode *string `yaml:"mode"`
				} `yaml:"proxy"`
			} `yaml:"defaults"`
		} `yaml:"isolation"`
	}

	if err := yaml.Unmarshal(data, &loaded); err != nil {
		return fmt.Errorf("failed to parse config file '%s': %w", path, err)
	}

	mergeConfig(cfg, &loaded)
	return nil
}

func loadVMConfigFile(cfg *Config, path string) error {
	data, err := os.ReadFile(path)
	if os.IsNotExist(err) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("failed to read VM config file '%s': %w", path, err)
	}

	var vmConfig struct {
		CPU       *int   `yaml:"cpu"`
		Memory    *int   `yaml:"memory"`
		DiskSize  *int   `yaml:"disk_size"`
		BaseImage string `yaml:"base_image"`
	}

	if err := yaml.Unmarshal(data, &vmConfig); err != nil {
		return fmt.Errorf("failed to parse VM config file '%s': %w", path, err)
	}

	if vmConfig.CPU != nil {
		cfg.Isolation.Defaults.VM.CPU = *vmConfig.CPU
	}
	if vmConfig.Memory != nil {
		cfg.Isolation.Defaults.VM.Memory = *vmConfig.Memory
	}
	if vmConfig.DiskSize != nil {
		cfg.Isolation.Defaults.VM.DiskSize = *vmConfig.DiskSize
	}
	if vmConfig.BaseImage != "" {
		cfg.Isolation.Defaults.VM.BaseImage = vmConfig.BaseImage
	}

	return nil
}

func mergeConfig(cfg *Config, loaded *struct {
	Version   *int `yaml:"version"`
	Isolation struct {
		Defaults struct {
			VM struct {
				CPU       *int    `yaml:"cpu"`
				Memory    *int    `yaml:"memory"`
				DiskSize  *int    `yaml:"disk_size"`
				BaseImage *string `yaml:"base_image"`
			} `yaml:"vm"`
			GitHub struct {
				DefaultBranchPrefix *string `yaml:"default_branch_prefix"`
			} `yaml:"github"`
			Output struct {
				SyncDir *string `yaml:"sync_dir"`
			} `yaml:"output"`
			Proxy struct {
				Mode *string `yaml:"mode"`
			} `yaml:"proxy"`
		} `yaml:"defaults"`
	} `yaml:"isolation"`
}) {
	if loaded.Isolation.Defaults.VM.CPU != nil {
		cfg.Isolation.Defaults.VM.CPU = *loaded.Isolation.Defaults.VM.CPU
	}
	if loaded.Isolation.Defaults.VM.Memory != nil {
		cfg.Isolation.Defaults.VM.Memory = *loaded.Isolation.Defaults.VM.Memory
	}
	if loaded.Isolation.Defaults.VM.DiskSize != nil {
		cfg.Isolation.Defaults.VM.DiskSize = *loaded.Isolation.Defaults.VM.DiskSize
	}
	if loaded.Isolation.Defaults.VM.BaseImage != nil {
		cfg.Isolation.Defaults.VM.BaseImage = *loaded.Isolation.Defaults.VM.BaseImage
	}
	if loaded.Isolation.Defaults.GitHub.DefaultBranchPrefix != nil {
		cfg.Isolation.Defaults.GitHub.DefaultBranchPrefix = *loaded.Isolation.Defaults.GitHub.DefaultBranchPrefix
	}
	if loaded.Isolation.Defaults.Output.SyncDir != nil {
		cfg.Isolation.Defaults.Output.SyncDir = *loaded.Isolation.Defaults.Output.SyncDir
	}
	if loaded.Isolation.Defaults.Proxy.Mode != nil {
		cfg.Isolation.Defaults.Proxy.Mode = *loaded.Isolation.Defaults.Proxy.Mode
	}
}

// Validate checks that all configuration values are within valid ranges.
// Returns a detailed error message including field name, invalid value,
// expected range, and file path (if provided).
func (c *Config) Validate(path string) error {
	if c.Isolation.Defaults.VM.CPU < minCPU || c.Isolation.Defaults.VM.CPU > maxCPU {
		return c.validationError("CPU", c.Isolation.Defaults.VM.CPU, fmt.Sprintf("between %d and %d", minCPU, maxCPU), path)
	}
	if c.Isolation.Defaults.VM.Memory < minMemory || c.Isolation.Defaults.VM.Memory > maxMemory {
		return c.validationError("memory", c.Isolation.Defaults.VM.Memory, fmt.Sprintf("between %d and %d MB", minMemory, maxMemory), path)
	}
	if c.Isolation.Defaults.VM.DiskSize < minDiskSize || c.Isolation.Defaults.VM.DiskSize > maxDiskSize {
		return c.validationError("disk_size", c.Isolation.Defaults.VM.DiskSize, fmt.Sprintf("between %d and %d GB", minDiskSize, maxDiskSize), path)
	}
	if c.Isolation.Defaults.VM.BaseImage == "" {
		return c.validationError("base_image", c.Isolation.Defaults.VM.BaseImage, "a non-empty string", path)
	}
	if c.Isolation.Defaults.Proxy.Mode != "auto" && c.Isolation.Defaults.Proxy.Mode != "on" && c.Isolation.Defaults.Proxy.Mode != "off" {
		return c.validationError("proxy mode", c.Isolation.Defaults.Proxy.Mode, "one of: auto, on, off", path)
	}
	return nil
}

func (c *Config) validationError(field string, value interface{}, expected string, path string) error {
	if path != "" {
		return fmt.Errorf("Invalid %s '%v' in %s: must be %s", field, value, path, expected)
	}
	return fmt.Errorf("Invalid %s '%v': must be %s", field, value, expected)
}

// GetDefaultConfigPath returns the path to the global config file (~/.calf/config.yaml).
func GetDefaultConfigPath() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}
	return filepath.Join(homeDir, ".calf", "config.yaml"), nil
}

// GetVMConfigPath returns the path to a specific VM's config file
// (~/.calf/isolation/vms/{vmName}/vm.yaml).
func GetVMConfigPath(vmName string) (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}
	return filepath.Join(homeDir, ".calf", "isolation", "vms", vmName, "vm.yaml"), nil
}
