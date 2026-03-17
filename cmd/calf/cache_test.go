package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/spf13/cobra"
)

func setupCacheCmd(t *testing.T, stdin string, args ...string) (*cobra.Command, *bytes.Buffer, *bytes.Buffer) {
	t.Helper()
	home := t.TempDir()
	out := &bytes.Buffer{}
	errOut := &bytes.Buffer{}
	cmd := newCacheCmd(strings.NewReader(stdin), home)
	cmd.SetOut(out)
	cmd.SetErr(errOut)
	cmd.SetArgs(args)
	return cmd, out, errOut
}

func setupCacheCmdWithDirs(t *testing.T, stdin string, cacheTypes []string, args ...string) (*cobra.Command, *bytes.Buffer, *bytes.Buffer, string) {
	t.Helper()
	home := t.TempDir()
	for _, ct := range cacheTypes {
		dir := filepath.Join(home, ".calf-cache", ct)
		if err := os.MkdirAll(dir, 0755); err != nil {
			t.Fatalf("failed to create cache dir %s: %v", ct, err)
		}
	}
	out := &bytes.Buffer{}
	errOut := &bytes.Buffer{}
	cmd := newCacheCmd(strings.NewReader(stdin), home)
	cmd.SetOut(out)
	cmd.SetErr(errOut)
	cmd.SetArgs(args)
	return cmd, out, errOut, home
}

func TestCacheClear(t *testing.T) {
	t.Run("when force flag set should clear without prompting for confirmation", func(t *testing.T) {
		// Arrange
		cmd, out, _ := setupCacheCmd(t, "", "clear", "--all", "--force")

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "No caches found to clear") {
			t.Errorf("expected 'No caches found to clear' output, got: %s", out.String())
		}
	})

	t.Run("when dry run flag set should not delete any files", func(t *testing.T) {
		// Arrange
		allTypes := []string{"homebrew", "npm", "go", "git"}
		cmd, _, _, home := setupCacheCmdWithDirs(t, "", allTypes, "clear", "--all", "--dry-run")
		testFile := filepath.Join(home, ".calf-cache", "homebrew", "testpkg.tar.gz")
		if err := os.WriteFile(testFile, []byte("data"), 0644); err != nil {
			t.Fatal(err)
		}

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if _, statErr := os.Stat(testFile); os.IsNotExist(statErr) {
			t.Error("expected test file to still exist after dry run, but it was deleted")
		}
	})

	t.Run("when dry run flag set should output what would be cleared", func(t *testing.T) {
		// Arrange
		allTypes := []string{"homebrew", "npm", "go", "git"}
		cmd, out, _, _ := setupCacheCmdWithDirs(t, "", allTypes, "clear", "--all", "--dry-run")

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Would clear") {
			t.Errorf("expected 'Would clear' in dry run output, got: %s", out.String())
		}
	})

	t.Run("when all flag set and user confirms should clear all cache types", func(t *testing.T) {
		// Arrange
		allTypes := []string{"homebrew", "npm", "go", "git"}
		cmd, out, _, _ := setupCacheCmdWithDirs(t, "y\n", allTypes, "clear", "--all")

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Cleared") {
			t.Errorf("expected 'Cleared' in output, got: %s", out.String())
		}
	})

	t.Run("when all flag set and user declines should abort without deleting files", func(t *testing.T) {
		// Arrange
		allTypes := []string{"homebrew", "npm", "go", "git"}
		cmd, out, _, home := setupCacheCmdWithDirs(t, "n\n", allTypes, "clear", "--all")
		testFile := filepath.Join(home, ".calf-cache", "homebrew", "testpkg.tar.gz")
		if err := os.WriteFile(testFile, []byte("data"), 0644); err != nil {
			t.Fatal(err)
		}

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Aborted") {
			t.Errorf("expected 'Aborted' in output, got: %s", out.String())
		}
		if _, statErr := os.Stat(testFile); os.IsNotExist(statErr) {
			t.Error("expected cache file to still exist after decline, but it was deleted")
		}
	})

	t.Run("when homebrew type flag set should clear only homebrew cache", func(t *testing.T) {
		// Arrange
		allTypes := []string{"homebrew", "npm", "go", "git"}
		cmd, out, _, home := setupCacheCmdWithDirs(t, "", allTypes, "clear", "--homebrew")
		npmFile := filepath.Join(home, ".calf-cache", "npm", "pkg.tgz")
		if err := os.WriteFile(npmFile, []byte("data"), 0644); err != nil {
			t.Fatal(err)
		}

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Homebrew") {
			t.Errorf("expected 'Homebrew' in output, got: %s", out.String())
		}
		if _, statErr := os.Stat(npmFile); os.IsNotExist(statErr) {
			t.Error("expected npm cache file to remain untouched, but it was deleted")
		}
	})

	t.Run("when npm type flag set should clear only npm cache", func(t *testing.T) {
		// Arrange
		allTypes := []string{"homebrew", "npm", "go", "git"}
		cmd, out, _, home := setupCacheCmdWithDirs(t, "", allTypes, "clear", "--npm")
		homebrewFile := filepath.Join(home, ".calf-cache", "homebrew", "pkg.bottle.tar.gz")
		if err := os.WriteFile(homebrewFile, []byte("data"), 0644); err != nil {
			t.Fatal(err)
		}

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "npm") {
			t.Errorf("expected 'npm' in output, got: %s", out.String())
		}
		if _, statErr := os.Stat(homebrewFile); os.IsNotExist(statErr) {
			t.Error("expected homebrew cache file to remain untouched, but it was deleted")
		}
	})

	t.Run("when go type flag set should clear only go cache", func(t *testing.T) {
		// Arrange
		allTypes := []string{"homebrew", "npm", "go", "git"}
		cmd, out, _, home := setupCacheCmdWithDirs(t, "", allTypes, "clear", "--go")
		npmFile := filepath.Join(home, ".calf-cache", "npm", "pkg.tgz")
		if err := os.WriteFile(npmFile, []byte("data"), 0644); err != nil {
			t.Fatal(err)
		}

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Go") {
			t.Errorf("expected 'Go' in output, got: %s", out.String())
		}
		if _, statErr := os.Stat(npmFile); os.IsNotExist(statErr) {
			t.Error("expected npm cache file to remain untouched, but it was deleted")
		}
	})

	t.Run("when git type flag set should clear only git cache", func(t *testing.T) {
		// Arrange
		allTypes := []string{"homebrew", "npm", "go", "git"}
		cmd, out, _, home := setupCacheCmdWithDirs(t, "", allTypes, "clear", "--git")
		npmFile := filepath.Join(home, ".calf-cache", "npm", "pkg.tgz")
		if err := os.WriteFile(npmFile, []byte("data"), 0644); err != nil {
			t.Fatal(err)
		}

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Git") {
			t.Errorf("expected 'Git' in output, got: %s", out.String())
		}
		if _, statErr := os.Stat(npmFile); os.IsNotExist(statErr) {
			t.Error("expected npm cache file to remain untouched, but it was deleted")
		}
	})

	t.Run("when homebrew type flag set with dry run should not delete files", func(t *testing.T) {
		// Arrange
		cmd, out, _, home := setupCacheCmdWithDirs(t, "", []string{"homebrew"}, "clear", "--homebrew", "--dry-run")
		testFile := filepath.Join(home, ".calf-cache", "homebrew", "pkg.bottle.tar.gz")
		if err := os.WriteFile(testFile, []byte("data"), 0644); err != nil {
			t.Fatal(err)
		}

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Would clear") {
			t.Errorf("expected 'Would clear' in output, got: %s", out.String())
		}
		if _, statErr := os.Stat(testFile); os.IsNotExist(statErr) {
			t.Error("expected homebrew cache file to still exist after dry run, but it was deleted")
		}
	})

	t.Run("when all and force flags set should clear all types without prompting", func(t *testing.T) {
		// Arrange
		allTypes := []string{"homebrew", "npm", "go", "git"}
		cmd, out, _, _ := setupCacheCmdWithDirs(t, "", allTypes, "clear", "--all", "--force")

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Cleared") {
			t.Errorf("expected 'Cleared' in output, got: %s", out.String())
		}
		if strings.Contains(out.String(), "Are you sure") {
			t.Errorf("expected no confirmation prompt with --force, got: %s", out.String())
		}
	})

	t.Run("when all and dry run flags set should report all types without deleting", func(t *testing.T) {
		// Arrange
		allTypes := []string{"homebrew", "npm", "go", "git"}
		cmd, out, _, home := setupCacheCmdWithDirs(t, "", allTypes, "clear", "--all", "--dry-run")
		testFile := filepath.Join(home, ".calf-cache", "git", "repo.bundle")
		if err := os.WriteFile(testFile, []byte("data"), 0644); err != nil {
			t.Fatal(err)
		}

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Would clear") {
			t.Errorf("expected 'Would clear' in output, got: %s", out.String())
		}
		if _, statErr := os.Stat(testFile); os.IsNotExist(statErr) {
			t.Error("expected git cache file to still exist after dry run, but it was deleted")
		}
	})
}
