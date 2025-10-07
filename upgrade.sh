#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Error handling - reset colors on failure
trap 'echo -e "${RED}❌ Upgrade failed!${NC}"; exit 1' ERR
set -e

TALOS_VERSION=v1.11.2
ARCH=amd64
IMAGE_EXT=rezachalak/multipath-tools-talos
PROFILE=installer
IMAGE_TAG=${1:-0.0.4}
DEST_DIR=${2:-_out}

TALOS_VERSION=v1.11.2
TALOS_IMAGE=ghcr.io/siderolabs/imager

TALOS_NODE=10.21.7.2

echo -e "${CYAN}🚀 Building and upgrading to ${YELLOW}${IMAGE_EXT}:${IMAGE_TAG}${NC}"

echo -e "${BLUE}📦 Building Docker image...${NC}"
make docker-multipath-tools PLATFORM=linux/amd64 TARGET_ARGS="--tag=${IMAGE_EXT}:${IMAGE_TAG} --load"
docker push ${IMAGE_EXT}:${IMAGE_TAG}
echo -e "${GREEN}✅ Image built and pushed successfully!${NC}"

echo -e "${PURPLE}🔧 Building Talos installer...${NC}"
docker run --rm -t -v /dev:/dev --privileged \
    -v "$PWD/${DEST_DIR}:/out" "${TALOS_IMAGE}:${TALOS_VERSION}" \
    --arch "${ARCH}" --system-extension-image ${IMAGE_EXT}:${IMAGE_TAG} "${PROFILE}"
echo -e "${GREEN}✅ Installer built successfully!${NC}"

crane push ${DEST_DIR}/installer-amd64.tar ${IMAGE_EXT}:${IMAGE_TAG}-installer
echo -e "${GREEN}✅ Installer pushed successfully!${NC}"

echo -e "${YELLOW}📋 Extensions before upgrade:${NC}"
talosctl get extensions -n ${TALOS_NODE}

echo -e "${CYAN}⬆️ Starting upgrade...${NC}"
talosctl upgrade --nodes ${TALOS_NODE} --image ${IMAGE_EXT}:${IMAGE_TAG}-installer

echo -e "${YELLOW}📋 Extensions after upgrade:${NC}"
talosctl get extensions -n ${TALOS_NODE}

echo -e "${GREEN}🎉 Upgrade completed successfully!${NC}"
