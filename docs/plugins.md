# Environment Plugins

> Extracted from [ADR-001](adr/ADR-001-cal-isolation.md) for quick reference.

## Available Environments

| Category | Environments |
|----------|--------------|
| Apple | `ios` (Xcode, Swift, simulators) ~30GB |
| Android | `android` (SDK, Gradle, Kotlin) ~12GB, requires `java` |
| Cross-platform | `flutter` ~2GB, `react-native` ~500MB |
| Backend | `node` ~200MB, `python` ~500MB, `go` ~500MB, `rust` ~1GB |
| Other | `java` ~500MB, `dotnet` ~3GB, `python-ml` ~8GB, `cpp` ~2GB |

## Commands

```bash
cal isolation env list <workspace>
cal isolation env install <workspace> <env> [--variant <v>]
cal isolation env remove <workspace> <env>
cal isolation env verify <workspace>
```

## Templates

| Template | Environments | Size |
|----------|--------------|------|
| `minimal` | (none) | ~25GB |
| `ios` | ios | ~55GB |
| `android` | java, android | ~38GB |
| `mobile` | ios, java, android | ~67GB |
| `backend` | node, python, go, rust | ~28GB |

```bash
cal isolation init my-app --template mobile
```

## Plugin Manifest

`~/.cal/environments/plugins/{name}/manifest.yaml`:

```yaml
name: android
display_name: "Android Development"
requires: [java]
provides: [android-sdk, gradle, kotlin, adb]
size_estimate: "12GB"

install:
  env:
    ANDROID_HOME: "$HOME/Library/Android/sdk"
    PATH: "$ANDROID_HOME/platform-tools:$PATH"
  brew: [kotlin]
  cask: [android-commandlinetools]
  post_install:
    - yes | sdkmanager --licenses || true
    - sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"

verify:
  - command: "adb --version"
    expect_contains: "Android Debug Bridge"

artifacts:
  patterns: ["*.apk", "*.aab", "build/outputs/**"]
  exclude: ["build/intermediates/**"]

uninstall:
  - rm -rf ~/Library/Android
```

## Template Definition

`~/.cal/isolation/templates/{name}.yaml`:

```yaml
name: mobile
description: "iOS + Android development"
base_image: "ghcr.io/cirruslabs/macos-sequoia-base:latest"
environments: [ios, java, android]
resources:
  cpu: 6
  memory: 12288
  disk_size: 100
```

## Custom Plugins

1. Create `~/.cal/environments/plugins/community/<name>/manifest.yaml`
2. Define install/verify/artifacts sections
3. Test: `cal isolation env install <workspace> <name>`
