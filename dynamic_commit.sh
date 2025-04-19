#!/bin/bash

set -e

### 1. Clean previous Git history
echo "🧹 Resetting .git history..."
rm -rf .git
git init
git checkout -b main

### 2. Create messages.txt if not present
if [ ! -f messages.txt ]; then
    echo -e "HASITH\nHELLO\n❤️\nDREAM\nBUILD\nENJOY" > messages.txt
    echo "✅ Created default messages.txt"
fi

### 3. Ensure figlet is installed
if ! command -v figlet &> /dev/null; then
    echo "🛠 Installing figlet..."
    sudo apt-get update && sudo apt-get install -y figlet
fi

### 4. Pick a message of the day
mapfile -t messages < messages.txt
msg_count=${#messages[@]}
if [ "$msg_count" -eq 0 ]; then
    echo "❌ 'messages.txt' is empty."
    exit 1
fi

day_of_year=$(date +%j)
word_index=$((day_of_year % msg_count))
word="${messages[$word_index]}"
echo "🎯 Selected message: $word"

### 5. Generate ASCII art
figlet -w 52 -f banner "$word" > pic.txt
mapfile -t lines < pic.txt

# Pad to 7 rows (GitHub contribution graph height)
while [ "${#lines[@]}" -lt 7 ]; do
  lines+=("")
done

### 6. Show preview
echo -e "\n📊 Contribution Graph Preview:"
for line in "${lines[@]}"; do
    echo "$line" | sed 's/[^[:space:]]/█/g'
done
echo

### 7. Start commit process
start_date=$(date -d "last sunday -51 weeks" +%Y-%m-%d)

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
echo "✅ All commits done. Push using: git push origin main --force"
