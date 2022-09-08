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

echo "--- Configuring application $APP_NAME ---"
cat >"$TARGET/.env" <<-EOF
	MONGODB_URI=${MONGODB_CONN_TEMPLATE//BARRY_APP_NAME/${APP_NAME}}
	RACK_ENV=production
EOF

echo "--- Installing dependencies ---"
# Some common dependencies like Nokogiri require more RAM to install than the server has,
# so we temporarily enable swap
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
function deallocate_swap {
  swapoff /swapfile
  rm /swapfile
}
trap deallocate_swap EXIT
bundle install
chown -R barry:barry "$TARGET"
chmod a+r "$TARGET"
su barry -c 'bundle install'

echo "--- Creating systemd unit ---"
cat >"/etc/systemd/system/${SERVICE_NAME}.service" <<-EOF
	[Unit]
	Description=[Barry App] $APP_NAME
	After=network.target

	[Service]
	Type=simple
	WorkingDirectory=$TARGET
	User=barry
	ExecStart=bundle exec rackup -p 80 -o 0.0.0.0
	Restart=on-failure
	AmbientCapabilities=CAP_NET_BIND_SERVICE
	SyslogIdentifier=barry-app
	Environment=RACK_ENV=production

	[Install]
	WantedBy=multi-user.target
EOF

sudo systemctl enable $SERVICE_NAME
