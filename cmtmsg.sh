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

# --- Animation Functions ---
show_progress_bar() {
  local total_steps="$1"
  local current_step="$2"
  local width=50
  local filled=$((current_step * width / total_steps))
  local empty=$((width - filled))
  
  printf "\r${CYAN}[PROGRESS]${NC} ["
  printf "%*s" $filled | tr ' ' '█'
  printf "%*s" $empty | tr ' ' '░'
  printf "] %d%% (%d/%d)" $((current_step * 100 / total_steps)) $current_step $total_steps
}

flash_message() {
  local tag="$1"
  local message="$2"
  local duration="${3:-1.5}"
  
  # Clear the line and show message
  printf "\r\033[K${GREEN}[${tag}]${NC} ${message}\n"
  sleep "$duration"
  # Clear the line
  printf "\033[1A\033[K"
}

clear_screen() {
  printf "\033[2J\033[H"
}

# --- Parse command line arguments ---
AUTO_CONFIRM=false
UPSTREAM_NAME="origin"

while [[ $# -gt 0 ]]; do
  case $1 in
    --confirm)
      AUTO_CONFIRM=true
      flash_message "INIT" "Auto-confirm mode enabled"
      shift
      ;;
    --upstream-name=*)
      UPSTREAM_NAME="${1#*=}"
      flash_message "INIT" "Upstream name set to: $UPSTREAM_NAME"
      shift
      ;;
    --upstream-name)
      if [[ -n $2 && $2 != -* ]]; then
        UPSTREAM_NAME="$2"
        flash_message "INIT" "Upstream name set to: $UPSTREAM_NAME"
        shift 2
      else
        print_error "--upstream-name requires a value"
        exit 1
      fi
      ;;
    *)
      print_error "Unknown option: $1"
      echo "Usage: $0 [--confirm] [--upstream-name=<name>] [--upstream-name <name>]"
      exit 1
      ;;
  esac
done

# --- Resolve true script path even when symlinked ---
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

# --- Initialize progress tracking ---
TOTAL_STEPS=8
CURRENT_STEP=0

# Show initial progress bar
show_progress_bar $TOTAL_STEPS $CURRENT_STEP

# --- Load .env and override any shell exports ---
unset OPENAI_API_KEY
unset API_KEY

if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  show_progress_bar $TOTAL_STEPS $CURRENT_STEP
  flash_message "CONFIG" ".env loaded from $SCRIPT_DIR/.env"
else
  print_error ".env file not found in $SCRIPT_DIR"
  exit 1
fi

API_KEY="$OPEN_AI_KEY"
MODEL="${MODEL:-gpt-4o}"

CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress_bar $TOTAL_STEPS $CURRENT_STEP
flash_message "AUTH" "OPEN_AI_KEY starts with: ${API_KEY:0:8}..."

CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress_bar $TOTAL_STEPS $CURRENT_STEP
flash_message "MODEL" "Using model: $MODEL"

# --- Generate working diff ---
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress_bar $TOTAL_STEPS $CURRENT_STEP
flash_message "SCAN" "Collecting working tree changes"

# Add untracked files for diff generation, but handle ignored files gracefully
git add -N . 2>/dev/null || true

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
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress_bar $TOTAL_STEPS $CURRENT_STEP
flash_message "PROC" "Transmitting to OpenAI API..." 2.0

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
CURRENT_STEP=$((CURRENT_STEP + 1))
show_progress_bar $TOTAL_STEPS $CURRENT_STEP
flash_message "OUTPUT" "Generated commit message:" 2.0

# Display each line of the message with simple indentation
while IFS= read -r line; do
  if [ ! -z "$line" ]; then
    echo -e "  ${BRIGHT_GREEN}$line${NC}"
  fi
done <<< "$STRIPPED_MSG"
echo ""

# --- Confirm commit ---
if [ "$AUTO_CONFIRM" = true ]; then
  CURRENT_STEP=$((CURRENT_STEP + 1))
  show_progress_bar $TOTAL_STEPS $CURRENT_STEP
  flash_message "AUTO" "Auto-confirming commit"
  CONFIRM="y"
else
  echo -ne "${GREEN}[CONFIRM]${NC} Commit with this message? ${DIM_GREEN}(y/N)${NC} "
  read -r CONFIRM
fi

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  git add . 2>/dev/null
  git commit -m "$STRIPPED_MSG" --quiet
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  CURRENT_STEP=$((CURRENT_STEP + 1))
  show_progress_bar $TOTAL_STEPS $CURRENT_STEP
  flash_message "COMMIT" "Committed to $BRANCH"

  if [ "$AUTO_CONFIRM" = true ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_progress_bar $TOTAL_STEPS $CURRENT_STEP
    flash_message "AUTO" "Auto-confirming push"
    PUSH_CONFIRM="y"
  else
    echo -ne "${GREEN}[PUSH]${NC} Push to $UPSTREAM_NAME/$BRANCH? ${DIM_GREEN}(y/N)${NC} "
    read -r PUSH_CONFIRM
  fi

  if [[ "$PUSH_CONFIRM" =~ ^[Yy]$ ]]; then
    git push "$UPSTREAM_NAME" "$BRANCH" --quiet
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_progress_bar $TOTAL_STEPS $CURRENT_STEP
    flash_message "PUSH" "Changes pushed to $UPSTREAM_NAME/$BRANCH"
  else
    flash_message "SKIP" "Push cancelled"
  fi

  # Complete progress bar and clear screen for celebration
  show_progress_bar $TOTAL_STEPS $TOTAL_STEPS
  sleep 1
  clear_screen
  echo ""
  echo -e "${YELLOW}   \\ | /${NC}"
  echo -e "${YELLOW}  -- ${BRIGHT_GREEN}@${NC}${YELLOW} --${NC}"
  echo -e "${YELLOW}   / | \\${NC}"
  echo -e "${GREEN}     |${NC}"
  echo -e "${GREEN}     |${NC}"
  echo -e "${BRIGHT_GREEN}   POWER${NC}"
  echo -e "${BRIGHT_GREEN}    UP!${NC}"

else
  flash_message "SKIP" "Commit cancelled"
fi