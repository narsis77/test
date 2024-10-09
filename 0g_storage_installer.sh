#!/bin/bash

echo "Updating package lists..."
sudo apt-get update

echo "Installing necessary packages..."
sudo apt-get install clang cmake build-essential -y

echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo "Removing existing 0g-storage-node directory..."
sudo systemctel stop zgs && rm -r $HOME/0g-storage-node

echo "Cloning the repository..."
git clone -b v0.5.0 https://github.com/0glabs/0g-storage-node.git
cd $HOME/0g-storage-node

echo "Stashing any local changes..."
git stash

echo "Fetching all tags..."
git fetch --all --tags

echo "Checking out specific commit..."
git checkout 20266e0

echo "Updating submodules..."
git submodule update --init

echo "Building the project..."
cargo build --release

echo "Removing old config file..."
rm -rf $HOME/0g-storage-node/run/config.toml

echo "Downloading new config file..."
curl -o $HOME/0g-storage-node/run/config.toml https://raw.githubusercontent.com/zstake-xyz/test/refs/heads/main/0g_storage_config.toml

echo "Enter your miner key:"
read MINER_KEY

echo "Updating miner_key in config.toml..."
sed -i "s/miner_key = \"\"/miner_key = \"$MINER_KEY\"/" $HOME/0g-storage-node/run/config.toml

echo "Creating systemd service file..."
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

echo "Installing additional packages..."
sudo apt-get install wget lz4 aria2 pv -y

echo "Downloading snapshot..."
aria2c -x 16 -s 16 https://snapshot.zstake.xyz/downloads/storage_0gchain_snapshot.lz4

echo "Removing old database, log, and network directories..."
rm -r $HOME/0g-storage-node/run/db && rm -r $HOME/0g-storage-node/run/log && rm -r $HOME/0g-storage-node/run/network

echo "Extracting snapshot..."
lz4 -c -d storage_0gchain_snapshot.lz4 | pv | tar -x -C $HOME/0g-storage-node/run

echo "Reloading systemd daemon, enabling and starting the service..."
sudo systemctl daemon-reload && sudo systemctl enable zgs && sudo systemctl start zgs

echo "Starting monitoring loop..."
while true; do 
    response=$(curl -s -X POST http://localhost:5678 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')
    logSyncHeight=$(echo $response | jq '.result.logSyncHeight')
    connectedPeers=$(echo $response | jq '.result.connectedPeers')
    echo -e "logSyncHeight: \033[32m$logSyncHeight\033[0m, connectedPeers: \033[34m$connectedPeers\033[0m"
    sleep 5; 
done