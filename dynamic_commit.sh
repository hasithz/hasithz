#!/usr/bin/env bash
set -euo pipefail             # stop on any error

###############################################################################
# 0. Get the *root* commit robustly (no reliance on the message text)
###############################################################################
if [[ "${RESET_HISTORY:-0}" == "1" ]]; then
  root_commit=$(git rev-list --max-parents=0 HEAD | tail -1)
  echo "🔄 Forcing full reset to root commit: $root_commit"
  git reset --hard "$root_commit"
else
  echo "⏩  No history reset (keeping previous drawings)"
fi

###############################################################################
# 1. Ensure figlet is available (skip install inside Actions for speed)
###############################################################################
if ! command -v figlet &>/dev/null; then
  echo "🛠  Installing figlet locally…"
  sudo apt-get update -qq && sudo apt-get install -y figlet
fi

###############################################################################
# 2. Load message list (create default if the file is missing)
###############################################################################
WORDS_FILE="messages.txt"
if [[ ! -f $WORDS_FILE ]]; then
  printf "HASITH\nHELLO\n❤️\nDREAM\nBUILD\nENJOY\n" > "$WORDS_FILE"
  echo "✅  Created default $WORDS_FILE"
fi

mapfile -t words < "$WORDS_FILE"
[[ ${#words[@]} -gt 0 ]] || { echo "❌ $WORDS_FILE is empty"; exit 1; }

# Rotate through the list by day‑of‑year
word="${words[$(( $(date +%j) % ${#words[@]} ))]}"
echo "🎯 Word of the day: $word"

###############################################################################
# 3. Convert the word to a 52×7 bitmap
###############################################################################
PIC=".pic.tmp"
figlet -w 52 -f banner "$word" > "$PIC"

mapfile -t lines < "$PIC"
while ((${#lines[@]} < 7)); do lines+=(""); done          # pad to 7 rows

echo -e "\n📊 Preview:"
for l in "${lines[@]}"; do
  printf '%-52s\n' "${l:0:52}" | sed 's/[^[:space:]]/█/g'
done
echo

###############################################################################
# 4. Commit loop (one pixel = 6 commits → medium‑dark square)
###############################################################################
base=$(date -d "last sunday -51 weeks" +%Y-%m-%d)

for row in {0..6}; do
  for col in {0..51}; do
    char="${lines[$row]:$col:1}"
    [[ -n $char && $char != ' ' ]] || continue

    day=$(date -d "$base +$col weeks +$row days" +%Y-%m-%d)
    for i in {1..6}; do
      echo "$day – pixel ($row,$col) $i" > fake.txt
      git add fake.txt
      GIT_AUTHOR_DATE="$day 12:00:00" \
      GIT_COMMITTER_DATE="$day 12:00:00" \
      git commit -q -m "[$word] pixel ($row,$col) commit $i"
    done
  done
done

rm -f fake.txt "$PIC"
echo "✅ All commits staged. Push with --force to overwrite history."
