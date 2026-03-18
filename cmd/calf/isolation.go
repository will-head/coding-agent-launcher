package main

import (
	"bufio"
	"fmt"
	"io"
	"strings"

	"github.com/spf13/cobra"
	"github.com/will-head/coding-agent-loader/internal/isolation"
)

// newIsolationCmd creates the isolation command group with injectable tart client and stdin.
func newIsolationCmd(tart *isolation.TartClient, stdin io.Reader) *cobra.Command {
	isolationCmd := &cobra.Command{
		Use:     "isolation",
		Aliases: []string{"iso"},
		Short:   "Manage isolation VMs",
		Long:    `Manage CALF isolation VMs (calf-dev and calf-init) via Tart.`,
	}

	var skipConfirm bool

	initCmd := &cobra.Command{
		Use:   "init",
		Short: "Initialize isolation VMs",
		Long:  `Initialize CALF isolation VMs. Creates calf-dev from the base image and calf-init as a snapshot.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			return runIsolationInit(cmd, tart, stdin, skipConfirm)
		},
	}
	initCmd.Flags().BoolVarP(&skipConfirm, "yes", "y", false, "Skip all confirmation prompts")

	isolationCmd.AddCommand(initCmd)
	return isolationCmd
}

// runIsolationInit implements the two-step init flow when VMs already exist.
func runIsolationInit(cmd *cobra.Command, tart *isolation.TartClient, stdin io.Reader, skipConfirm bool) error {
	devExists := tart.Exists("calf-dev")
	initExists := tart.Exists("calf-init")

	if devExists && initExists && !skipConfirm {
		// Step 1: offer to replace calf-init with current calf-dev
		fmt.Fprintf(cmd.OutOrStdout(), "Do you want to replace calf-init with current calf-dev? (y/N) ")
		reader := bufio.NewReader(stdin)
		reply, _ := reader.ReadString('\n')
		reply = strings.TrimSpace(strings.ToLower(reply))
		if reply == "y" || reply == "yes" {
			// TODO: implement replace calf-init from calf-dev (1.6)
			fmt.Fprintln(cmd.OutOrStdout(), "Replacing calf-init with current calf-dev...")
			return nil
		}

		// Step 2: offer full reinit (delete both VMs and start fresh)
		fmt.Fprintf(cmd.OutOrStdout(), "Delete calf-dev and calf-init, then re-initialize? (y/N) ")
		reply, _ = reader.ReadString('\n')
		reply = strings.TrimSpace(strings.ToLower(reply))
		if reply != "y" && reply != "yes" {
			fmt.Fprintln(cmd.OutOrStdout(), "Aborted. Existing VMs not modified.")
			return nil
		}
	}

	if devExists || initExists {
		// TODO: git safety check before deleting VMs (1.7)
		if devExists {
			if tart.IsRunning("calf-dev") {
				if err := tart.Stop("calf-dev", false); err != nil {
					return fmt.Errorf("failed to stop calf-dev: %w", err)
				}
			}
			if err := tart.Delete("calf-dev"); err != nil {
				return fmt.Errorf("failed to delete calf-dev: %w", err)
			}
		}
		if initExists {
			if err := tart.Delete("calf-init"); err != nil {
				return fmt.Errorf("failed to delete calf-init: %w", err)
			}
		}
	}

	// TODO: implement full init from base image (1.6)
	fmt.Fprintln(cmd.OutOrStdout(), "Initializing VMs...")
	return nil
}
