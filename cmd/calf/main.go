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
	Use:   "calf",
	Short: "CALF - Coding Agent Loader Foundation",
	Long: `CALF (Coding Agent Loader Foundation) - VM-based sandbox for AI coding agents.

CALF provides isolated macOS VMs (via Tart) for running AI coding agents safely,
with automated setup, snapshot management, and GitHub workflow integration.`,
	Version: Version,
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
