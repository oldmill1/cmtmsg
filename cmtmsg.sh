#!/usr/bin/env bash
set -e

# --- Parse command line arguments ---
AUTO_CONFIRM=false
if [[ "$1" == "--confirm" ]]; then
  AUTO_CONFIRM=true
  echo "🚀 Auto-confirm mode enabled"
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
  echo "✅ .env loaded from $SCRIPT_DIR/.env"
else
  echo "❌ .env file not found in $SCRIPT_DIR"
  exit 1
fi

API_KEY="$OPEN_AI_KEY"
MODEL="${MODEL:-gpt-4o}"

echo "🔑 OPEN_AI_KEY starts with: ${API_KEY:0:8}..."
echo "🤖 MODEL is set to: $MODEL"

# --- Generate working diff ---
echo -e "\n📥 Collecting working tree changes..."
git add -N . > /dev/null
DIFF_CONTENT=$(git diff HEAD)

if [ -z "$DIFF_CONTENT" ]; then
  echo "✅ No changes detected. Nothing to describe."
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
echo -e "\n📡 Sending request to OpenAI..."
RESPONSE=$(curl -s https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_JSON")

# --- Extract commit message ---
RAW_MSG=$(echo "$RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null)
STRIPPED_MSG=$(echo "$RAW_MSG" | sed '/^```/d' | sed '/^\s*$/d')

if [ -z "$STRIPPED_MSG" ]; then
  echo "❌ Failed to extract commit message from LLM response."
  echo "$RAW_MSG"
  exit 1
fi

# --- Show result ---
echo -e "\n💬 Commit message:"
echo "$STRIPPED_MSG"

# --- Confirm commit ---
if [ "$AUTO_CONFIRM" = true ]; then
  echo "🟢 Auto-confirming commit..."
  CONFIRM="y"
else
  read -r -p "🟢 Commit with this message? (y/N) " CONFIRM
fi

if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  git add .
  git commit -m "$STRIPPED_MSG"
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  echo "✅ Committed to $BRANCH"

  if [ "$AUTO_CONFIRM" = true ]; then
    echo "📤 Auto-confirming push..."
    PUSH_CONFIRM="y"
  else
    read -r -p "📤 Push to origin/$BRANCH? (y/N) " PUSH_CONFIRM
  fi

  if [[ "$PUSH_CONFIRM" =~ ^[Yy]$ ]]; then
    git push origin "$BRANCH"
    echo "✅ Changes pushed to origin/$BRANCH"
  else
    echo "❌ Skipping push."
  fi
else
  echo "❌ Skipping commit."
fi