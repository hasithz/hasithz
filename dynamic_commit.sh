#!/bin/bash

set -e

# 1. Git check
if [ ! -d ".git" ]; then
    echo "❌ Not a Git repo. Run in a git-initialized folder."
    exit 1
fi

# 2. Ensure figlet is installed
if ! command -v figlet &> /dev/null; then
    echo "🛠 Installing figlet..."
    sudo apt-get update && sudo apt-get install -y figlet
fi

# 3. Load words list
if [ ! -f messages.txt ]; then
    echo "HASITH\nHELLO\n❤️\nDREAM\nBUILD\nENJOY" > messages.txt
fi

mapfile -t messages < messages.txt
msg_count=${#messages[@]}
if [ "$msg_count" -eq 0 ]; then
    echo "❌ 'messages.txt' is empty."
    exit 1
fi

# 4. Pick a word based on the day
day_of_year=$(date +%j)
word_index=$((day_of_year % msg_count))
word="${messages[$word_index]}"

echo "🎯 Rendering word: $word"

# 5. Generate ASCII art
figlet -w 52 -f banner "$word" > pic.txt
mapfile -t lines < pic.txt

# Make sure we have at least 7 rows (GitHub graph rows)
while [ "${#lines[@]}" -lt 7 ]; do
  lines+=("")
done

# 6. Preview
echo -e "\n📊 Commit Graph Pattern Preview:"
for line in "${lines[@]}"; do
    echo "$line" | sed 's/[^[:space:]]/█/g'
done
echo

# 7. Start from 52 weeks ago
start_date=$(date -d "last sunday -51 weeks" +%Y-%m-%d)

# 8. Commit every visible pixel
for row in {0..6}; do
  for col in {0..51}; do
    char="${lines[$row]:$col:1}"
    if [[ "$char" != " " && "$char" != "" ]]; then
      commit_date=$(date -d "$start_date +$col weeks +$row days" +%Y-%m-%d)
      for i in $(seq 1 6); do
        echo "$commit_date - $word commit $i" > fake.txt
        git add fake.txt
        GIT_AUTHOR_DATE="$commit_date 12:00:00" \
        GIT_COMMITTER_DATE="$commit_date 12:00:00" \
        git commit -m "[$word] Commit $i on $commit_date"
      done
    fi
  done
done

rm -f fake.txt
echo "✅ Done drawing '$word'. Now run: git push origin main --force"
echo "💾 Your commit history is now a work of art!"