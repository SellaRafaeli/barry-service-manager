#!/bin/bash

source "$(dirname "$0")/setenv.sh"

systemctl stop $SERVICE_NAME
