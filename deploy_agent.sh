#!/bin/bash

cd "$(dirname "$0")" || exit 1

project=""

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

create_folders() {
    read -p "Enter a project name: " name || exit 1
    if [[ ! $name =~ ^[A-Za-z0-9_-]+$ ]]; then
        echo "Error: use only letters, numbers, - or _."
        exit 1
    fi

    if [ -d "attendance_tracker_$name" ]; then
        read -p "attendance_tracker_$name already exists. Overwrite? (y/n): " answer
        if [ "$answer" != "y" ]; then
            echo "Error: project already exists. Aborting."
            exit 1
        fi
        rm -rf "attendance_tracker_$name"
    fi

    project="attendance_tracker_$name"
    mkdir -p "$project/Helpers" "$project/reports" || exit 1
    cp templates/attendance_checker.py "$project/"
    cp templates/config.json "$project/Helpers/"
    echo "Created $project"
}

deploy() {
    check_tools
    create_folders
    echo "Deployment complete."
}

echo "1) Deploy"
read -p "Choose an option: " option

case $option in
    1) deploy ;;
    *) echo "Invalid option." ;;
esac
