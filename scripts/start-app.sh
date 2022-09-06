#!/bin/bash

source "$(dirname "$0")/setenv.sh"

systemctl start $SERVICE_NAME
