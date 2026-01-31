.PHONY: build test lint install clean

# Build the cal binary
build:
	go build -o cal ./cmd/cal

# Run all tests
test:
	go test ./...

# Run staticcheck linter
lint:
	staticcheck ./...

# Install binary to GOPATH/bin or /usr/local/bin
install:
	@if [ -n "$$GOPATH" ]; then \
		go install ./cmd/cal; \
	else \
		go build -o /usr/local/bin/cal ./cmd/cal; \
	fi

# Clean build artifacts
clean:
	rm -f cal
	rm -f *.out
	rm -f *.test
	rm -rf test-output/
