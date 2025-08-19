#!/usr/bin/env bash
set -e

# --- Terminal Colors (Retro Green Theme) ---
GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
DIM_GREEN='\033[2;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Retro Terminal Functions ---
print_status() {
  echo -e "${GREEN}[${1}]${NC} ${2}"
}

print_highlight() {
  echo -e "${BRIGHT_GREEN}[${1}]${NC} ${2}"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} ${1}"
}

print_progress() {
  local msg="$1"
  echo -ne "${DIM_GREEN}[PROC]${NC} ${msg}"
  for i in {1..3}; do
    sleep 0.3
    echo -ne "."
  done
  echo -e " ${GREEN}COMPLETE${NC}"
}

# --- Parse command line arguments ---
AUTO_CONFIRM=false
if [[ "$1" == "--confirm" ]]; then
  AUTO_CONFIRM=true
  print_status "INIT" "Auto-confirm mode enabled"
fi

# --- Resolve true script path even when symlinked ---
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# --- Load .env and override any shell exports ---
unset OPENAI_API_KEY
unset API_KEY

if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
  print_status "CONFIG" ".env loaded from $SCRIPT_DIR/.env"
else
  print_error ".env file not found in $SCRIPT_DIR"
  exit 1
fi

API_KEY="$OPEN_AI_KEY"
MODEL="${MODEL:-gpt-4o}"

print_status "AUTH" "OPEN_AI_KEY starts with: ${API_KEY:0:8}..."
print_status "MODEL" "Using model: $MODEL"

# --- Generate working diff ---
echo ""
print_status "SCAN" "Collecting working tree changes"
git add -N . > /dev/null
DIFF_CONTENT=$(git diff HEAD)

if [ -z "$DIFF_CONTENT" ]; then
  print_highlight "CLEAN" "No changes detected. Nothing to describe."
  exit 0
fi

# --- LLM prompt setup ---
SYSTEM_PROMPT="You are a commit message generator. You strictly follow the Conventional Commits format.

Your output must include:
- A one-line title: <type>[optional scope]: <description>
- An optional short body (1–2 lines), no bullet points, no Markdown, no backticks."

USER_PROMPT="Generate a Conventional Commit message (title and short body only) for the following git diff:\n\n$DIFF_CONTENT"

# --- Prepare JSON payload ---
REQUEST_JSON=$(jq -n \
  --arg model "$MODEL" \
  --arg system "$SYSTEM_PROMPT" \
  --arg prompt "$USER_PROMPT" \
  '{
    model: $model,
    messages: [
      { role: "system", content: $system },
      { role: "user", content: $prompt }
    ]
  }')

# --- Call OpenAI API ---
echo ""
print_progress "Transmitting to OpenAI API"

RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_JSON")

# --- Extract commit message ---
RAW_MSG=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null)
STRIPPED_MSG=$(echo "$RAW_MSG" | sed '/^```/d' | sed '/^\s*$/d')

if [ -z "$STRIPPED_MSG" ]; then
  print_error "Failed to extract commit message from LLM response."
  echo "$RAW_MSG"
  exit 1
fi

# --- Show result ---
echo ""
print_highlight "OUTPUT" "Generated commit message:"
echo ""
# Display each line of the message with simple indentation
while IFS= read -r line; do
  if [ ! -z "$line" ]; then
    echo -e "  ${BRIGHT_GREEN}$line${NC}"
  fi
done <<< "$STRIPPED_MSG"
echo ""

# --- Confirm commit ---
echo ""
if [ "$AUTO_CONFIRM" = true ]; then
  print_status "AUTO" "Auto-confirming commit"
  CONFIRM="y"
else
  echo -ne "${GREEN}[CONFIRM]${NC} Commit with this message? ${DIM_GREEN}(y/N)${NC} "
  read -r CONFIRM
fi

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  git add . 2>/dev/null
  git commit -m "$STRIPPED_MSG" --quiet
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  print_highlight "COMMIT" "Committed to $BRANCH"

  if [ "$AUTO_CONFIRM" = true ]; then
    print_status "AUTO" "Auto-confirming push"
    PUSH_CONFIRM="y"
  else
    echo -ne "${GREEN}[PUSH]${NC} Push to origin/$BRANCH? ${DIM_GREEN}(y/N)${NC} "
    read -r PUSH_CONFIRM
  fi

  if [[ "$PUSH_CONFIRM" =~ ^[Yy]$ ]]; then
    git push origin "$BRANCH" --quiet
    print_highlight "PUSH" "Changes pushed to origin/$BRANCH"
  else
    print_status "SKIP" "Push cancelled"
  fi
else
  print_status "SKIP" "Commit cancelled"
fi