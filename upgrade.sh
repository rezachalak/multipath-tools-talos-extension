#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Error handling - reset colors on failure
trap 'echo -e "${RED}❌ Upgrade failed!${NC}"; exit 1' ERR
set -e

# Default values
ARCH=amd64
PROFILE=installer
TALOS_IMAGE=ghcr.io/siderolabs/imager
IMAGE_EXT="rezachalak/multipath-tools-talos:0.0.4"
DEST_DIR="_out"
TALOS_VERSION="v1.11.2"
TALOS_NODES=""

# Help function
show_help() {
    echo -e "${CYAN}Multipath-tools Talos Extension Build & Upgrade Script${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "    $0 [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "    -n, --nodes NODES           Comma-separated list of Talos node IPs"
    echo "                                Example: -n 10.21.7.2,10.21.7.3,10.21.7.4"
    echo ""
    echo "    -v, --talos-version VERSION Talos version to use"
    echo "                                Default: v1.11.2"
    echo "                                Example: -v v1.12.0"
    echo ""
    echo "    -d, --dest DIRECTORY        Destination directory for build artifacts"
    echo "                                Default: _out"
    echo "                                Example: -d /tmp/build"
    echo ""
    echo "    --ext-image IMAGE:TAG       Extension image name with tag"
    echo "                                Default: rezachalak/multipath-tools-talos:0.0.4"
    echo "                                Example: --ext-image myrepo/multipath:1.0.0"
    echo ""
    echo "    -h, --help                  Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "    # Build and upgrade with default settings"
    echo "    $0"
    echo ""
    echo "    # Build and upgrade to specific nodes"
    echo "    $0 -n 10.21.7.2,10.21.7.3"
    echo ""
    echo "    # Build with custom image tag and Talos version"
    echo "    $0 --ext-image rezachalak/multipath-tools-talos:0.1.0 -v v1.12.0"
    echo ""
    echo "    # Full example with all options"
    echo "    $0 -n 10.21.7.2,10.21.7.3,10.21.7.4 \\"
    echo "       -v v1.12.0 \\"
    echo "       -d /tmp/multipath-build \\"
    echo "       --ext-image myrepo/multipath-tools:1.0.0"
    echo ""
    echo -e "${YELLOW}Notes:${NC}"
    echo "    - The script will build the Docker image and push it to the registry"
    echo "    - If nodes are specified, it will upgrade those nodes with the new extension"
    echo "    - Make sure you have Docker buildx configured and are logged into your registry"
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--nodes)
            TALOS_NODES="$2"
            shift 2
            ;;
        -v|--talos-version)
            TALOS_VERSION="$2"
            shift 2
            ;;
        -d|--dest|--DEST)
            DEST_DIR="$2"
            shift 2
            ;;
        --ext-image)
            IMAGE_EXT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Extract image name and tag from IMAGE_EXT
if [[ "$IMAGE_EXT" =~ ^(.+):(.+)$ ]]; then
    IMAGE_NAME="${BASH_REMATCH[1]}"
    IMAGE_TAG="${BASH_REMATCH[2]}"
else
    echo -e "${RED}Error: --ext-image must be in format 'image:tag'${NC}"
    echo "Example: --ext-image rezachalak/multipath-tools-talos:0.0.4"
    exit 1
fi

# Validate required parameters
if [[ -z "$TALOS_NODES" ]]; then
    echo -e "${YELLOW}⚠️  No nodes specified. Image will be built and pushed, but not deployed.${NC}"
    echo -e "${YELLOW}   Use -n or --nodes to specify target nodes for deployment.${NC}"
fi

echo -e "${CYAN}🚀 Building and upgrading multipath-tools extension${NC}"
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Image:         ${YELLOW}${IMAGE_EXT}${NC}"
echo -e "  Talos Version: ${YELLOW}${TALOS_VERSION}${NC}"
echo -e "  Dest Dir:      ${YELLOW}${DEST_DIR}${NC}"
if [[ -n "$TALOS_NODES" ]]; then
    echo -e "  Target Nodes:  ${YELLOW}${TALOS_NODES}${NC}"
fi
echo ""

# Create buildx builder
docker buildx create --name local --use || true

# Build Docker image
echo -e "${BLUE}📦 Building Docker image...${NC}"
for i in {1..2}; do
    if make docker-multipath-tools PLATFORM=linux/amd64 TARGET_ARGS="--tag=${IMAGE_EXT} --load"; then
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}Failed to build image after 10 attempts${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Build attempt $i failed, retrying...${NC}"
    sleep 2
done

echo -e "${PURPLE}🔧 Building Talos installer...${NC}"
docker run --rm -t -v /dev:/dev --privileged \
    -v "$PWD/${DEST_DIR}:/out" "${TALOS_IMAGE}:${TALOS_VERSION}" \
    --arch "${ARCH}" --system-extension-image ${IMAGE_EXT} "${PROFILE}"
echo -e "${GREEN}✅ Installer built successfully!${NC}"

crane push ${DEST_DIR}/installer-amd64.tar ${IMAGE_EXT}-installer
echo -e "${GREEN}✅ Installer pushed successfully!${NC}"

echo -e "${YELLOW}📋 Extensions before upgrade:${NC}"
talosctl get extensions -n ${TALOS_NODES}

echo -e "${CYAN}⬆️ Starting upgrade...${NC}"
talosctl upgrade --nodes ${TALOS_NODES} --image ${IMAGE_EXT}-installer

echo -e "${YELLOW}📋 Extensions after upgrade:${NC}"
talosctl get extensions -n ${TALOS_NODES}

echo -e "${GREEN}🎉 Upgrade completed successfully!${NC}"
