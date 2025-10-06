#!/bin/bash
TALOS_VERSION=v1.11.2
ARCH=amd64
IMAGE_EXT=rezachalak/multipath-tools-talos
PROFILE=installer
IMAGE_TAG=${1:-0.0.4}

TALOS_VERSION=v1.11.2
TALOS_IMAGE=ghcr.io/siderolabs/imager

TALOS_NODE=10.21.7.2

echo "Building and upgrading to ${IMAGE_EXT}:${IMAGE_TAG}"
echo "Building image"
make docker-multipath-tools PLATFORM=linux/amd64 TARGET_ARGS="--tag=${IMAGE_EXT}:${IMAGE_TAG} --load"
docker push ${IMAGE_EXT}:${IMAGE_TAG}
echo "Image built and pushed"

echo "Building installer"
docker run --rm -t -v /dev:/dev --privileged \
    -v "$PWD/_out:/out" "${TALOS_IMAGE}:${TALOS_VERSION}" \
    --arch "${ARCH}" --system-extension-image ${IMAGE_EXT}:${IMAGE_TAG} "${PROFILE}"
echo "Installer built"
crane push _out/installer-amd64.tar ${IMAGE_EXT}:${IMAGE_TAG}-installer
echo "Installer pushed"

echo "extensions before upgrade"
talosctl get extensions -n ${TALOS_NODE}
echo "upgrade..."
talosctl upgrade --nodes ${TALOS_NODE} --image ${IMAGE_EXT}:${IMAGE_TAG}-installer
echo "extensions after upgrade"
talosctl get extensions -n ${TALOS_NODE}
echo "Upgrade done"
