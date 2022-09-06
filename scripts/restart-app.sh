#!/bin/bash

source "$(dirname "$0")/setenv.sh"

sudo systemctl restart $SERVICE_NAME
