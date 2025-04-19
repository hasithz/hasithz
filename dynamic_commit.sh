#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────── CONFIG ──────────────────────────────
WORDS_FILE="messages.txt"      # 1 word/emoji per line
COMMITS_PER_CELL=12            # 1‑30 → light→dark
FONT="standard"                # any figlet font installed locally
START_TIME="12:00:00"          # commit time of day (HH:MM:SS)
PATTERN_FILE=".pattern.tmp"    # temp bitmap (auto‑deleted)
# ────────────────────────────────────────────────────────────────────

### 0. Prepare a *fresh* repo so old commits don’t re‑appear
if [ -d .git ]; then
  read -p "Repo already exists. Completely reset history? (y/N) " YES
  [[ $YES == y* ]] || { echo "Aborted."; exit 1; }
  rm -rf .git
fi
git init -q

### 1. Pick a word (rotates daily)
mapfile -t WORDS < "$WORDS_FILE"
idx=$(( $(date +%j) % ${#WORDS[@]} ))
WORD="${WORDS[$idx]}"
echo "→ Rendering '$WORD' for today’s pattern"

### 2. Convert to a 52×7 bitmap
figlet -w 52 -f "$FONT" "$WORD" \
 | sed 's/[^ ]/#/g' \
 | awk '{printf "%-52s\n", substr($0,1,52)}' \
 | head -n 7 > "$PATTERN_FILE"

echo "→ Preview:"
sed 's/#/█/g' "$PATTERN_FILE"

### 3. Calculate bottom‑left date (last Sunday, 51 weeks ago)
START_DATE=$(date -d "last sunday -51 weeks" +%Y-%m-%d)
echo "→ First cell = $START_DATE"

### 4. Paint the grid with fake commits
ROW=0
while IFS= read -r LINE; do
  for COL in {0..51}; do
    [[ "${LINE:$COL:1}" == "#" ]] || continue
    CELL_DATE=$(date -d "$START_DATE +$COL weeks +$ROW days" +%Y-%m-%d)
    for i in $(seq 1 $COMMITS_PER_CELL); do
      echo "$CELL_DATE • $WORD • $i" > .dummy.txt
      git add .dummy.txt
      GIT_AUTHOR_DATE="$CELL_DATE $START_TIME" \
      GIT_COMMITTER_DATE="$CELL_DATE $START_TIME" \
      git commit -q -m "$WORD pixel ($ROW,$COL) $i"
    done
  done
  ROW=$((ROW + 1))
done < "$PATTERN_FILE"

rm -f "$PATTERN_FILE" .dummy.txt
echo "✔  Done!\nPush with:"
echo "   git branch -M main"
echo "   git remote add origin <YOUR_REPO_URL>"
echo "   git push -u origin main"
