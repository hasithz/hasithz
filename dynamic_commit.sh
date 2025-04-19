#!/bin/bash

# Exit immediately on error
set -e

# 🔐 Check for git repository
if [ ! -d ".git" ]; then
    echo "❌ Not a Git repository. Run this script in a git-initialized folder."
    exit 1
fi

# 🧰 Install figlet if not installed
if ! command -v figlet &> /dev/null; then
    echo "🛠 Installing figlet..."
    sudo apt-get update && sudo apt-get install -y figlet
fi

# 📄 Check for messages.txt
if [ ! -f messages.txt ]; then
    echo "❌ 'messages.txt' not found. Please create one with words like:"
    echo -e "HASITH\nHELLO\n❤️\nBUILD\nENJOY" > messages.txt
    echo "✅ Example messages.txt created."
fi

# 🔁 Load message of the day
mapfile -t messages < messages.txt
msg_count=${#messages[@]}
if [ "$msg_count" -eq 0 ]; then
    echo "❌ 'messages.txt' is empty."
    exit 1
fi

day_of_year=$(date +%j)
msg_index=$((day_of_year % msg_count))
message=${messages[$msg_index]}

# 🎨 Create ASCII art
figlet -w 52 -f banner "$message" > pic.txt
mapfile -t lines < pic.txt

# 🔍 Preview ASCII in terminal
echo -e "\n📊 Contribution Graph Pattern Preview:"
for line in "${lines[@]}"; do
    echo "$line" | sed 's/[^[:space:]]/█/g'
done
echo

# 📅 Contribution position
col=$(date +%U)  # current week number
row_count=7      # GitHub graph rows: Sunday to Saturday
start_date=$(date -d "last sunday -51 weeks" +%Y-%m-%d)

echo "🖼️ Rendering '$message' into GitHub contribution graph (week $col)"

# 🟩 Loop through today's column and commit each non-space character
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
    echo "✅ Commits added for '$message'. Push to GitHub to update the graph!"
else
    echo "⚠️ No visible characters in today's column. Nothing committed."
fi
