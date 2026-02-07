package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"strings"

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

var cacheClearCmd = &cobra.Command{
	Use:   "clear",
	Short: "Clear package download caches",
	Long:  `Clear package download caches to free disk space. Prompts for confirmation before clearing each cache type.`,
	RunE:  runCacheClear,
}

var clearAll bool
var dryRun bool

func init() {
	cacheCmd.AddCommand(cacheStatusCmd)
	cacheCmd.AddCommand(cacheClearCmd)

	cacheClearCmd.Flags().BoolVarP(&clearAll, "all", "a", false, "Clear all caches without prompting (dangerous)")
	cacheClearCmd.Flags().BoolVar(&dryRun, "dry-run", false, "Show what would be cleared without actually clearing")

	rootCmd.AddCommand(cacheCmd)
}

func runCacheClear(cmd *cobra.Command, args []string) error {
	cm := isolation.NewCacheManager()

	cacheTypes := []struct {
		name    string
		getInfo func() (*isolation.CacheInfo, error)
	}{
		{"Homebrew", cm.GetHomebrewCacheInfo},
		{"npm", cm.GetNpmCacheInfo},
		{"Go", cm.GetGoCacheInfo},
		{"Git", cm.GetGitCacheInfo},
	}

	totalFreed := int64(0)
	clearedCount := 0
	totalCount := 0

	if clearAll && !dryRun {
		fmt.Println("Warning: Clearing all caches without confirmation")
		fmt.Println("This will slow down your next VM bootstrap!")
		fmt.Println()
	}

	if dryRun {
		fmt.Println("Dry run: Showing what would be cleared")
		fmt.Println()
	}

	reader := bufio.NewReader(os.Stdin)

	for _, ct := range cacheTypes {
		info, err := ct.getInfo()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error getting %s cache info: %v\n", ct.name, err)
			continue
		}

		if !info.Available {
			continue
		}

		totalCount++

		sizeStr := isolation.FormatBytes(info.Size)
		var shouldClear bool

		if clearAll {
			shouldClear = true
			if dryRun {
				fmt.Printf("Would clear %s cache (%s)\n", ct.name, sizeStr)
			} else {
				fmt.Printf("Clearing %s cache (%s)...\n", ct.name, sizeStr)
			}
		} else {
			fmt.Printf("Clear %s cache (%s)? [y/N]: ", ct.name, sizeStr)
			input, err := reader.ReadString('\n')
			if err != nil {
				if errors.Is(err, io.EOF) {
					shouldClear = false
					fmt.Printf("Skipping %s cache (EOF)\n", ct.name)
				} else {
					return fmt.Errorf("failed to read input: %w", err)
				}
			} else {
				shouldClear = strings.TrimSpace(strings.ToLower(input)) == "y"
			}
		}

		if shouldClear {
			var cleared bool
			var err error

			cacheType := strings.ToLower(ct.name)
			cleared, err = cm.Clear(cacheType, dryRun)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error clearing %s cache: %v\n", ct.name, err)
				continue
			}

			if cleared {
				totalFreed += info.Size
				clearedCount++
				if !clearAll && !dryRun {
					fmt.Printf("Cleared %s cache\n", ct.name)
				}
			}
		} else {
			if !clearAll {
				fmt.Printf("Skipping %s cache\n", ct.name)
			}
		}
		fmt.Println()
	}

	if totalCount == 0 {
		fmt.Println("No caches found to clear")
		return nil
	}

	if clearedCount == 0 {
		fmt.Println("No caches cleared")
		return nil
	}

	action := "Cleared"
	if dryRun {
		action = "Would clear"
	}

	fmt.Printf("%s %s (%d/%d caches)\n", action, isolation.FormatBytes(totalFreed), clearedCount, totalCount)

	if !dryRun && clearedCount > 0 {
		fmt.Println()
		fmt.Println("Warning: Next VM bootstrap will be slower")
		fmt.Println("Use 'calf cache status' to verify caches are empty")
	}

	return nil
}
