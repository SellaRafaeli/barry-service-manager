#!/bin/bash

source "$(dirname "$0")/setenv.sh"

GITHUB_URL="$1"
APP_NAME="$2"
APP_TYPE="$3"

usage() {
    echo "Usage: $0 <github-url> <app_name> [type]" >&2
    echo >&2
    echo "Where 'type' is one of [ruby, node], defaulting to [ruby]" >&2
    exit 1
}

if [ -z "$GITHUB_URL" ] || [ -z "$APP_NAME" ]; then usage; fi
if [ -z "$APP_TYPE" ]; then APP_TYPE="ruby"; fi
if [[ "$APP_TYPE" != @(ruby|node) ]]; then usage; fi

$BASE_DIR/app-status.sh && {
    echo "Existing application is already running, stopping..."
    $BASE_DIR/stop-app.sh
}

TARGET="$WORKSPACE_DIR/$APP_NAME"
echo "--- Cloning $GITHUB_URL to $TARGET ---"
rm -rf "$TARGET"
mkdir -p "$TARGET"
git clone --single-branch "$GITHUB_URL" "$TARGET"

DETERMINED_TYPE="unknown"
if [ -f "$TARGET/package.json" ]; then
	DETERMINED_TYPE="node"
elif [ -f "$TARGET/Gemfile" ]; then
	DETERMINED_TYPE="ruby"
fi

if [ "$APP_TYPE" != "$DETERMINED_TYPE" ]; then
	echo "FATAL: Specified application type ($APP_TYPE) does not match determined type ($DETERMINED_TYPE)!" >&2
	exit 2
fi

echo "--- Configuring $APP_TYPE application $APP_NAME ---"
case "$APP_TYPE" in
    'ruby')
        cat >"$TARGET/.env" <<-EOF
            MONGODB_URI=${MONGODB_CONN_TEMPLATE//BARRY_APP_NAME/${APP_NAME}}
            RACK_ENV=production
        EOF
        ;;
    'node')
        cat >"$TARGET/.env" <<-EOF
            MONGODB_URI=${MONGODB_CONN_TEMPLATE//BARRY_APP_NAME/${APP_NAME}}
        EOF
        ;;
esac

echo "--- Installing dependencies ---"
chown -R barry:barry "$WORKSPACE_DIR"
case "$APP_TYPE" in
    'ruby')
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

        # Fix up bundler directory permissions
        chown -R barry:barry "/home/barry/.bundle"
        su -l barry -c "cd $TARGET && bundle config set path 'vendor/bundle' && bundle install"
        ;;

    'node')
        su -l barry -c "cd $TARGET && npm install"
        ;;
esac

echo "--- Creating systemd unit ---"
case "$APP_TYPE" in
    'ruby')
        STARTUP_COMMAND="bundle exec rackup -p 80 -o 0.0.0.0"
        EXTRA_ENV="RACK_ENV=production"
        ;;
    'node')
        STARTUP_COMMAND="node index.js"
        EXTRA_ENV="\"MONGODB_URI=$MONGODB_URI\" PORT=80"
        ;;
esac

cat >"/etc/systemd/system/${SERVICE_NAME}.service" <<-EOF
	[Unit]
	Description=[Barry App] $APP_NAME
	After=network.target

	[Service]
	Type=simple
	WorkingDirectory=$TARGET
	User=barry
	ExecStart=$STARTUP_COMMAND
	Restart=on-failure
	AmbientCapabilities=CAP_NET_BIND_SERVICE
	SyslogIdentifier=barry-app
	Environment=$EXTRA_ENV

	[Install]
	WantedBy=multi-user.target
EOF

sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME
