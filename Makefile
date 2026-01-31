.PHONY: build test lint install clean

# Build the cal binary
build:
	go build -o cal ./cmd/cal

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
		go install ./cmd/cal; \
	else \
		go build -o /usr/local/bin/cal ./cmd/cal || { echo "Error: Failed to install to /usr/local/bin. Try with sudo or set GOPATH."; exit 1; }; \
	fi

# Clean build artifacts
clean:
	rm -f cal
	rm -f *.out
	rm -f *.test
	rm -rf test-output/
