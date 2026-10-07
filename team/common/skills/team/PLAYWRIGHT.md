# Using Playwright locally

UI checks run in a real browser through Playwright's MCP server. Playwright stays on the machine that runs the check. Nothing from it is added to the product repo.

## Keep it out of the project

- Do not add Playwright as a dependency, and do not add a Playwright config or spec files.
- Do not commit a browser profile, a storage-state file, or cookies.
- Do not commit an MCP config that lives inside the product repo. The server is configured on the person's own machine.
- Screenshots of a walkthrough go in the team's artifact folder for that run (`.dev-team/<slug>/qa/`, or the accept or audit folder named in the skill you are following). Those files are evidence. The profile is not.

## One-time setup

The person running the check adds the server once, outside the project.

**Cursor** — `~/.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

**Claude Code:**

```bash
claude mcp add playwright npx @playwright/mcp@latest
```

The first run downloads Playwright's own browser into the user cache (`~/Library/Caches/ms-playwright` on macOS, `~/.cache/ms-playwright` on Linux, `%USERPROFILE%\AppData\Local\ms-playwright` on Windows). A Chrome or Chromium install on the system is not required. The download needs network once.

If the Playwright tools are not available in this session, record the UI flows under **Not verified** and say the server is not configured. Do not install Playwright into the project to get past that.

## A logged-in user

The default is a persistent profile, one per workspace, in that same cache (`mcp-{channel}-{workspace-hash}`). The browser opens headed.

When a flow needs a signed-in user and the page is a login wall, ask the user to log in once in that window, then continue. Later runs on this machine reuse that login. Each person has their own profile; do not copy it to another machine or into the repo.

That profile is Playwright's browser. A login in the user's everyday Chrome is not visible to it. To drive a tab they are already signed into, they connect the Playwright browser extension. Do not copy their Chrome profile into the repo.

Leave isolated mode off. It drops the login when the browser closes. Do not pass a storage-state path inside the repo. That file is cookies.

One profile can only be used by one browser at a time. Do not open a second Playwright browser against the same workspace profile.

## Walk a screen

1. Start the dev server from `PROJECT.md` if it is not already running. In a worktree, use a free port.
2. Open the flow's URL with the Playwright browser tools.
3. Read the accessibility snapshot. Click, type, and navigate by role and accessible name, the way a user would.
4. Walk each user flow, including the failure paths (empty, error, disabled).
5. Read the console and note errors.
6. Check the screen at desktop width, then resize to about 360px wide and check again. Look for horizontal scrolling and overlapping content.
7. Save a screenshot of each key state into the artifact folder for this run.
8. Anything you could not open goes under **Not verified**, with the reason.

## What this does not replace

Write and run the project's own component and interaction tests. Playwright is the browser walkthrough. It is not a test suite checked into the app.
