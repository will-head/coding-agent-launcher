package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/will-head/coding-agent-launcher/internal/config"
)

var vmName string

var configCmd = &cobra.Command{
	Use:   "config",
	Short: "Manage CALF configuration",
}

var configShowCmd = &cobra.Command{
	Use:   "show",
	Short: "Display effective configuration",
	Run:   runConfigShow,
}

func init() {
	configShowCmd.Flags().StringVarP(&vmName, "vm", "v", "", "VM name to show config for")
	configCmd.AddCommand(configShowCmd)
	rootCmd.AddCommand(configCmd)
}

func runConfigShow(cmd *cobra.Command, args []string) {
	globalConfigPath, err := config.GetDefaultConfigPath()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}

	var vmConfigPath string
	if vmName != "" {
		vmConfigPath, err = config.GetVMConfigPath(vmName)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	}

	cfg, err := config.LoadConfig(globalConfigPath, vmConfigPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error loading configuration: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("CALF Configuration")
	fmt.Println("=================")
	fmt.Println()

	fmt.Println("VM Defaults:")
	fmt.Printf("  CPU: %d cores\n", cfg.Isolation.Defaults.VM.CPU)
	fmt.Printf("  Memory: %d MB\n", cfg.Isolation.Defaults.VM.Memory)
	fmt.Printf("  Disk Size: %d GB\n", cfg.Isolation.Defaults.VM.DiskSize)
	fmt.Printf("  Base Image: %s\n", cfg.Isolation.Defaults.VM.BaseImage)
	fmt.Println()

	fmt.Println("GitHub:")
	fmt.Printf("  Default Branch Prefix: %s\n", cfg.Isolation.Defaults.GitHub.DefaultBranchPrefix)
	fmt.Println()

	fmt.Println("Output:")
	fmt.Printf("  Sync Directory: %s\n", cfg.Isolation.Defaults.Output.SyncDir)
	fmt.Println()

	fmt.Println("Proxy:")
	fmt.Printf("  Mode: %s\n", cfg.Isolation.Defaults.Proxy.Mode)
	fmt.Println()

	if vmName != "" {
		fmt.Printf("(Showing config for VM: %s)\n", vmName)
	} else {
		fmt.Println("(Showing global config)")
	}
}
