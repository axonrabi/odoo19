#!/bin/bash
# LXD Odoo Deployment Script
# This script initializes an LXD container, sets up Odoo prerequisites, and provides basic commands.

COMMAND=$1
CONTAINER_NAME=${2:-odoo-local}

case "$COMMAND" in
  install)
    echo "Installing Odoo in LXD container: $CONTAINER_NAME..."
    # Launch a new Ubuntu container
    lxc launch ubuntu:22.04 $CONTAINER_NAME

    # Wait for the container to get an IP address
    sleep 5

    # Update package list and install dependencies
    lxc exec $CONTAINER_NAME -- apt-get update
    lxc exec $CONTAINER_NAME -- DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip postgresql git libpq-dev libldap2-dev libsasl2-dev libxslt1-dev libzip-dev zlib1g-dev python3-dev build-essential

    # Setup PostgreSQL user
    lxc exec $CONTAINER_NAME -- su - postgres -c "createuser -s odoo" || true

    # Clone Odoo (using 16.0 for example)
    lxc exec $CONTAINER_NAME -- git clone https://github.com/odoo/odoo.git --depth 1 --branch 16.0 /opt/odoo

    # Install Python requirements
    lxc exec $CONTAINER_NAME -- pip3 install -r /opt/odoo/requirements.txt

    # Create Odoo systemd service
    lxc exec $CONTAINER_NAME -- bash -c 'cat <<EOF > /etc/systemd/system/odoo.service
[Unit]
Description=Odoo
After=network.target postgresql.service

[Service]
Type=simple
User=odoo
Group=odoo
ExecStart=/opt/odoo/odoo-bin -d odoo
Restart=always

[Install]
WantedBy=multi-user.target
EOF'
    lxc exec $CONTAINER_NAME -- systemctl daemon-reload
    lxc exec $CONTAINER_NAME -- systemctl enable odoo

    # Add proxy device to map port 8069
    lxc config device add $CONTAINER_NAME odoo-port8069 proxy listen=tcp:0.0.0.0:8069 connect=tcp:127.0.0.1:8069

    echo "Odoo installation completed in $CONTAINER_NAME."
    ;;

  start)
    echo "Starting Odoo in container: $CONTAINER_NAME..."
    lxc exec $CONTAINER_NAME -- systemctl start odoo
    ;;

  snapshot)
    SNAPSHOT_NAME=${3:-"backup-$(date +%Y%m%d%H%M%S)"}
    echo "Taking snapshot of $CONTAINER_NAME as $SNAPSHOT_NAME..."
    lxc snapshot $CONTAINER_NAME $SNAPSHOT_NAME
    ;;

  export)
    EXPORT_PATH=${3:-"./${CONTAINER_NAME}_export.tar.gz"}
    echo "Exporting container $CONTAINER_NAME to $EXPORT_PATH..."
    lxc export $CONTAINER_NAME $EXPORT_PATH
    ;;

  *)
    echo "Usage: $0 {install|start|snapshot|export} [container_name] [snapshot_name/export_path]"
    exit 1
    ;;
esac
