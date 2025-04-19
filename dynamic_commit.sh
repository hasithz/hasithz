#!/bin/bash

# Abort on error
set -e

# Git repo check
if [ ! -d ".git" ]; then
    echo "❌ Not a Git repository. Run in a Git-initialized folder."
    exit 1
fi

# Ensure figlet is installed
if ! command -v figlet &> /dev/null; then
    echo "🛠 Installing figlet..."
    sudo apt-get update && sudo apt-get install -y figlet
fi

# Message to render
MESSAGE=${1:-HASITH}

# Generate 52x7 ASCII art
figlet -w 52 -f banner "$MESSAGE" > pic.txt
mapfile -t lines < pic.txt

# Ensure height is 7 (GitHub graph height)
if [ "${#lines[@]}" -lt 7 ]; then
    echo "⚠️ ASCII art too short. Padding to 7 rows."
    while [ "${#lines[@]}" -lt 7 ]; do
        lines+=(" ")
    done
fi

# Preview
echo -e "\n📊 Commit Graph Preview:"
for line in "${lines[@]}"; do
    echo "$line" | sed 's/[^[:space:]]/█/g'
done
echo

# Start date: last Sunday - 51 weeks
start_date=$(date -d "last sunday -51 weeks" +%Y-%m-%d)

# Loop over the 52x7 grid
for row in {0..6}; do
    for col in {0..51}; do
        char="${lines[$row]:$col:1}"
        if [[ "$char" != " " && "$char" != "" ]]; then
            commit_date=$(date -d "$start_date +$col weeks +$row days" +%Y-%m-%d)
            for i in $(seq 1 5); do  # 5 commits per day = dark square
                echo "$commit_date - $MESSAGE fake commit $i" > fake.txt
                git add fake.txt
                GIT_AUTHOR_DATE="$commit_date 12:00:00" \
                GIT_COMMITTER_DATE="$commit_date 12:00:00" \
                git commit -m "[$MESSAGE] Fake commit $i on $commit_date"
            done
        fi
    done
done

rm -f fake.txt
echo "✅ All commits created. Push with: git push origin main --force"
