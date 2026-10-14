#!/bin/bash

cd "$(dirname "$0")" || exit 1

project=""

read_number() {
    while true; do
        read -p "$1" number || exit 1
        number=${number:-$4}
        if [[ $number =~ ^[0-9]+$ ]] && [ "$number" -ge "$2" ] && [ "$number" -le "$3" ]; then
            return
        fi
        echo "Please enter a number between $2 and $3."
    done
}

cleanup() {
    echo
    echo "Deployment interrupted!"
    if [ -n "$project" ] && [ -d "$project" ]; then
        rm -f "${project}_archive.zip"
        zip -rq "${project}_archive.zip" "$project"
        rm -rf "$project"
        echo "Incomplete project saved to ${project}_archive.zip and removed."
    fi
    exit 1
}

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

create_roster() {
    file="$project/Helpers/assets.csv"
    names=("Amara Uwase" "Brian Mugisha" "Chloe Keza" "David Habimana" "Esther Ishimwe"
           "Felix Gasana" "Grace Mutesi" "Henry Kamanzi" "Ines Ineza" "Joel Nkurunziza")

    while true; do
        read -p "Roster: (A) copy from template or (B) generate new? " choice || exit 1
        case $choice in
            A|a)
                read_number "How many students to copy (1-10)? " 1 10
                head -n $((number + 1)) templates/assets.csv > "$file"
                break ;;
            B|b)
                read_number "How many students to generate (1-10)? " 1 10
                echo "Email,Names,Attendance Count,Absence Count" > "$file"
                for ((i = 0; i < number; i++)); do
                    email=$(echo "${names[$i]}" | tr 'A-Z ' 'a-z.')@example.com
                    echo "$email,${names[$i]},0,0" >> "$file"
                done
                sed -i 's/"total_sessions": [0-9]*/"total_sessions": 1/' "$project/Helpers/config.json"
                break ;;
            *)
                echo "Please choose A or B." ;;
        esac
    done
    echo "Created roster with $number students."
}

set_permissions() {
    chmod +x "$project/attendance_checker.py"
    chmod 600 "$project/Helpers/config.json"
    echo "Permissions set:"
    ls -l "$project/attendance_checker.py" "$project/Helpers/config.json"
}

update_thresholds() {
    read -p "Update attendance thresholds? (y/n): " answer
    if [ "$answer" != "y" ]; then
        return
    fi

    while true; do
        read_number "Warning threshold (default 75): " 0 100 75
        warning=$number
        read_number "Failure threshold (default 50): " 0 100 50
        failure=$number
        if [ "$failure" -lt "$warning" ]; then
            break
        fi
        echo "Failure threshold must be lower than warning threshold."
    done

    config="$project/Helpers/config.json"
    sed -i "s/\"warning\": [0-9]*/\"warning\": $warning/" "$config"
    sed -i "s/\"failure\": [0-9]*/\"failure\": $failure/" "$config"
    echo "Thresholds updated: warning=$warning, failure=$failure"
}

deploy() {
    trap cleanup INT TSTP
    check_tools
    create_folders
    create_roster
    set_permissions
    update_thresholds
    trap - INT TSTP
    echo "Deployment complete."
}

echo "1) Deploy"
read -p "Choose an option: " option

case $option in
    1) deploy ;;
    *) echo "Invalid option." ;;
esac
