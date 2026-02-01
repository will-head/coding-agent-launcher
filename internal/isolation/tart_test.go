// Package isolation provides VM isolation and management for CAL.
package isolation

import (
	"strings"
	"testing"
)

func TestExpandTilde(t *testing.T) {
	tests := []struct {
		name    string
		path    string
		wantErr bool
	}{
		{
			name:    "expand tilde",
			path:    "~/test/path",
			wantErr: false,
		},
		{
			name:    "no tilde",
			path:    "/absolute/path",
			wantErr: false,
		},
		{
			name:    "relative path without tilde",
			path:    "relative/path",
			wantErr: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := ExpandTilde(tt.path)
			if (err != nil) != tt.wantErr {
				t.Errorf("ExpandTilde() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !tt.wantErr && strings.HasPrefix(tt.path, "~") && !strings.Contains(got, "/") {
				t.Errorf("ExpandTilde() = %v, should expand tilde", got)
			}
		})
	}
}

func TestVMState_String(t *testing.T) {
	tests := []struct {
		name  string
		state VMState
	}{
		{"running", StateRunning},
		{"stopped", StateStopped},
		{"not_found", StateNotFound},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if string(tt.state) != tt.name {
				t.Errorf("VMState.String() = %v, want %v", string(tt.state), tt.name)
			}
		})
	}
}

func TestTartClient_Constants(t *testing.T) {
	if TartInstallPrompt == "" {
		t.Error("TartInstallPrompt should not be empty")
	}
	if cacheDirMount == "" {
		t.Error("cacheDirMount should not be empty")
	}
}

func TestTartClient_NewTartClient(t *testing.T) {
	client := NewTartClient()
	if client == nil {
		t.Fatal("NewTartClient() should return non-nil client")
	}
	if client.installPrompt == "" {
		t.Error("NewTartClient() should set installPrompt")
	}
	if client.pollInterval == 0 {
		t.Error("NewTartClient() should set pollInterval")
	}
	if client.pollTimeout == 0 {
		t.Error("NewTartClient() should set pollTimeout")
	}
}

func TestTartClient_Set(t *testing.T) {
	tests := []struct {
		name      string
		vmName    string
		cpu       int
		memory    int
		disk      string
		wantError bool
	}{
		{
			name:      "VM not found",
			vmName:    "nonexistent-vm",
			cpu:       4,
			memory:    8192,
			disk:      "80",
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := NewTartClient()
			if err := client.Set(tt.vmName, tt.cpu, tt.memory, tt.disk); (err != nil) != tt.wantError {
				t.Errorf("Set() error = %v, wantError %v", err, tt.wantError)
			}
		})
	}
}

func TestTartClient_Run(t *testing.T) {
	tests := []struct {
		name      string
		vmName    string
		headless  bool
		vnc       bool
		vncExp    bool
		dirs      []string
		wantError bool
	}{
		{
			name:      "VM not found - headless",
			vmName:    "nonexistent-vm",
			headless:  true,
			vnc:       false,
			vncExp:    false,
			wantError: true,
		},
		{
			name:      "VM not found - VNC experimental",
			vmName:    "nonexistent-vm",
			headless:  false,
			vnc:       false,
			vncExp:    true,
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := NewTartClient()
			if err := client.Run(tt.vmName, tt.headless, tt.vnc, tt.vncExp, tt.dirs); (err != nil) != tt.wantError {
				t.Errorf("Run() error = %v, wantError %v", err, tt.wantError)
			}
		})
	}
}

func TestTartClient_Stop(t *testing.T) {
	tests := []struct {
		name      string
		vmName    string
		force     bool
		wantError bool
	}{
		{
			name:      "VM not found",
			vmName:    "nonexistent-vm",
			force:     false,
			wantError: true,
		},
		{
			name:      "VM not found - force",
			vmName:    "nonexistent-vm",
			force:     true,
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := NewTartClient()
			if err := client.Stop(tt.vmName, tt.force); (err != nil) != tt.wantError {
				t.Errorf("Stop() error = %v, wantError %v", err, tt.wantError)
			}
		})
	}
}

func TestTartClient_Delete(t *testing.T) {
	tests := []struct {
		name      string
		vmName    string
		wantError bool
	}{
		{
			name:      "VM not found",
			vmName:    "nonexistent-vm",
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := NewTartClient()
			if err := client.Delete(tt.vmName); (err != nil) != tt.wantError {
				t.Errorf("Delete() error = %v, wantError %v", err, tt.wantError)
			}
		})
	}
}

func TestTartClient_List(t *testing.T) {
	client := NewTartClient()
	vms, err := client.List()
	if err != nil {
		t.Errorf("List() error = %v", err)
		return
	}
	if vms == nil {
		t.Error("List() returned nil, expected slice")
	}
}

func TestTartClient_IP(t *testing.T) {
	tests := []struct {
		name      string
		vmName    string
		wantError bool
	}{
		{
			name:      "VM not found",
			vmName:    "nonexistent-vm",
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := NewTartClient()
			ip, err := client.IP(tt.vmName, 0)
			if (err != nil) != tt.wantError {
				t.Errorf("IP() error = %v, wantError %v", err, tt.wantError)
			}
			if !tt.wantError && ip == "" {
				t.Error("IP() returned empty string")
			}
		})
	}
}

func TestTartClient_Get(t *testing.T) {
	tests := []struct {
		name      string
		vmName    string
		wantError bool
	}{
		{
			name:      "VM not found",
			vmName:    "nonexistent-vm",
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			client := NewTartClient()
			vm, err := client.Get(tt.vmName)
			if (err != nil) != tt.wantError {
				t.Errorf("Get() error = %v, wantError %v", err, tt.wantError)
			}
			if !tt.wantError && vm == nil {
				t.Error("Get() returned nil")
			}
		})
	}
}

func TestTartClient_IsRunning(t *testing.T) {
	client := NewTartClient()
	running := client.IsRunning("nonexistent-vm")
	if running {
		t.Error("IsRunning() returned true for nonexistent VM")
	}
}

func TestTartClient_Exists(t *testing.T) {
	client := NewTartClient()
	exists := client.Exists("nonexistent-vm")
	if exists {
		t.Error("Exists() returned true for nonexistent VM")
	}
}

func TestTartClient_GetState(t *testing.T) {
	client := NewTartClient()
	state := client.GetState("nonexistent-vm")
	if state != StateNotFound {
		t.Errorf("GetState() returned %v for nonexistent VM, expected %v", state, StateNotFound)
	}
}
