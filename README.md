# Talos Extension Playground

⚠️ **Work in Progress** - This is a learning and experimentation environment for Talos extensions.

## Overview

This repository is a **playground for developing and testing Talos Linux extensions**. It provides a complete workflow for building, testing, and deploying custom extensions to your Talos cluster.

### Example Extension: multipath-tools

The repository includes a not ful functional `multipath-tools` extension as a reference implementation. This extension provides multipath storage device management functionality and has been tested with remote multipath targets, with `multipath` commands executed in the mount namespace of the `ext-multipathd` Talos extension service.

## Purpose

This project is designed to help you:
- **Learn** how to create custom Talos extensions from scratch
- **Rapidly iterate** and test extension configurations
- **Understand** the complete extension build and deployment workflow
- **Experiment** with different extension architectures and configurations
- **Use as a template** for your own custom extensions

## Project Structure

```
talos-extension-playground/
├── multipath-tools/          # Example extension
│   ├── pkg.yaml             # Extension build configuration
│   ├── vars.yaml            # Version and checksum variables
│   ├── multipathd.yaml      # Extension service configuration
│   ├── patches/             # Source code patches
│   └── README.md            # This file
├── upgrade.sh               # Build and deployment script
└── Makefile                 # Build automation
```

## Quick Start

Use the provided `upgrade.sh` script to build and deploy the extension to your cluster:

```bash
# Build and push the extension (no deployment)
./upgrade.sh

# Build and deploy to specific nodes
./upgrade.sh -n 10.21.7.2,10.21.7.3

# Custom image and version
./upgrade.sh --ext-image myrepo/multipath-tools:0.1.0 -v v1.12.0

# See all options
./upgrade.sh -h
```

## ⚠️ Important Warnings

### Extension Replacement
**This script will replace ALL existing extensions on your cluster.** When you upgrade a Talos node with a custom installer image containing this extension, any other extensions previously installed will be removed. This is because the script creates a new installer image with only the multipath-tools extension.

If you need to preserve other extensions:
1. Modify the script to include all required extensions in the installer image
2. Or use Talos machine config to specify multiple extensions

### Production Use
This is a **development/testing project**. Before using in production:
- Thoroughly test in a non-production environment
- Review and understand all configuration files
- Ensure your storage infrastructure supports multipath
- Have a rollback plan ready

## Project Status

- ✅ Extension builds successfully
- ✅ Rapid upgrade workflow implemented
- 🚧 Runtime testing in progress
- 🚧 Configuration optimization ongoing
- ❌ Automated tests not yet implemented

## Creating Your Own Extension

To create a new extension based on this template:

1. **Copy the example structure**:
   ```bash
   cp -r multipath-tools/ my-extension/
   ```

2. **Update the configuration files**:
   - `pkg.yaml`: Define your build steps, dependencies, and installation
   - `vars.yaml`: Set version numbers and checksums
   - `*-service.yaml`: Configure your extension's runtime service

3. **Modify the Makefile**:
   - Add a new target for your extension
   - Update the `TARGET_ARGS` to use your image name

4. **Test and iterate**:
   ```bash
   ./upgrade.sh --ext-image myrepo/my-extension:0.1.0 -n <test-node>
   ```

## Key Files Explained

### `pkg.yaml`
Defines how your extension is built:
- **variant**: Base image type (`scratch`, `alpine`, etc.)
- **dependencies**: Required system packages and libraries
- **steps**: Build, install, and test phases
- **finalize**: What gets included in the final extension

### `vars.yaml`
Contains version-specific variables:
- Software version to build
- SHA256/SHA512 checksums for source verification
- Extension version tag

### Service Configuration (`*.yaml`)
Defines the runtime behavior:
- Container security settings
- Entrypoint and arguments
- Environment variables
- Mount points and dependencies

## TODO

- [ ] Add automated tests to verify multipath-tools functionality
- [ ] Create troubleshooting guide
- [ ] Add more example extensions (e.g., monitoring agents, storage drivers)
- [ ] Create a template generator script

## Contributing

This is a learning project. Feel free to:
- Experiment and break things
- Share your custom extensions
- Improve the documentation
- Report issues and suggest improvements

**Remember**: This is a playground - mistakes are learning opportunities! 🚀y