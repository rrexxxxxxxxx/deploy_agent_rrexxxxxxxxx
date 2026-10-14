#!/bin/bash

cd "$(dirname "$0")" || exit 1

check_tools() {
    for tool in python3 zip; do
        if ! command -v "$tool" > /dev/null; then
            echo "Error: $tool is not installed."
            exit 1
        fi
    done
    echo "Found $(python3 --version) and zip."

    if [ ! -d templates ]; then
        echo "Error: templates folder not found."
        exit 1
    fi
}

deploy() {
    check_tools
    echo "Deployment complete."
}

echo "1) Deploy"
read -p "Choose an option: " option

case $option in
    1) deploy ;;
    *) echo "Invalid option." ;;
esac
