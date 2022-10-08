#!/bin/bash

set -e

if [ -z "$BSM_BRANCH" ]; then BSM_BRANCH="master"; fi

cd /opt/barry-service-manager
su barry -c "git fetch && git reset --hard origin/$BSM_BRANCH"
bundle install

# Rewrite the systemd unit (in case of new/modified environment)
cat >/etc/systemd/system/barry-service-manager.service <<-EOF
	[Unit]
	Description=Barry Service Manager
	After=network.target

	[Service]
	Type=simple
	WorkingDirectory=/opt/barry-service-manager
	User=barry
	ExecStart=bundle exec rackup -p 8100 -o 0.0.0.0
	Restart=on-failure
	SyslogIdentifier=barry-service-manager
	Environment=RACK_ENV=production
	Environment=MONGODB_CONN_TEMPLATE=${MONGODB_CONN_TEMPLATE}
	Environment=ADMIN_TOKEN=${ADMIN_TOKEN}

	[Install]
	WantedBy=multi-user.target
EOF

# Update script sudo permissions (in case of new/removed scripts)
{
  for script in /opt/barry-service-manager/scripts/*.sh; do
    echo "barry ALL= NOPASSWD:SETENV: $script"
  done
} >/etc/sudoers.d/barry-app-ctrl

systemctl daemon-reload
systemctl restart barry-service-manager.service
