#!/bin/bash

# Define CSV file containing server list
CSV_FILE="servers.csv"

# Define directory to check
DIR_TO_CHECK="/home/ctmag"

# Define the username
USER="ctmag"

# Check if the CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file '$CSV_FILE' not found!"
    exit 1
fi

echo "Checking disk space for directory: $DIR_TO_CHECK on listed servers..."

# Read the server list and check disk usage
while IFS=, read -r SERVER; do
    if [[ -n "$SERVER" ]]; then
        echo "Checking disk space on $SERVER..."
        ssh -o StrictHostKeyChecking=no "${USER}@${SERVER}" "df -h $DIR_TO_CHECK" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            echo "Error: Unable to connect to ${USER}@${SERVER} or fetch disk usage!"
        fi
        echo "--------------------------------------"
    fi
done < "$CSV_FILE"