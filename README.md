### 📝 `README.md`

```markdown
```

   ____ ___  __  __ _______ __  __ ____   ____ _______     __
/ ___/ _ \| \/ |__   __| \/ | _ \ / __ \__   __| / /
| | | | | | \ / | | | | \ / | |_) | | | | | | / /
| |__| |_| | |\/| | | | | |\/| |  __/| |__| | | | / /  
\____\___/|_| |_| |_| |_| |_|_| \____/ |_| /_/

-------------------------------------------------------------
🚀 AI-Powered Conventional Commit Message Assistant

     AUTHOR  : oldmill1
     TOOL    : cmtmsg-tool
     VERSION : v1.0.0
     LICENSE : MIT
     URL     : https://github.com/oldmill1/cmtmsg

-------------------------------------------------------------

> > DESCRIPTION
> > cmtmsg-tool is a command-line utility that auto-generates
> > Conventional Commit messages using OpenAI's GPT model.
> > Designed to enhance your git workflow with intelligent,
> > consistent, and clean commit messages, every time.

> > FEATURES

- 🤖 GPT-powered commit message generation
- ✍️ Follows Conventional Commits format
- 🔍 Parses your current Git diff
- ✅ .env-based secret config
- 🆗 Auto-confirm commit & push
- 🧵 Clean, minimal output

> > USAGE

$ ./cmtmsg.sh → Generate commit message interactively
$ ./cmtmsg.sh --confirm → Automatically commit & push

Ensure you have a `.env` file in the same directory with:
OPEN_AI_KEY=your-api-key-here

> > DEPENDENCIES

- git
- curl
- jq
- bash
- OpenAI API access

> > EXAMPLE

📥 Git diff found
📡 Sending to GPT model...
💬 Suggested message:
feat(cli): add support for AI-generated commit messages

> > INSTALL

$ git clone https://github.com/oldmill1/cmtmsg.git
$ cd cmtmsg
$ cp .env.example .env # Add your OpenAI key
$ ./cmtmsg.sh

> > CONTRIBUTING
> > Pull requests are welcome. For major changes,
> > please open an issue first to discuss what you’d like to change.

> > ⚠️ REMEMBER
> > With great AI comes great responsibility.
> > Review your commits before you push 🚀

-------------------------------------------------------------

      [ SYSTEM READY ] :: PRESS ENTER TO COMMIT 🤘

-------------------------------------------------------------

```
```