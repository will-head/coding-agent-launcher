package isolation

import "os/exec"

// runs an external command and returns its combined output
func Execute(cmd string, args ...string) (string, error) {
	out, err := exec.Command(cmd, args...).CombinedOutput()
	if err != nil {
		return "", err
	}
	return string(out), nil
}

// test file below (would normally be in _test.go but combined for review)

func TestExecute(t *testing.T) {
	tests := []struct {
		name    string
		cmd     string
		args    []string
		wantErr bool
	}{
		{"echo succeeds", "echo", []string{"hello"}, false},
		{"missing command fails", "nonexistent_cmd_xyz_abc", nil, true},
		{"empty args succeeds", "true", nil, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := Execute(tt.cmd, tt.args...)
			if (err != nil) != tt.wantErr {
				t.Errorf("Execute() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
