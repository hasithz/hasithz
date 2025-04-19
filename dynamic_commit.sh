#!/bin/bash

# Exit immediately if any command fails
set -e

if [ ! -d ".git" ]; then
    echo "❌ Not a Git repository. Run this in a git-initialized folder."
    exit 1
fi

# Ensure figlet is installed
if ! command -v figlet &> /dev/null; then
    echo "🛠 Installing figlet..."
    sudo apt-get update && sudo apt-get install -y figlet
fi

# Check if messages.txt exists
if [ ! -f messages.txt ]; then
    echo "❌ 'messages.txt' not found. Please create one with a list of words (one per line)."
    exit 1
fi

# Load rotating message
mapfile -t messages < messages.txt
msg_count=${#messages[@]}
if [ "$msg_count" -eq 0 ]; then
    echo "❌ 'messages.txt' is empty."
    exit 1
fi

day_of_year=$(date +%j)
msg_index=$((day_of_year % msg_count))
message=${messages[$msg_index]}

# Generate ASCII art (52 columns wide)
figlet -w 52 -f banner "$message" > pic.txt
mapfile -t lines < pic.txt

# Calculate position in contribution graph
col=$(date +%U)  # current week number
row_count=7      # GitHub graph has 7 rows (Sun–Sat)
start_date=$(date -d "last sunday -51 weeks" +%Y-%m-%d)

echo "📅 Today: $(date)"
echo "🖼️ Rendering message: '$message' at week $col"

# Loop through 7 rows for this week and commit if pixel is present
commit_made=false
for row in $(seq 0 $((row_count - 1))); do
    char="${lines[$row]:$col:1}"
    if [ "$char" != " " ] && [ -n "$char" ]; then
        commit_date=$(date -d "$start_date +$col weeks +$row days" +%Y-%m-%d)
        for i in $(seq 1 6); do
            echo "$commit_date - Commit $i for $message" > fake.txt
            git add fake.txt
            GIT_AUTHOR_DATE="$commit_date 12:00:00" \
            GIT_COMMITTER_DATE="$commit_date 12:00:00" \
            git commit -m "[$message] Pixel commit at ($col,$row)"
        done
        commit_made=true
    fi
done

rm -f fake.txt

if $commit_made; then
    echo "✅ Commits added for '$message' at week $col."
else
    echo "⚠️ No visible characters in today's column. Nothing committed."
fi
