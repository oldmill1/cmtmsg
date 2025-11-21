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


# --- Beautiful Progress Bar ---
show_progress_bar() {
  local total_steps="$1"
  local current_step="$2"
  local step_name="$3"
  local width=40
  local filled=$((current_step * width / total_steps))
  local empty=$((width - filled))
  local percentage=$((current_step * 100 / total_steps))
  
  # Beautiful minimalistic progress bar
  printf "\r${BRIGHT_GREEN}⚡${NC} ${CYAN}%s${NC} " "$step_name"
  printf "${DIM_GREEN}[${NC}"
  printf "${BRIGHT_GREEN}%*s${NC}" $filled | tr ' ' '▰'
  printf "${DIM_GREEN}%*s${NC}" $empty | tr ' ' '▱'
  printf "${DIM_GREEN}]${NC} ${YELLOW}%d%%${NC}" $percentage
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
      shift
      ;;
    --upstream-name=*)
      UPSTREAM_NAME="${1#*=}"
      shift
      ;;
    --upstream-name)
      if [[ -n $2 && $2 != -* ]]; then
        UPSTREAM_NAME="$2"
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

# --- Load .env and override any shell exports ---
unset OPENAI_API_KEY
unset API_KEY

if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
  if [ "$AUTO_CONFIRM" != true ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_progress_bar $TOTAL_STEPS $CURRENT_STEP "Loading config"
  fi
else
  print_error ".env file not found in $SCRIPT_DIR"
  exit 1
fi

API_KEY="$OPEN_AI_KEY"
MODEL="${MODEL:-gpt-4o}"

if [ "$AUTO_CONFIRM" != true ]; then
  CURRENT_STEP=$((CURRENT_STEP + 1))
  show_progress_bar $TOTAL_STEPS $CURRENT_STEP "Authenticating"
fi

if [ "$AUTO_CONFIRM" != true ]; then
  CURRENT_STEP=$((CURRENT_STEP + 1))
  show_progress_bar $TOTAL_STEPS $CURRENT_STEP "Initializing model"
fi

# --- Generate working diff ---
if [ "$AUTO_CONFIRM" != true ]; then
  CURRENT_STEP=$((CURRENT_STEP + 1))
  show_progress_bar $TOTAL_STEPS $CURRENT_STEP "Scanning changes"
fi

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
if [ "$AUTO_CONFIRM" != true ]; then
  CURRENT_STEP=$((CURRENT_STEP + 1))
  show_progress_bar $TOTAL_STEPS $CURRENT_STEP "Generating message"
fi

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
if [ "$AUTO_CONFIRM" != true ]; then
  CURRENT_STEP=$((CURRENT_STEP + 1))
  show_progress_bar $TOTAL_STEPS $CURRENT_STEP "Processing output"
fi

# For --confirm flag, only show the commit message without any formatting
if [ "$AUTO_CONFIRM" = true ]; then
  echo "$STRIPPED_MSG"
else
  # Display each line of the message with simple indentation for non-confirm mode
  while IFS= read -r line; do
    if [ ! -z "$line" ]; then
      echo -e "  ${BRIGHT_GREEN}$line${NC}"
    fi
  done <<< "$STRIPPED_MSG"
  echo ""
fi

# --- Confirm commit ---
if [ "$AUTO_CONFIRM" = true ]; then
  CONFIRM="y"
else
  CURRENT_STEP=$((CURRENT_STEP + 1))
  show_progress_bar $TOTAL_STEPS $CURRENT_STEP "Committing changes"
  echo -ne "${GREEN}[CONFIRM]${NC} Commit with this message? ${DIM_GREEN}(y/N)${NC} "
  read -r CONFIRM
fi

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  git add . 2>/dev/null
  git commit -m "$STRIPPED_MSG" --quiet
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [ "$AUTO_CONFIRM" != true ]; then
    CURRENT_STEP=$((CURRENT_STEP + 1))
    show_progress_bar $TOTAL_STEPS $CURRENT_STEP "Pushing to remote"
  fi

  if [ "$AUTO_CONFIRM" = true ]; then
    PUSH_CONFIRM="y"
  else
    echo -ne "${GREEN}[PUSH]${NC} Push to $UPSTREAM_NAME/$BRANCH? ${DIM_GREEN}(y/N)${NC} "
    read -r PUSH_CONFIRM
  fi

  if [[ "$PUSH_CONFIRM" =~ ^[Yy]$ ]]; then
    git push "$UPSTREAM_NAME" "$BRANCH" --quiet
    if [ "$AUTO_CONFIRM" != true ]; then
      CURRENT_STEP=$((CURRENT_STEP + 1))
      show_progress_bar $TOTAL_STEPS $CURRENT_STEP "Complete!"
      
      # Complete progress bar and clear screen for celebration
      show_progress_bar $TOTAL_STEPS $TOTAL_STEPS
      clear_screen
      echo ""
      echo -e "${YELLOW}   \\ | /${NC}"
      echo -e "${YELLOW}  -- ${BRIGHT_GREEN}@${NC}${YELLOW} --${NC}"
      echo -e "${YELLOW}   / | \\${NC}"
      echo -e "${GREEN}     |${NC}"
      echo -e "${GREEN}     |${NC}"
      echo -e "${BRIGHT_GREEN}   POWER${NC}"
      echo -e "${BRIGHT_GREEN}    UP!${NC}"
    fi
  fi

else
  if [ "$AUTO_CONFIRM" != true ]; then
    print_status "SKIP" "Commit cancelled"
  fi
fi