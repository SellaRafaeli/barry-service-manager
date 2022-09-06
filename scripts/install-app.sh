#!/bin/bash

source "$(dirname "$0")/setenv.sh"

GITHUB_URL="$1"
APP_NAME="$2"
if [ -z "$GITHUB_URL" ] || [ -z "$APP_NAME" ]; then
  echo "Usage: $0 <github-url> <app_name>" >&2
  exit 1
fi

$BASE_DIR/app-status.sh && {
  echo "Existing application is already running, stopping..."
  $BASE_DIR/stop-app.sh
}

TARGET="$WORKSPACE_DIR/$APP_NAME"
echo "--- Cloning $GITHUB_URL to $TARGET ---"
rm -rf "$TARGET"
mkdir -p "$TARGET"
cd "$TARGET"
git clone --single-branch "$GITHUB_URL" "$TARGET"

echo "--- Installing dependencies ---"
bundle install
chown -R barry:barry "$TARGET"
chmod a+r "$TARGET"

echo "--- Creating systemd unit ---"
cat >"/etc/systemd/system/${SERVICE_NAME}.service" <<-EOF
	[Unit]
	Description=[Barry App] $APP_NAME
	After=network.target

	[Service]
	Type=simple
	WorkingDirectory=$TARGET
	User=barry
	ExecStart=bundle exec rackup -p 80
	Restart=on-failure
	AmbientCapabilities=CAP_NET_BIND_SERVICE
	SyslogIdentifier=barry-app

	[Install]
	WantedBy=multi-user.target
EOF

sudo systemctl enable $SERVICE_NAME
