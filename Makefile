.PHONY: build test lint install clean

# Build the calf binary
build:
	go build -o calf ./cmd/calf

# Run all tests
test:
	go test ./...

# Run staticcheck linter
lint:
	@command -v staticcheck >/dev/null 2>&1 || { echo "Error: staticcheck is not installed. Run: go install honnef.co/go/tools/cmd/staticcheck@latest"; exit 1; }
	staticcheck ./...

# Install binary to GOPATH/bin or /usr/local/bin
install:
	@if [ -n "$$GOPATH" ]; then \
		go install ./cmd/calf; \
	else \
		go build -o /usr/local/bin/calf ./cmd/calf || { echo "Error: Failed to install to /usr/local/bin. Try with sudo or set GOPATH."; exit 1; }; \
	fi

# Clean build artifacts
clean:
	rm -f calf
	rm -f *.out
	rm -f *.test
	rm -rf test-output/
