# Operating Environment

You are running inside **opencode** (v1.15.0+), a terminal-based AI coding agent.
This file is loaded globally via `instructions` in `~/.config/opencode/opencode.json`
— every model invoked through opencode for this user sees it.

The user runs **Linux (WSL2 Debian)** with **Guix Home** managing dotfiles and
tooling. Default shell is **zsh**. Working dir is the project passed to
`opencode [project]`.

The schemas below are extracted from `sst/opencode` (`packages/opencode/src/tool/*`).
If a schema field is not documented here, **omit it** — do NOT invent params.

---

## Tool-calling protocol

- Use the **OpenAI tool-calling JSON format**: emit calls via `tool_calls` on an
  assistant message with `function.name` and `function.arguments` (stringified
  JSON object).
- **Do NOT** emit XML-style calls (`<tool_call>`, `<function=...>`,
  `<|tool▁call|>`). Other harnesses use those; opencode will not parse them.
- `function.arguments` MUST be valid, complete JSON — close every brace and
  bracket before emitting.
- For optional params, **omit the key entirely**. Never send `"undefined"` or
  `"null"` strings.
- One tool call per turn unless the active provider supports parallel calls.

---

## Built-in tools — exact schemas

### `read`

Read file contents.

| Param      | Type               | Required | Default | Description                                                |
| ---------- | ------------------ | -------- | ------- | ---------------------------------------------------------- |
| `filePath` | string             | yes      | —       | Absolute path to the file or directory to read.            |
| `offset`   | non-negative int   | no       | —       | Line number to start from (1-indexed).                     |
| `limit`    | non-negative int   | no       | 2000    | Max number of lines to read.                               |

Use `offset`/`limit` for files > 2000 lines. For directories, `read` returns the
listing — there is no separate `list` tool.

### `edit`

Surgical string replacement in an existing file. **Must `read` the file first.**

| Param        | Type    | Required | Default | Description                                                          |
| ------------ | ------- | -------- | ------- | -------------------------------------------------------------------- |
| `filePath`   | string  | yes      | —       | Absolute path to the file.                                           |
| `oldString`  | string  | yes      | —       | Exact text to replace.                                               |
| `newString`  | string  | yes      | —       | Replacement text. Must differ from `oldString`.                      |
| `replaceAll` | boolean | no       | false   | Replace every occurrence vs. fail when `oldString` is non-unique.    |

When `oldString` matches multiple times and `replaceAll` is false, the tool
errors — widen the surrounding context until unique.

### `write`

Create a new file or fully overwrite one.

| Param      | Type   | Required | Default | Description                                                            |
| ---------- | ------ | -------- | ------- | ---------------------------------------------------------------------- |
| `filePath` | string | yes      | —       | Absolute path (must be absolute, not relative).                        |
| `content`  | string | yes      | —       | File contents.                                                         |

If the file exists, opencode requires you to `read` it first (in-context state
check). Prefer `edit` for existing files.

### `apply_patch`

Apply a multi-file unified-diff style patch. Paths are embedded in the patch
text via `*** Add File:`, `*** Update File:`, `*** Delete File:` markers.

| Param       | Type   | Required | Default | Description                                                  |
| ----------- | ------ | -------- | ------- | ------------------------------------------------------------ |
| `patchText` | string | yes      | —       | Full patch text describing every change.                     |

### `bash` (aka `shell`)

Run a shell command in zsh.

| Param         | Type   | Required | Default     | Description                                                   |
| ------------- | ------ | -------- | ----------- | ------------------------------------------------------------- |
| `command`     | string | yes      | —           | Shell command to execute.                                     |
| `description` | string | yes      | —           | Human-readable description shown to the user.                 |
| `workdir`     | string | no       | project dir | Override the working directory.                               |
| `timeout`     | number | no       | 120000 (ms) | Execution timeout in milliseconds. Must be positive.          |

Use dedicated tools (`read`/`edit`/`write`/`glob`/`grep`) instead of shelling
out to `cat`/`sed`/`echo`/`find`/`rg` when a dedicated tool fits.

### `glob`

Find files by pattern.

| Param     | Type   | Required | Default     | Description                                                                                       |
| --------- | ------ | -------- | ----------- | ------------------------------------------------------------------------------------------------- |
| `pattern` | string | yes      | —           | Glob pattern (e.g. `src/**/*.ts`).                                                                |
| `path`    | string | no       | project dir | Directory to search in. **Omit** for default — never send the literal string `"undefined"`/`"null"`. |

Results are sorted by modification time (most recent first).

### `grep`

Regex content search; respects `.gitignore`.

| Param     | Type   | Required | Default     | Description                                                |
| --------- | ------ | -------- | ----------- | ---------------------------------------------------------- |
| `pattern` | string | yes      | —           | Regex pattern to match in file contents.                   |
| `path`    | string | no       | project dir | Directory to search in.                                    |
| `include` | string | no       | —           | File filter glob (e.g. `*.ts`, `*.{ts,tsx}`).              |

### `task`

Delegate to a subagent. Subagents run in an isolated context window and return
a single message; they do **not** see this conversation.

| Param           | Type    | Required | Default | Description                                                                |
| --------------- | ------- | -------- | ------- | -------------------------------------------------------------------------- |
| `description`   | string  | yes      | —       | Short 3–5-word task description.                                           |
| `prompt`        | string  | yes      | —       | Self-contained task brief for the subagent.                                |
| `subagent_type` | string  | yes      | —       | Subagent name (see Subagents below).                                       |
| `task_id`       | string  | no       | —       | Resume a previous subagent session by its `task_id`.                       |
| `command`       | string  | no       | —       | Command that triggered the task (rarely needed).                           |
| `background`    | boolean | no       | false   | Launch in background and return immediately (experimental, may be absent). |

Write `prompt` like a brief to a colleague who just walked in: state goal,
constraints, what to return. Subagents have no shared memory across calls
unless you pass `task_id`.

### `todowrite`

Maintain the visible task checklist. **Disabled for subagents by default.**

`todos` is an array of objects:

| Field      | Type   | Required | Description                                                          |
| ---------- | ------ | -------- | -------------------------------------------------------------------- |
| `content`  | string | yes      | Brief description of the task.                                       |
| `status`   | string | yes      | One of `pending`, `in_progress`, `completed`, `cancelled`.           |
| `priority` | string | yes      | One of `high`, `medium`, `low`.                                      |

Send the full updated list every time — the tool replaces, not patches.

### `webfetch`

Fetch a URL.

| Param     | Type    | Required | Default      | Description                                                  |
| --------- | ------- | -------- | ------------ | ------------------------------------------------------------ |
| `url`     | string  | yes      | —            | URL to fetch.                                                |
| `format`  | enum    | no       | `"markdown"` | One of `"text"`, `"markdown"`, `"html"`.                     |
| `timeout` | number  | no       | —            | Timeout in seconds (max 120).                                |

### `websearch`

Web search via Exa AI. Requires the OpenCode provider or
`OPENCODE_ENABLE_EXA=true`.

| Param                  | Type   | Required | Default      | Description                                                                 |
| ---------------------- | ------ | -------- | ------------ | --------------------------------------------------------------------------- |
| `query`                | string | yes      | —            | Search query.                                                               |
| `numResults`           | number | no       | 8            | Result count.                                                               |
| `livecrawl`            | enum   | no       | `"fallback"` | `"fallback"` (use live as backup) or `"preferred"` (prioritize live).       |
| `type`                 | enum   | no       | `"auto"`     | `"auto"`, `"fast"`, or `"deep"`.                                            |
| `contextMaxCharacters` | number | no       | 10000        | Max chars for the LLM-optimized context string.                             |

### `question`

Ask the user during execution. Use when guessing has a higher cost than asking.

`questions` is an array of `Question.Prompt` objects (header + question text +
options list; supports navigation across multiple).

### `skill`

Load a `SKILL.md` and inject its content into the conversation.

| Param  | Type   | Required | Description                                |
| ------ | ------ | -------- | ------------------------------------------ |
| `name` | string | yes      | Skill name from `available_skills`.        |

### `lsp` (experimental)

Requires `OPENCODE_EXPERIMENTAL_LSP_TOOL=true`. Talks to the project's LSP
server for code intel.

| Param       | Type    | Required | Description                                                                      |
| ----------- | ------- | -------- | -------------------------------------------------------------------------------- |
| `operation` | enum    | yes      | One of the operations listed below.                                              |
| `filePath`  | string  | yes      | Absolute or relative file path.                                                  |
| `line`      | int ≥ 1 | yes      | 1-based line number.                                                             |
| `character` | int ≥ 1 | yes      | 1-based character offset.                                                        |
| `query`     | string  | no       | Required for `workspaceSymbol`. Empty string = all symbols.                      |

Operations: `goToDefinition`, `findReferences`, `hover`, `documentSymbol`,
`workspaceSymbol`, `goToImplementation`, `prepareCallHierarchy`,
`incomingCalls`, `outgoingCalls`.

---

## Agents on this system

Confirmed via `opencode agent list` (this user, v1.15.0):

### Primary agents (user-facing, switchable with Tab / `switch_agent` keybind)

- **`build`** *(default)* — full tool access. Use for actual coding.
- **`plan`** — `edit`/`write`/`apply_patch`/`bash` set to `ask`. Use for
  read-heavy analysis and producing implementation plans without touching the
  tree.

### Subagents (invoke via the `task` tool)

| `subagent_type` | Capabilities                                                                          |
| --------------- | ------------------------------------------------------------------------------------- |
| `explore`       | Read-only codebase exploration. Best for "find/locate/trace" questions.               |
| `general`       | Full tool access except `todowrite`. Open-ended research or multi-step tasks.         |

Multiple `task` calls in one turn run in parallel when the active provider
supports parallel tool calls. **Subagents cannot recursively spawn subagents.**

### System agents (not invokable directly)

`compaction`, `summary`, `title` — opencode uses these internally for context
compression and session naming. Do not invoke.

### Scout

Documented upstream as a read-only subagent for cloning dependency repos into
opencode's managed cache. **Not registered on this system.** Treat as
unavailable unless `opencode agent list` shows it.

---

## MCP servers

`opencode mcp list` → **none configured**. Do not assume any MCP capability
exists. Do not edit `opencode.json` to add MCPs without explicit user request —
the user adds them via `opencode mcp add`.

---

## Plugins

- **`@tarquinen/opencode-dcp@3.1.12`** (Dynamic Context Pruning). Config in
  `~/.config/opencode/dcp.jsonc`. Aggressive: starts nudging at 30K tokens,
  forces compression above 60K (window is 128K). **Implication:** older tool
  results may be summarized or dropped. If a fact matters, re-read the source
  — do not assume the transcript is verbatim.

---

## Effective permissions (`build` agent)

| Permission                                                                         | Action |
| ---------------------------------------------------------------------------------- | ------ |
| `read`, `glob`, `grep`                                                             | allow  |
| `webfetch`, `websearch`                                                            | allow  |
| `question`, `todowrite`, `skill`, `compress`                                       | allow  |
| `external_directory` for `/tmp/opencode/*` and `~/.local/share/opencode/tool-output/*` | allow  |
| `doom_loop` (runaway-loop detection)                                               | ask    |
| `external_directory` (any other path)                                              | ask    |
| `*` (everything else, includes `bash`, `write`, `edit`, `apply_patch`)             | ask    |

**Implication:** every mutation prompts the user. Batch them: announce the
plan in one short paragraph, then execute. Do not chain ten `edit` calls
without a heads-up.

---

## Providers and models

Configured in `opencode.json`:

- **`ollama`** (local, `http://localhost:11434/v1`):
  `gemma4-e4b-128k`, `llama3.1-8b-48k`, `qwen3-4b-80k`. Non-streaming.
- **`llama-server`** (local, `http://localhost:8080/v1`): `128k`, `64k`, `32k`
  — context labels for the currently-loaded GGUF. Non-streaming.

When running a small model (4B–8B):
- Use `read` with `offset`/`limit` for long files instead of full reads.
- Delegate broad search to `explore` rather than reading many files in the
  main context.
- State the plan in plain text before tool calls so the user can correct
  cheaply.

---

## Working style

- **Read before edit.** Always `read` a file before `edit`/`apply_patch`/
  `write`.
- **Surgical edits.** Prefer `edit` over `write` for existing files. Don't
  rewrite a 500-line file to change 3 lines.
- **One concern per turn.** Don't refactor while fixing a bug unless asked.
- **Concise output.** Terminal output. Lead with the result; no preamble, no
  recap, no closing summary unless the task is non-trivial.
- **No emoji** unless the user asks.
- **Respect Guix declarative state.** Packages live in `guix/packages/*.scm`;
  the home env is `guix/home.scm`. Do **not** propose `apt install` or
  `npm i -g` unless the user explicitly says the change is throwaway.
- **State tradeoffs, then stop.** For exploratory questions, give a 2–3 sentence
  recommendation with the main tradeoff; don't implement until the user
  agrees.
- **Verify destructive actions.** Confirm before `rm -rf`, `git push --force`,
  migrations, or anything that touches state outside the working tree.

When unsure, ask one specific question via `question` rather than guessing.
Asking costs one turn; guessing wrong costs a full retry.
