package main

import (
	"github.com/spf13/cobra"
	"github.com/will-head/coding-agent-launcher/internal/isolation"
)

var cacheCmd = &cobra.Command{
	Use:   "cache",
	Short: "Manage package download caches",
	Long:  `Manage package download caches for faster VM bootstraps.`,
}

var cacheStatusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show cache status and sizes",
	Long:  `Display information about package download caches, including size, location, and availability.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		cm := isolation.NewCacheManager()
		return cm.Status(cmd.OutOrStdout())
	},
}

func init() {
	cacheCmd.AddCommand(cacheStatusCmd)
	rootCmd.AddCommand(cacheCmd)
}
