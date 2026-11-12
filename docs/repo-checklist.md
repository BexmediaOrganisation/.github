# Bexmedia repo checklist

Use this to check an existing repo against the current Bexmedia standards. The steps around it are in the SOP [Bringing an existing repo up to date](https://bexmediastudio.monday.com/docs/18439746339).

Each item names the SOP it comes from. If an item and its SOP disagree, the SOP wins: follow the SOP, and tell the person you are working with that this checklist needs updating.

## How to run it

1. Read each SOP named below (see [CLAUDE.md](../CLAUDE.md) for how).
2. Check every item, and report each one as **pass**, **fail** or **not applicable**, with a short reason for anything that isn't a pass.
3. Fix the failures you can on one branch named `chore/bexmedia-standards`, in one pull request titled `chore: bring repo up to bexmedia standards`, following Commits and pull requests.
4. End the report with a list of what only a person can do.

Never change repo settings, secrets or variables yourself, and never commit straight to main. Never invent a change to a doc you can't check against the code: ask instead.

## Settings

From [Starting a new repo](https://bexmediastudio.monday.com/docs/18439133662), Step 2A part B.

- [ ] Squash merging only, with its default message set to the pull request title.
- [ ] Merge commits and rebase merging switched off.
- [ ] Head branches delete themselves after merging.
- [ ] Public repos only: main is protected and needs a pull request.

If any of these fail, the fix is to re-run the setup script (Starting a new repo, Step 2). Report it for a person to do.

## Standard files

From [Starting a new repo](https://bexmediastudio.monday.com/docs/18439133662), Step 2A part C. The templates are in this repo's `templates` folder.

- [ ] `CLAUDE.md` has the *Bexmedia standards* section at the top, and `AGENTS.md` points to it.
- [ ] `.gitignore` includes every line of the template's `.gitignore`.
- [ ] `release-please-config.json` and `.release-please-manifest.json` exist, and the manifest's version matches the repo's latest version tag.
- [ ] The PR title check, Release and main guard workflows are in `.github/workflows`, and the Release workflow has the notify job.
- [ ] If the repo has its own pull request template, it has the *What changes for the team* section.

Public repos leave out the workflows and the release-please files.

## Releases

From [Versioning and releases](https://bexmediastudio.monday.com/docs/18438794583), Step 1.

- [ ] The repo variable `RELEASE_BOT_APP_ID` and the secret `RELEASE_BOT_PRIVATE_KEY` exist. Check only that they are there, never their values.
- [ ] Web apps only: a dev site and a live site are set up (Step 1B), and the app shows its version number.

## Matt Pocock's skills

From [Building with AI](https://bexmediastudio.monday.com/docs/18439287632), Step 2.

- [ ] `docs/agents/issue-tracker.md` exists.
- [ ] The glossary is `GLOSSARY.md` (or `GLOSSARY-MAP.md`), not `CONTEXT.md` (or `CONTEXT-MAP.md`), and `docs/agents/domain.md` names `GLOSSARY.md`.

## Pull requests and branches

From [Commits and pull requests](https://bexmediastudio.monday.com/docs/18438793528).

- [ ] Every open pull request's title uses the `type: what changed` format.
- [ ] List any branches whose work isn't in main. Don't delete them: report them.

## Docs

From [Versioning and releases](https://bexmediastudio.monday.com/docs/18438794583), Step 2.

- [ ] `README.md`, `GLOSSARY.md`, `docs/adr/`, `CLAUDE.md`, `AGENTS.md`, `docs/agents/` and any other `.md` file still match the code. ADRs replaced by a later decision are marked superseded.
- [ ] `CHANGELOG.md` is left to release-please from now on. If the repo has a hand-written changelog, report it and ask what to do.

## App Store

From [Starting a new repo](https://bexmediastudio.monday.com/docs/18439133662), Step 4.

- [ ] If the repo is for a tool, the tool's App Store row links to the repo.
