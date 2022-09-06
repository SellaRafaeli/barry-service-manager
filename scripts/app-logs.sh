#!/bin/bash

source "$(dirname "$0")/setenv.sh"

journalctl -t $SERVICE_NAME
