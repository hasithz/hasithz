#!/bin/bash

if [ ! -d ".git" ]; then
    echo "Not a git repository"
    exit 1
fi

# Ensure figlet is installed
if ! command -v figlet &> /dev/null; then
    echo "Installing figlet..."
    sudo apt-get install -y figlet
fi

# Get rotating message
mapfile -t messages < messages.txt
day_of_year=$(date +%j)
msg_index=$((day_of_year % ${#messages[@]}))
message=${messages[$msg_index]}

# Create ASCII banner (52-width, 7-height)
figlet -w 52 -f banner "$message" > pic.txt
mapfile -t lines < pic.txt

# Calculate today's position
col=$(date +%U)  # week number
row_offset=$(date +%w)  # 0 = Sunday

# Starting Sunday 51 weeks ago
start_date=$(date -d "last sunday -51 weeks" +%Y-%m-%d)
today_date=$(date -d "$start_date +$col weeks +$row_offset days" +%Y-%m-%d)

echo "🖼️ Rendering '$message' at week $col (today = $today_date)"

char="${lines[$row_offset]:$col:1}"
if [ "$char" != " " ]; then
    for i in $(seq 1 6); do
        echo "$today_date - Commit for $message - $i" > fake.txt
        git add fake.txt
        GIT_AUTHOR_DATE="$today_date 12:00:00" \
        GIT_COMMITTER_DATE="$today_date 12:00:00" \
        git commit -m "[$message] daily contribution commit"
    done
else
    echo "No block to commit for today in pattern."
fi

rm -f fake.txt
