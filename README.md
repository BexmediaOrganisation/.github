# Bexmedia GitHub standards

This repo is the signpost for how Bexmedia builds software. Every repo in the BexmediaOrganisation org points here, and this repo points to the SOPs on monday.com.

The SOPs are the single source of truth. This repo holds no rules of its own, only links to them and the ready-made files they ask you to use.

## The journey

Most work follows [From idea to release](https://bexmediastudio.monday.com/docs/18439308736): plan, then tickets, then build, then pull request, then merge, then release, then check it's out. It gives the order, and points to the SOP below that explains each step.

## The SOPs

| When you are… | Follow |
|---|---|
| Starting a new repo | [Starting a new repo](https://bexmediastudio.monday.com/docs/18439133662) |
| Changing code: branches, commits, pull requests | [Commits and pull requests](https://bexmediastudio.monday.com/docs/18438793528) |
| Releasing a new version | [Versioning and releases](https://bexmediastudio.monday.com/docs/18438794583) |
| Building with AI in Claude Code | [Building with AI](https://bexmediastudio.monday.com/docs/18439287632) |
| Listing a tool in the App Store, or reporting a problem with one | [Adding an app to the Bexmedia App Store](https://bexmediastudio.monday.com/docs/18439313835) |
| Writing an SOP, or building a skill or tool from one | [The SOP lifecycle](https://bexmediastudio.monday.com/docs/18439474792) |
| Setting up where a build runs | [GitHub self-hosted runners](https://bexmediastudio.monday.com/docs/18438628008) |

The SOPs live on Bexmedia's monday.com, so you need a Bexmedia login to read them.

## Set up a repo in one go

The setup script does the Starting a new repo SOP for you, on a new repo or an existing one. It asks for the repo's name and type, then sets everything up. Existing repos get a pull request to check, so nothing changes without you seeing it.

**Windows** (open PowerShell and paste):

```powershell
irm https://raw.githubusercontent.com/BexmediaOrganisation/.github/main/scripts/setup-repo.ps1 | iex
```

**Mac** (open Terminal and paste):

```bash
curl -fsSL https://raw.githubusercontent.com/BexmediaOrganisation/.github/main/scripts/setup-repo.sh | bash
```

On Windows you need Git and the GitHub CLI (`winget install GitHub.cli`); the script tells you if either is missing. On a Mac, the launcher offers to install PowerShell and the GitHub CLI for you with Homebrew, then runs the same setup script. Either way, it logs you in to GitHub if needed.

## What's in here

- `CLAUDE.md` and `AGENTS.md`: the instructions AI coding tools read.
- `templates/`: the standard files copied into every new repo (see Starting a new repo, Step 4).
- `scripts/setup-repo.ps1`: the setup script above. `scripts/setup-repo.sh` is the Mac launcher for it.
- `CONTRIBUTING.md`, `pull_request_template.md` and `ISSUE_TEMPLATE/`: defaults GitHub shows in every org repo that doesn't have its own.

## Keep this repo public and clean

GitHub only applies the defaults above if this repo is public. Never put passwords, keys, hostnames, IP addresses or client names here.
