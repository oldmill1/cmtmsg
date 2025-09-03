# CMTMSG(1)

## NAME

**cmtmsg** - AI-powered git commit message generator

## SYNOPSIS

**cmtmsg** [**--confirm**] [**--upstream-name**=*NAME*]

## DESCRIPTION

**cmtmsg** generates conventional commit messages using OpenAI's API based on your git working tree changes. It analyzes the diff and creates properly formatted commit messages following the Conventional Commits specification.

The script requires a `.env` file in the same directory containing your OpenAI API key as `OPEN_AI_KEY`.

## OPTIONS

**--confirm**
: Skip confirmation prompts and automatically commit and push changes

**--upstream-name**=*NAME*
: Specify the upstream remote name (default: origin)

**--upstream-name** *NAME*
: Alternative syntax for specifying upstream remote name

## FILES

**.env**
: Configuration file containing `OPEN_AI_KEY` and optional `MODEL` variables

## ENVIRONMENT

**OPEN_AI_KEY**
: OpenAI API key (loaded from .env file)

**MODEL**
: OpenAI model to use (default: gpt-4o, loaded from .env file)

## EXAMPLES

Generate commit message with prompts:
```
cmtmsg
```

Auto-commit and push to origin:
```
cmtmsg --confirm
```

Use custom upstream remote:
```
cmtmsg --upstream-name=upstream
```

Auto-commit with custom remote:
```
cmtmsg --confirm --upstream-name=fork
```

## EXIT STATUS

**0** - Success or no changes detected  
**1** - Error (missing .env, API failure, invalid arguments)

## AUTHOR

Generated commit messages follow the Conventional Commits format with type, scope, and description.