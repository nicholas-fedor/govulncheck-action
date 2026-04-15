<!-- markdownlint-disable -->
<div align="center">

# govulncheck-action

<!-- markdownlint-restore -->
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/nicholas-fedor/govulncheck-action/badge)](https://scorecard.dev/viewer/?uri=github.com/nicholas-fedor/govulncheck-action)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/31b33e083b1c48e0af7564d6fce1a78c)](https://app.codacy.com/gh/nicholas-fedor/govulncheck-action/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
![GitHub Tag](https://img.shields.io/github/v/tag/nicholas-fedor/govulncheck-action)
![GitHub License](https://img.shields.io/github/license/nicholas-fedor/govulncheck-action)

</div>

A GitHub Action that runs [govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) to detect known vulnerabilities in Go dependencies.

This action uses **static analysis** to identify only those vulnerabilities that could actually affect your application, reducing noise from irrelevant findings.

For detailed information about govulncheck's capabilities, flags, and limitations, see the [official govulncheck documentation](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck).

## Quick Start

```yaml
name: Run Go Security Check
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  OUTPUT_FILE: results.sarif

jobs:
  govulncheck:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
      - name: Run govulncheck
        uses: nicholas-fedor/govulncheck-action@19e2c8d03c343967529f5116faf90a3d64718f3d
        with:
          output-format: sarif
          output-file: ${{ env.OUTPUT_FILE }}
          go-version-file: "go.mod"

      - name: Upload SARIF file
        uses: github/codeql-action/upload-sarif@v4
        with:
          sarif_file: ${{ env.OUTPUT_FILE }}
```

## Running Locally

To run `govulncheck` locally before using the action:

1. Install govulncheck:

   ```bash
   go install golang.org/x/vuln/cmd/govulncheck@latest
   ```

2. Run `govulncheck` from your project's root directory:

   ```bash
   govulncheck ./...
   ```

For detailed information about govulncheck's capabilities, flags, and limitations, see the [official govulncheck documentation](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck).

## Configuration

### Go Environment

| Input                   | Description                                                      | Default    |
|-------------------------|------------------------------------------------------------------|------------|
| `setup-go`              | Setup Go via actions/setup-go                                    | `true`     |
| `repo-checkout`         | Checkout the repository                                          | `true`     |
| `go-version-input`      | Go version to use                                                | `"stable"` |
| `go-version-file`       | Path to go.mod or go.work                                        | -          |
| `check-latest`          | Always check for latest Go version                               | `true`     |
| `cache`                 | Enable Go module caching                                         | `true`     |
| `cache-dependency-path` | Path to dependency file for caching (e.g., go.sum for monorepos) | `""`       |

### Scan Options

| Input           | Description                                                                                     | Default    |
|-----------------|-------------------------------------------------------------------------------------------------|------------|
| `go-package`    | Go package to scan (or binary path for binary mode)                                             | `"./..."`  |
| `work-dir`      | Working directory                                                                               | `"."`      |
| `scan-level`    | Scanning detail level: module, package, or symbol                                               | `"symbol"` |
| `include-tests` | Include test files in vulnerability analysis (ignored in binary mode)                           | `false`    |
| `build-tags`    | Comma-separated list of build tags                                                              | `""`       |
| `db-url`        | Custom vulnerability database URL                                                               | `""`       |
| `mode`          | Scan mode: source, binary, or extract                                                           | `"source"` |
| `show`          | Show additional info: traces (full call stack), verbose (progress). Only valid for text format. | `""`       |

### Output Options

| Input           | Description                               | Default  |
|-----------------|-------------------------------------------|----------|
| `output-format` | Output format: text, json, sarif, openvex | `"text"` |
| `output-file`   | Output file path                          | `""`     |

### Scan Level

The `scan-level` input controls the detail level of the vulnerability analysis:

| Level     | Description                                                                |
|-----------|----------------------------------------------------------------------------|
| `symbol`  | Most detailed - analyzes at function symbol level (default, most accurate) |
| `package` | Analyzes at package level                                                  |
| `module`  | Least detailed - analyzes at module level (fastest)                        |

### Scan Mode

The `mode` input specifies how to analyze the code:

| Mode      | Description                                             |
|-----------|---------------------------------------------------------|
| `source`  | Analyze source code (default)                           |
| `binary`  | Analyze a compiled binary (requires a pre-built binary) |
| `extract` | Extract information from binary for later analysis      |

#### Binary Mode

When using `mode: binary`, provide the path to a compiled binary instead of a package pattern:

```yaml
- uses: nicholas-fedor/govulncheck-action@v1
  with:
    mode: binary
    go-package: ./myapp
```

**Note:** The `-test` flag is not valid for binary mode and will be ignored if `mode: binary` is set.

#### Show Output

The `show` input enables additional output information:

| Value     | Description                                   |
|-----------|-----------------------------------------------|
| `traces`  | Show full call stack for each vulnerability   |
| `verbose` | Show progress messages and additional details |

```yaml
- uses: nicholas-fedor/govulncheck-action@v1
  with:
    show: traces
    output-format: text
```

**Note:** The `-show` flag is only applicable for text output format.

### Go Version Precedence

The precedence for specifying the Go version via the inputs `go-version-input`, `go-version-file`, and `check-latest` is inherited from [actions/setup-go](https://github.com/actions/setup-go).

### Output Formats

| Format    | Description                                                                             |
|-----------|-----------------------------------------------------------------------------------------|
| `text`    | Human-readable text output (default)                                                    |
| `json`    | JSON output with streaming support for large projects                                   |
| `sarif`   | [SARIF](https://sarifweb.azurewebsites.net/) format for integration with security tools |
| `openvex` | [OpenVEX](https://openvex.dev/) (Vulnerability EXchange) format                         |

## Example Workflows

### Basic

```yaml
name: Vulnerability Scanning
on: [push, pull_request]

jobs:
  govulncheck:
    runs-on: ubuntu-latest
    steps:
      - uses: nicholas-fedor/govulncheck-action@v1
```

### SARIF for Code Scanning

```yaml
name: Vulnerability Scanning
on: [push, pull_request]

permissions:
  contents: read
  actions: read
  pull-requests: read
  security-events: write

jobs:
  govulncheck:
    runs-on: ubuntu-latest
    steps:
      - uses: nicholas-fedor/govulncheck-action@v1
        with:
          output-format: sarif
          output-file: results.sarif

      - uses: github/codeql-action/upload-sarif@v4
        with:
          sarif_file: results.sarif
```

### JSON for Custom Processing

```yaml
name: Vulnerability Scanning
on: [push, pull_request]

jobs:
  govulncheck:
    runs-on: ubuntu-latest
    steps:
      - uses: nicholas-fedor/govulncheck-action@v1
        with:
          output-format: json
          output-file: results.json
```

### OpenVEX for Supply Chain Security

```yaml
name: Vulnerability Scanning
on: [push, pull_request]

jobs:
  govulncheck:
    runs-on: ubuntu-latest
    steps:
      - uses: nicholas-fedor/govulncheck-action@v1
        with:
          output-format: openvex
          output-file: results.vex
```

### Binary Analysis

```yaml
name: Binary Vulnerability Scanning
on: [push, pull_request]

jobs:
  govulncheck:
    runs-on: ubuntu-latest
    steps:
      - name: Build binary
        run: go build -o myapp ./cmd/myapp

      - uses: nicholas-fedor/govulncheck-action@v1
        with:
          mode: binary
          go-package: ./myapp
          output-format: sarif
          output-file: results.sarif

      - uses: github/codeql-action/upload-sarif@v4
        with:
          sarif_file: results.sarif
```

## Exit Codes

| Code | Description                                                            |
|------|------------------------------------------------------------------------|
| 0    | Success (no vulnerabilities found, or using json/sarif/openvex format) |
| 1    | Vulnerabilities found (text output only)                               |
| 2    | Error occurred                                                         |

**Note:** When using `json`, `sarif`, or `openvex` output formats, govulncheck always exits successfully (code 0) regardless of vulnerabilities found. This allows CI/CD pipelines to upload results to external services without failing the build.

Reference: <https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck#hdr-Exit_codes>

## License

See the [LICENSE](LICENSE) file.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).
