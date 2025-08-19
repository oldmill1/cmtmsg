# 🧠 cmtmsg-tool

_Zero-effort, AI-generated commit messages. Powered by OpenAI._

---

## Output Example

```bash
➜  cmtmsg-tool git:(main) ✗ cmtmsg
[CONFIG] .env loaded from /Users/ataxali/dev/cmtmsg-tool/.env
[AUTH] OPEN_AI_KEY starts with: sk-proj-...
[MODEL] Using model: gpt-4o

[SCAN] Collecting working tree changes

[PROC] Transmitting to OpenAI API... COMPLETE

[OUTPUT] Generated commit message:

  chore(cmtmsg): update ASCII art to celebration
  Replaced sunflower ASCII art with a celebration motif to enhance script output.


[CONFIRM] Commit with this message? (y/N) y
[COMMIT] Committed to main
[PUSH] Push to origin/main? (y/N) y
[PUSH] Changes pushed to origin/main

   \ | /
  -- @ --
   / | \033[0m
     |
     |
   POWER
    UP!
➜  cmtmsg-tool git:(main) 
```

## 🤔 Why

Stop writing commit messages.  
Let your code **explain itself**.

---

## ⚡️ What It Does

- Parses your working `git diff`
- Sends it to OpenAI's GPT (configurable model)
- Returns a Conventional Commit message
- Optionally commits and pushes it — fully hands-free

---

## 🚀 Quick Start

```bash
# clone your fork
git clone https://github.com/oldmill1/cmtmsg.git
cd cmtmsg

# add your OpenAI API key
cp .env.example .env
```

`.env` file contents:

```dotenv
OPEN_AI_KEY=sk-xxx
MODEL=gpt-4o
```

Make changes to your repo, then run:

```bash
./cmtmsg.sh          # interactively review
./cmtmsg.sh --confirm  # fire-and-forget mode
```

---

## ✅ Requirements

- `git`
- `bash`
- `curl`
- [`jq`](https://stedolan.github.io/jq/)
- OpenAI API key

---

## ⚙️ Config Options (`.env`)

| Key           | Purpose                   | Default  |
|---------------|---------------------------|----------|
| `OPEN_AI_KEY` | Your OpenAI API key       | —        |
| `MODEL`       | GPT model for description | `gpt-4o` |

---

## 🧪 Example Output

```txt
💬 Commit message:

feat(cli): add OpenAI-powered commit message generation

Uses current Git diff and generates meaningful Conventional Commits.
```

---

## 📦 License

MIT © [@oldmill1](https://github.com/oldmill1)

---

## 👋 Contributing

Pull requests, issues, and ideas are welcome.  
This is built to be simple — let's keep it that way.