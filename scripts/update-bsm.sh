#!/bin/bash

set -e

cd /opt/barry-service-manager
su barry -c 'git fetch && git reset --hard origin/master'
systemctl restart barry-service-manager.service
