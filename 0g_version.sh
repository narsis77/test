#!/bin/bash


echo -e "\033[31m;1m"Checking version of 0gchain..."\033[31m"
echo -e "\033[31m"Test"\033[0m"

cd $HOME/0gchaind
0gchaind version

echo "Checking version for storage node..."
cd $HOME/0g-storage-node
git log --decorate=short --oneline | grep "tag: v" | head -n 1
cd

echo "Checking version for storage client..."
cd $HOME/0g-storage-client
git log --decorate=short --oneline | grep "tag: v" | head -n 1
cd

echo "Checking version for da node..."
cd $HOME/0g-da-node
git log --decorate=short --oneline | grep "tag: v" | head -n 1
cd

echo "Checking version for da client..."
cd $HOME/0g-da-client
git log --decorate=short --oneline | grep "tag: v" | head -n 1
cd

echo "Checking version for storage kv..."
cd $HOME/0g-storage-kv
git log --decorate=short --oneline | grep "tag: v" | head -n 1
cd
