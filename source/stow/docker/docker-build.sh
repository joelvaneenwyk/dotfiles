#!/usr/bin/env bash

set -eu

STOW_ROOT="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && cd ../ && pwd -P)"
STOW_VERSION=$(perl "$STOW_ROOT/tools/get-version")
DOCKER_BASE_IMAGE="stowtest"
DOCKER_IMAGE="$DOCKER_BASE_IMAGE:$STOW_VERSION"

echo "Building Docker DOCKER_IMAGE $DOCKER_IMAGE ..."
docker build \
    --progress plain \
    -t "$DOCKER_BASE_IMAGE:latest" \
    -t "$DOCKER_IMAGE" \
    -f "$STOW_ROOT/docker/Dockerfile" \
    "$STOW_ROOT"
