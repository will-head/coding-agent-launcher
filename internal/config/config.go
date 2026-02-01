package config

import (
	"fmt"
	"os"
	"path/filepath"

	"gopkg.in/yaml.v3"
)

const (
	minCPU         = 1
	maxCPU         = 32
	minMemory      = 2048
	maxMemory      = 65536
	minDiskSize    = 10
	maxDiskSize    = 500
	currentVersion = 1
)

type Config struct {
	Version   int             `yaml:"version"`
	Isolation IsolationConfig `yaml:"isolation"`
}

type IsolationConfig struct {
	Defaults DefaultsConfig `yaml:"defaults"`
}

type DefaultsConfig struct {
	VM     VMConfig     `yaml:"vm"`
	GitHub GitHubConfig `yaml:"github"`
	Output OutputConfig `yaml:"output"`
	Proxy  ProxyConfig  `yaml:"proxy"`
}

type VMConfig struct {
	CPU       int    `yaml:"cpu"`
	Memory    int    `yaml:"memory"`
	DiskSize  int    `yaml:"disk_size"`
	BaseImage string `yaml:"base_image"`
}

type GitHubConfig struct {
	DefaultBranchPrefix string `yaml:"default_branch_prefix"`
}

type OutputConfig struct {
	SyncDir string `yaml:"sync_dir"`
}

type ProxyConfig struct {
	Mode string `yaml:"mode"`
}

func LoadConfig(globalPath, vmPath string) (*Config, error) {
	cfg := &Config{
		Version: currentVersion,
		Isolation: IsolationConfig{
			Defaults: getHardcodedDefaults(),
		},
	}

	if globalPath != "" {
		if err := loadConfigFile(cfg, globalPath); err != nil {
			return nil, err
		}
	}

	if vmPath != "" {
		if err := loadVMConfigFile(cfg, vmPath); err != nil {
			return nil, err
		}
	}

	path := ""
	if vmPath != "" {
		path = vmPath
	} else if globalPath != "" {
		path = globalPath
	}

	if err := cfg.Validate(path); err != nil {
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
			SyncDir: "~/cal-output",
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

	var loaded Config
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

func mergeConfig(cfg *Config, loaded *Config) {
	if loaded.Isolation.Defaults.VM.CPU != 0 {
		cfg.Isolation.Defaults.VM.CPU = loaded.Isolation.Defaults.VM.CPU
	}
	if loaded.Isolation.Defaults.VM.Memory != 0 {
		cfg.Isolation.Defaults.VM.Memory = loaded.Isolation.Defaults.VM.Memory
	}
	if loaded.Isolation.Defaults.VM.DiskSize != 0 {
		cfg.Isolation.Defaults.VM.DiskSize = loaded.Isolation.Defaults.VM.DiskSize
	}
	if loaded.Isolation.Defaults.VM.BaseImage != "" {
		cfg.Isolation.Defaults.VM.BaseImage = loaded.Isolation.Defaults.VM.BaseImage
	}
	if loaded.Isolation.Defaults.GitHub.DefaultBranchPrefix != "" {
		cfg.Isolation.Defaults.GitHub.DefaultBranchPrefix = loaded.Isolation.Defaults.GitHub.DefaultBranchPrefix
	}
	if loaded.Isolation.Defaults.Output.SyncDir != "" {
		cfg.Isolation.Defaults.Output.SyncDir = loaded.Isolation.Defaults.Output.SyncDir
	}
	if loaded.Isolation.Defaults.Proxy.Mode != "" {
		cfg.Isolation.Defaults.Proxy.Mode = loaded.Isolation.Defaults.Proxy.Mode
	}
}

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

func GetDefaultConfigPath() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}
	return filepath.Join(homeDir, ".cal", "config.yaml"), nil
}

func GetVMConfigPath(vmName string) (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}
	return filepath.Join(homeDir, ".cal", "isolation", "vms", vmName, "vm.yaml"), nil
}
