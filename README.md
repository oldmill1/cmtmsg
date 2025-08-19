# cmtmsg-tool

AI-powered Conventional Commit Message Assistant.

## 📖 Overview

**cmtmsg-tool** is a command-line utility that uses OpenAI's GPT models to automatically generate
high-quality [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/) messages based on the current Git
diff in your working directory. It helps developers write clean and consistent commit messages with minimal effort.

## ✨ Features

- 💬 Generates meaningful commit messages using OpenAI models
- 💡 Follows the Conventional Commits specification
- 📄 Parses your current staged and unstaged changes (via `git diff`)
- ⚙️ Supports `.env` file for API key and model configuration
- ✅ Optional interactive or auto-confirm commit/push workflow

## 🚀 Quick Start

1. Clone the repository:

   ```bash
   git clone https://github.com/oldmill1/cmtmsg.git
   cd cmtmsg
   ```

2. Create a `.env` file in the root of the project:

   ```
   OPEN_AI_KEY=your_openai_api_key_here
   MODEL=gpt-4o
   ```

3. Make some code changes in your Git repo.

4. Run the tool:

   ```bash
   ./cmtmsg.sh
   ```

   Or to auto-confirm commit and push:

   ```bash
   ./cmtmsg.sh --confirm
   ```

## ⚙️ Configuration

| Variable      | Description                      | Example  |
|---------------|----------------------------------|----------|
| `OPEN_AI_KEY` | Your OpenAI API key              | `sk-...` |
| `MODEL`       | The model name to use (optional) | `gpt-4o` |

The `.env` file must be located in the same directory as the script.

## 🛠 Dependencies

Ensure the following tools are installed:

- `git`
- `bash`
- `curl`
- [`jq`](https://stedolan.github.io/jq/)
- Access to OpenAI’s [Chat Completions API](https://platform.openai.com/docs/guides/gpt)

## 🧪 Example Output

```
💬 Commit message:
feat(cli): add OpenAI-powered commit message generation

Uses current Git diff and generates meaningful Conventional Commits.
```

## 📦 License

MIT © [oldmill1](https://github.com/oldmill1)

## 🙌 Contributions

Feel free to open issues, suggest features, or submit pull requests!
