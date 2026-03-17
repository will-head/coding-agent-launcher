package main

import (
	"bytes"
	"strings"
	"testing"
)

// setupRootCmd wires rootCmd for testing with captured stdout/stderr.
// All state is automatically restored via t.Cleanup.
func setupRootCmd(t *testing.T, args ...string) (out, errOut *bytes.Buffer) {
	t.Helper()
	out = &bytes.Buffer{}
	errOut = &bytes.Buffer{}
	rootCmd.SetOut(out)
	rootCmd.SetErr(errOut)
	t.Cleanup(func() {
		rootCmd.SetOut(nil)
		rootCmd.SetErr(nil)
	})
	rootCmd.SetArgs(args)
	t.Cleanup(func() { rootCmd.SetArgs(nil) })
	return out, errOut
}

func TestRootCommand(t *testing.T) {
	t.Run("when no args provided should print usage information", func(t *testing.T) {
		// Arrange
		out, _ := setupRootCmd(t)

		// Act
		err := rootCmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Usage:") {
			t.Errorf("expected usage information in output, got: %s", out.String())
		}
	})

	t.Run("when help flag provided should print help text", func(t *testing.T) {
		// Arrange
		out, _ := setupRootCmd(t, "--help")

		// Act
		err := rootCmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "CALF") {
			t.Errorf("expected CALF in help output, got: %s", out.String())
		}
	})

	t.Run("when unknown subcommand provided should return error", func(t *testing.T) {
		// Arrange
		_, _ = setupRootCmd(t, "unknowncmd")

		// Act
		err := rootCmd.Execute()

		// Assert
		if err == nil {
			t.Fatal("expected error for unknown subcommand, got nil")
		}
	})
}

func TestConfigSubcommand(t *testing.T) {
	t.Run("when config subcommand provided should be recognized", func(t *testing.T) {
		// Arrange
		out, _ := setupRootCmd(t, "config")

		// Act
		err := rootCmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("expected config subcommand to be recognized, got error: %v", err)
		}
		if !strings.Contains(out.String(), "config") {
			t.Errorf("expected config in output, got: %s", out.String())
		}
	})
}

func TestCacheSubcommand(t *testing.T) {
	t.Run("when cache subcommand provided should be recognized", func(t *testing.T) {
		// Arrange
		out, _ := setupRootCmd(t, "cache")

		// Act
		err := rootCmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("expected cache subcommand to be recognized, got error: %v", err)
		}
		if !strings.Contains(out.String(), "cache") {
			t.Errorf("expected cache in output, got: %s", out.String())
		}
	})
}
