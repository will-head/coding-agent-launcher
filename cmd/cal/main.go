package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var (
	// Version is set via ldflags during build
	Version = "dev"
)

var rootCmd = &cobra.Command{
	Use:   "cal",
	Short: "CAL - Coding Agent Launcher",
	Long: `CAL (Coding Agent Launcher) - VM-based sandbox for AI coding agents.

CAL provides isolated macOS VMs (via Tart) for running AI coding agents safely,
with automated setup, snapshot management, and GitHub workflow integration.`,
	Version: Version,
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
