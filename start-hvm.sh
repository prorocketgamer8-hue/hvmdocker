#!/bin/bash
set -e

echo "================================="
echo " HVM 5.1"
echo " Starting..."
echo "================================="

cd /root/hvm

# Start HVM
if [ -f hvm-5.1.py ]; then
    exec python3 hvm-5.1.py
elif [ -f hvm.py ]; then
    exec python3 hvm.py
else
    echo "ERROR: HVM startup file not found."
    ls -la
    exit 1
fi
