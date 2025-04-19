#!/bin/bash

set -e

### 1. Full reset of git history
echo "🧨 Wiping all Git history..."

### 2. Preserve your existing README.md but do not modify it
initial_date=$(date -d "last sunday -51 weeks" +%Y-%m-%d)

GIT_AUTHOR_DATE="$initial_date 00:00:00" \
GIT_COMMITTER_DATE="$initial_date 00:00:00" \
git commit -m "initial commit"

echo "✅ Backdated initial commit created at $initial_date"

### 3. Ensure figlet is installed
if ! command -v figlet &> /dev/null; then
    echo "🛠 Installing figlet..."
    sudo apt-get update && sudo apt-get install -y figlet
fi

### 4. Ensure messages.txt exists
if [ ! -f messages.txt ]; then
    echo -e "HASITH\nHELLO\n❤️\nDREAM\nBUILD\nENJOY" > messages.txt
    echo "✅ Created default messages.txt"
fi

### 5. Randomly select a word from messages.txt
mapfile -t messages < messages.txt
msg_count=${#messages[@]}

if [ "$msg_count" -eq 0 ]; then
    echo "❌ 'messages.txt' is empty."
    exit 1
fi

word="${messages[$((RANDOM % msg_count))]}"
echo "🎯 Randomly selected word: $word"

### 6. Generate ASCII pattern (52 wide, up to 7 high)
figlet -w 52 -f banner "$word" > pic.txt
mapfile -t lines < pic.txt

# Pad to 7 rows if needed
while [ "${#lines[@]}" -lt 7 ]; do
    lines+=("")
done

### 7. Preview pattern in terminal
echo -e "\n📊 Contribution Graph Pattern Preview:"
for line in "${lines[@]}"; do
    echo "$line" | sed 's/[^[:space:]]/█/g'
done
echo

### 8. Start commit grid drawing
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
echo "✅ All commits added. Push using:"
echo "   git push origin main --force"
