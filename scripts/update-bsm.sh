#!/bin/bash

set -e

cd /opt/barry-service-manager
su barry -c 'git fetch && git reset --hard origin/master'
bundle install
systemctl restart barry-service-manager.service

# Update script sudo permissions (in case of new/removed scripts)
{
  for script in /opt/barry-service-manager/scripts/*.sh; do
    echo "barry ALL= NOPASSWD: $script"
  done
} >/etc/sudoers.d/barry-app-ctrl
