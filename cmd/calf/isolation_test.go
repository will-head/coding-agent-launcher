package main

import (
	"bytes"
	"slices"
	"strings"
	"testing"

	"github.com/spf13/cobra"
	"github.com/will-head/coding-agent-launcher/internal/isolation"
)

// mockTartRunner is a test helper that simulates tart command execution.
type mockTartRunner struct {
	outputs    map[string]string
	errors     map[string]error
	calledWith [][]string
}

func (m *mockTartRunner) run(args ...string) (string, error) {
	key := strings.Join(args, " ")
	m.calledWith = append(m.calledWith, args)
	if err, ok := m.errors[key]; ok {
		return "", err
	}
	if out, ok := m.outputs[key]; ok {
		return out, nil
	}
	return "", nil
}

// setupIsolationInitCmd creates a fresh isolation command configured for testing.
func setupIsolationInitCmd(t *testing.T, mock *mockTartRunner, stdinContent string, args ...string) (*cobra.Command, *bytes.Buffer, *bytes.Buffer) {
	t.Helper()
	out, errOut := &bytes.Buffer{}, &bytes.Buffer{}
	tart := isolation.NewTartClient(
		isolation.WithTartPath("/mock/tart"),
		isolation.WithRunCommand(mock.run),
	)
	cmd := newIsolationCmd(tart, strings.NewReader(stdinContent))
	cmd.SetOut(out)
	cmd.SetErr(errOut)
	cmd.SetArgs(args)
	return cmd, out, errOut
}

func TestIsolationInitTwoStepFlow(t *testing.T) {
	t.Run("when both VMs exist and user declines replace and declines reinit should abort", func(t *testing.T) {
		// Arrange
		mock := &mockTartRunner{
			outputs: map[string]string{
				"list --format json": `[{"name":"calf-dev","state":"stopped"},{"name":"calf-init","state":"stopped"}]`,
			},
		}
		cmd, out, _ := setupIsolationInitCmd(t, mock, "n\nn\n", "init")

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(out.String(), "Aborted. Existing VMs not modified.") {
			t.Errorf("expected abort message in output, got: %s", out.String())
		}
	})

	t.Run("when both VMs exist and user declines replace and confirms reinit should delete both VMs", func(t *testing.T) {
		// Arrange
		mock := &mockTartRunner{
			outputs: map[string]string{
				"list --format json": `[{"name":"calf-dev","state":"stopped"},{"name":"calf-init","state":"stopped"}]`,
			},
		}
		cmd, out, _ := setupIsolationInitCmd(t, mock, "n\ny\n", "init")

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		deletedDev := slices.ContainsFunc(mock.calledWith, func(args []string) bool {
			return len(args) == 2 && args[0] == "delete" && args[1] == "calf-dev"
		})
		deletedInit := slices.ContainsFunc(mock.calledWith, func(args []string) bool {
			return len(args) == 2 && args[0] == "delete" && args[1] == "calf-init"
		})
		if !deletedDev {
			t.Error("expected calf-dev to be deleted, but delete was not called")
		}
		if !deletedInit {
			t.Error("expected calf-init to be deleted, but delete was not called")
		}
		if !strings.Contains(out.String(), "Initializing") {
			t.Errorf("expected init message after deletion, got: %s", out.String())
		}
	})

	t.Run("when yes flag set and both VMs exist should skip prompts and delete both VMs", func(t *testing.T) {
		// Arrange
		mock := &mockTartRunner{
			outputs: map[string]string{
				"list --format json": `[{"name":"calf-dev","state":"stopped"},{"name":"calf-init","state":"stopped"}]`,
			},
		}
		cmd, out, _ := setupIsolationInitCmd(t, mock, "", "init", "--yes")

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		deletedDev := slices.ContainsFunc(mock.calledWith, func(args []string) bool {
			return len(args) == 2 && args[0] == "delete" && args[1] == "calf-dev"
		})
		deletedInit := slices.ContainsFunc(mock.calledWith, func(args []string) bool {
			return len(args) == 2 && args[0] == "delete" && args[1] == "calf-init"
		})
		if !deletedDev {
			t.Error("expected calf-dev to be deleted without prompting, but delete was not called")
		}
		if !deletedInit {
			t.Error("expected calf-init to be deleted without prompting, but delete was not called")
		}
		if !strings.Contains(out.String(), "Initializing") {
			t.Errorf("expected init message after deletion, got: %s", out.String())
		}
	})

	t.Run("when calf-dev is running and reinit confirmed should stop before deleting", func(t *testing.T) {
		// Arrange
		mock := &mockTartRunner{
			outputs: map[string]string{
				"list --format json": `[{"name":"calf-dev","state":"running"},{"name":"calf-init","state":"stopped"}]`,
			},
		}
		cmd, _, _ := setupIsolationInitCmd(t, mock, "n\ny\n", "init")

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		stopIdx, deleteIdx := -1, -1
		for i, args := range mock.calledWith {
			if len(args) == 2 && args[0] == "stop" && args[1] == "calf-dev" {
				stopIdx = i
			}
			if len(args) == 2 && args[0] == "delete" && args[1] == "calf-dev" {
				deleteIdx = i
			}
		}
		if stopIdx == -1 || deleteIdx == -1 || stopIdx > deleteIdx {
			t.Errorf("expected stop before delete for calf-dev, calls: %v", mock.calledWith)
		}
	})

	t.Run("when calf-dev is stopped and reinit confirmed should delete without stopping", func(t *testing.T) {
		// Arrange
		mock := &mockTartRunner{
			outputs: map[string]string{
				"list --format json": `[{"name":"calf-dev","state":"stopped"},{"name":"calf-init","state":"stopped"}]`,
			},
		}
		cmd, _, _ := setupIsolationInitCmd(t, mock, "n\ny\n", "init")

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		stopped := slices.ContainsFunc(mock.calledWith, func(args []string) bool {
			return len(args) == 2 && args[0] == "stop" && args[1] == "calf-dev"
		})
		if stopped {
			t.Error("expected stop not to be called for an already-stopped calf-dev, but it was")
		}
	})

	t.Run("when both VMs exist and user confirms replace should not delete VMs", func(t *testing.T) {
		// Arrange
		mock := &mockTartRunner{
			outputs: map[string]string{
				"list --format json": `[{"name":"calf-dev","state":"stopped"},{"name":"calf-init","state":"stopped"}]`,
			},
		}
		cmd, out, _ := setupIsolationInitCmd(t, mock, "y\n", "init")

		// Act
		err := cmd.Execute()

		// Assert
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		deletedAnything := slices.ContainsFunc(mock.calledWith, func(args []string) bool {
			return len(args) >= 1 && args[0] == "delete"
		})
		if deletedAnything {
			t.Error("expected no VMs to be deleted when user chose replace, but delete was called")
		}
		if !strings.Contains(out.String(), "Replacing calf-init with current calf-dev") {
			t.Errorf("expected replace message in output, got: %s", out.String())
		}
	})
}
