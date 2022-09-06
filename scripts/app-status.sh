#!/bin/bash

source "$(dirname "$0")/setenv.sh"

systemctl is-active --quiet "${SERVICE_NAME}.service"
