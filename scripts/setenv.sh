#!/bin/bash

set -e

if [[ $(id -u) -ne 0 ]]; then
    echo "Must run as root"
    exit 1
fi

BASE_DIR="$(dirname "$0")"
SERVICE_NAME='barry-app'
WORKSPACE_DIR="/home/barry/workspaces"
