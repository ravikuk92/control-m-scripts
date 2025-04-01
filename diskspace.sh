#!/bin/bash

# Define CSV file containing server list
CSV_FILE="servers.csv"

# Define directory to check
DIR_TO_CHECK="/home/ctmag"

# Define the username
USER="ctmag"

# Define threshold percentage
THRESHOLD=90

# Check if the CSV file exists
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: CSV file '$CSV_FILE' not found!"
    exit 1
fi

echo "Server Name, Used Percentage, Threshold, Status"

# Read the server list and check disk usage
while IFS=, read -r SERVER || [[ -n "$SERVER" ]]; do
    if [[ -n "$SERVER" ]]; then
        # Fetch disk usage and extract the used percentage
        USAGE=$(ssh -o StrictHostKeyChecking=no "${USER}@${SERVER}" "df -h $DIR_TO_CHECK | awk 'NR==2 {print \$5}'" 2>/dev/null)

        if [[ $? -ne 0 || -z "$USAGE" ]]; then
            echo "$SERVER, ERROR, $THRESHOLD%, Unable to fetch"
        else
            # Remove the % symbol
            USAGE_VALUE=${USAGE%\%}

            # Check if the usage is above the threshold
            if (( USAGE_VALUE > THRESHOLD )); then
                STATUS="NOT OK"
            else
                STATUS="OK"
            fi

            # Print formatted output
            echo "$SERVER, $USAGE%, $THRESHOLD%, $STATUS"
        fi
    fi
done < <(cat "$CSV_FILE")