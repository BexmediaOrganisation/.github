# Bexmedia repo setup
# Does the setup in the "Starting a new repo" SOP for you, on a new or an existing repo:
# https://bexmediastudio.monday.com/docs/18439133662
#
# Windows (PowerShell):  irm https://raw.githubusercontent.com/BexmediaOrganisation/.github/main/scripts/setup-repo.ps1 | iex
# Mac (needs PowerShell: brew install powershell):
#   pwsh -c "irm https://raw.githubusercontent.com/BexmediaOrganisation/.github/main/scripts/setup-repo.ps1 | iex"

& {
  try {
    $ErrorActionPreference = 'Stop'
    $Org = 'BexmediaOrganisation'
    $StandardsRepo = "$Org/.github"
    $SopLink = 'https://bexmediastudio.monday.com/docs/18439133662'
    $AppLink = "https://github.com/organizations/$Org/settings/installations"

    function Say($m)  { Write-Host $m }
    function Good($m) { Write-Host "  OK  $m" -ForegroundColor Green }
    function Warn($m) { Write-Host "  !!  $m" -ForegroundColor Yellow }
    $script:Stage = ''
    function Fail($m) {
        Write-Host ''
        Write-Host "  XX  $m" -ForegroundColor Red
        if ($script:Stage) { Write-Host "      Carry on by hand from Step 2A, part $($script:Stage) of the SOP: $SopLink" -ForegroundColor Red }
        throw 'Setup stopped.'
    }

    Say ''
    Say 'Bexmedia repo setup'
    Say "This follows the Starting a new repo SOP: $SopLink"
    Say ''

    # ---- 1. Check the tools ----
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Fail 'Git is not installed. Windows: winget install Git.Git   Mac: xcode-select --install   Then run this again.'
    }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        Fail 'The GitHub CLI is not installed. Windows: winget install GitHub.cli   Mac: brew install gh   Then run this again.'
    }
    gh auth status *> $null
    if ($LASTEXITCODE -ne 0) {
        Say 'You need to log in to GitHub first. A browser window will open.'
        gh auth login --web --scopes 'repo,admin:org'
        if ($LASTEXITCODE -ne 0) { Fail 'GitHub login did not finish. Run this again when you are ready.' }
    }
    Good 'Git and the GitHub CLI are ready'

    # ---- 2. Ask about the repo ----
    Say ''
    Say 'Naming: Bexmedia tools (day-to-day workflow tools) are Bexmedia + name, e.g. BexmediaBexclock.'
    Say '        Everything else is a descriptive PascalCase name, e.g. DarkhorseProjectArchive.'
    $Name = (Read-Host 'Repo name').Trim()
    if (-not $Name) { Fail 'No repo name given.' }

    Say ''
    Say 'What kind of repo is it?'
    Say '  1  Private (almost every repo)'
    Say '  2  Public -Updates repo (the download channel for an app)'
    Say '  3  Public open-source tool (only with Tom''s OK)'
    $Kind = (Read-Host 'Choose 1, 2 or 3 [1]').Trim()
    if (-not $Kind) { $Kind = '1' }
    if ('1', '2', '3' -notcontains $Kind) { Fail 'Please choose 1, 2 or 3.' }

    $NamePattern = '^[A-Z][A-Za-z0-9]*$'
    if ($Kind -eq '2') { $NamePattern = '^[A-Z][A-Za-z0-9]*-Updates$' }
    if ($Name -notmatch $NamePattern) {
        if ($Kind -eq '2') { Warn "$Name doesn't end in -Updates, or isn't PascalCase." } else { Warn "$Name isn't PascalCase (e.g. BexmediaBexclock)." }
        $Ok = Read-Host 'Use this name anyway? (y/n)'
        if ($Ok -ne 'y') { Fail 'Stopped so you can pick a name that follows the SOP.' }
    }
    $Full = "$Org/$Name"

    # ---- Step 2A, part A: create the repo, or use the existing one ----
    $script:Stage = 'A'
    gh repo view $Full --json name *> $null
    $Exists = ($LASTEXITCODE -eq 0)
    if ($Exists) {
        Good "$Full already exists, so it will be brought up to standard"
    } else {
        $CreateArgs = @('repo', 'create', $Full, '--add-readme')
        if ($Kind -eq '1') { $CreateArgs += '--private' } else { $CreateArgs += '--public' }
        if ($Kind -eq '2') {
            $App = $Name -replace '-Updates$', ''
            $CreateArgs += @('--description', "Public release channel for $App. Source code lives in the private $App repo.")
        }
        gh @CreateArgs | Out-Null
        if ($LASTEXITCODE -ne 0) { Fail "Could not create $Full. Check you are a member of the $Org org." }
        Good "Created $Full"
    }

    $Info = gh repo view $Full --json visibility,defaultBranchRef,id | ConvertFrom-Json
    $Branch = $Info.defaultBranchRef.name
    $IsPublic = ($Info.visibility -eq 'PUBLIC')
    if ($Kind -eq '1' -and $IsPublic) { Warn "$Full is public but you chose private. Visibility was left as it is: talk to Tom." }
    if ($Kind -ne '1' -and -not $IsPublic) { Warn "$Full is private but you chose public. Visibility was left as it is: talk to Tom." }
    if ($Branch -ne 'main') { Warn "The main branch is called '$Branch', not 'main'. Talk to Tom about renaming it." }

    # ---- Step 2A, part B: repo settings ----
    $script:Stage = 'B'
    gh api -X PATCH "repos/$Full" -F allow_merge_commit=true -F allow_squash_merge=false -F allow_rebase_merge=false -F delete_branch_on_merge=true -f merge_commit_title=PR_TITLE -f merge_commit_message=BLANK --silent
    if ($LASTEXITCODE -ne 0) { Fail 'Could not change the repo settings. You may need admin rights on this repo.' }
    Good 'Merge commits only, using the PR title, and branches delete themselves after merging'

    # Public repos can lock main on our GitHub plan, so lock it.
    if ($IsPublic) {
        $Rule = Join-Path ([IO.Path]::GetTempPath()) ("bex-protect-" + [guid]::NewGuid() + '.json')
        '{"required_status_checks":null,"enforce_admins":true,"required_pull_request_reviews":{"required_approving_review_count":0},"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}' | Set-Content -Path $Rule -Encoding ascii
        gh api -X PUT "repos/$Full/branches/$Branch/protection" --input $Rule --silent
        $Locked = ($LASTEXITCODE -eq 0)
        Remove-Item $Rule -ErrorAction SilentlyContinue
        if ($Locked) { Good "$Branch is locked: every change needs a pull request" } else { Warn "Could not lock $Branch. Lock it by hand: Step 2A, part B of the SOP." }
    }

    # ---- Step 2A, part C: standard files ----
    $script:Stage = 'C'
    $UsesFiles = ($Kind -ne '2')
    $UsesWorkflows = ($Kind -eq '1')
    if ($Kind -eq '3') { Warn 'Public repo: no workflows added, so pull requests from strangers can never run on our computers.' }

    if ($UsesFiles) {
        $Work = Join-Path ([IO.Path]::GetTempPath()) ("bex-setup-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $Work | Out-Null
        try {
            $Std = Join-Path $Work 'standards'
            $Repo = Join-Path $Work 'repo'
            git clone --quiet --depth 1 "https://github.com/$StandardsRepo.git" $Std
            gh repo clone $Full $Repo -- --quiet
            if ($LASTEXITCODE -ne 0) { Fail "Could not download $Full." }

            $FixBranch = 'chore/bexmedia-standards'
            if ($Exists) { git -C $Repo switch --quiet -c $FixBranch }

            $Tpl = Join-Path $Std 'templates'
            $Files = Get-ChildItem -Path $Tpl -Recurse -File -Force
            foreach ($F in $Files) {
                $Rel = $F.FullName.Substring($Tpl.Length + 1)
                $RelSlash = $Rel -replace '\\', '/'
                if (-not $UsesWorkflows -and ($RelSlash -like '.github/workflows/*' -or $RelSlash -like '*release-please*')) { continue }
                $Dest = Join-Path $Repo $Rel
                $DestDir = Split-Path $Dest -Parent
                if (-not (Test-Path $DestDir)) { New-Item -ItemType Directory -Path $DestDir -Force | Out-Null }

                if (-not (Test-Path $Dest)) {
                    $Text = Get-Content -Path $F.FullName -Raw
                    if ($RelSlash -eq 'CLAUDE.md') { $Text = $Text -replace '\[Repo name\]', $Name }
                    if ($RelSlash -eq '.release-please-manifest.json' -and $Exists) {
                        $LastTag = git -C $Repo describe --tags --abbrev=0 2>$null
                        if ($LASTEXITCODE -eq 0 -and $LastTag -match '^[vV]?(\d+\.\d+\.\d+)$') {
                            $Text = $Text -replace '0\.0\.0', $Matches[1]
                            Good "Releases will carry on from $LastTag"
                        }
                    }
                    Set-Content -Path $Dest -Value $Text -NoNewline
                    Good "Added $RelSlash"
                }
                elseif ($RelSlash -eq 'CLAUDE.md') {
                    $Mine = Get-Content -Path $Dest -Raw
                    if ($Mine -notmatch '## Bexmedia standards') {
                        $Tmpl = Get-Content -Path $F.FullName -Raw
                        $Section = ($Tmpl -split '(?m)^## About this repo')[0] -replace '(?s)^.*?(?=## Bexmedia standards)', ''
                        $Lines = $Mine -split "`r?`n", 2
                        if ($Lines[0] -match '^# ') { $New = $Lines[0] + "`n`n" + $Section.Trim() + "`n`n" + $Lines[1] }
                        else { $New = $Section.Trim() + "`n`n" + $Mine }
                        Set-Content -Path $Dest -Value $New -NoNewline
                        Good 'Added the Bexmedia standards section to the existing CLAUDE.md (your notes are kept)'
                    }
                }
                elseif ($RelSlash -eq '.gitignore') {
                    $Have = Get-Content -Path $Dest
                    $Missing = Get-Content -Path $F.FullName | Where-Object { $_ -and $_ -notmatch '^#' -and $Have -notcontains $_ }
                    if ($Missing) {
                        Add-Content -Path $Dest -Value (@('', '# Added by Bexmedia repo setup') + $Missing)
                        Good 'Added missing lines to the existing .gitignore'
                    }
                }
                else {
                    Warn "$RelSlash already exists, so it was left as it is"
                }
            }

            git -C $Repo add -A
            $Changes = git -C $Repo status --porcelain
            if (-not $Changes) {
                Good 'All the standard files were already there'
            }
            elseif (-not $Exists) {
                git -C $Repo commit --quiet -m 'chore: set up repo'
                git -C $Repo push --quiet origin $Branch
                Good "Standard files committed to $Branch (the one time that's allowed)"
            }
            else {
                git -C $Repo commit --quiet -m 'chore: add bexmedia standards'
                git -C $Repo push --quiet -u origin $FixBranch
                $Pr = gh pr create --repo $Full --base $Branch --head $FixBranch --title 'chore: add bexmedia standards' --body 'Adds the Bexmedia standard files, following the Starting a new repo SOP. Check nothing important was changed, then merge.'
                Good "Opened a pull request with the standard files: $Pr"
            }
        }
        finally {
            Set-Location ([IO.Path]::GetTempPath())
            Remove-Item -Recurse -Force $Work -ErrorAction SilentlyContinue
        }
    }

    # ---- Step 2A, part D: release app ID and key ----
    $script:Stage = 'D'
    if ($UsesWorkflows) {
        $RepoNumber = gh api "repos/$Full" --jq .id
        $SecretOk = $true
        gh api -X PUT "orgs/$Org/actions/secrets/RELEASE_BOT_PRIVATE_KEY/repositories/$RepoNumber" --silent 2>$null
        if ($LASTEXITCODE -ne 0) { $SecretOk = $false }
        gh api -X PUT "orgs/$Org/actions/variables/RELEASE_BOT_APP_ID/repositories/$RepoNumber" --silent 2>$null
        if ($LASTEXITCODE -ne 0) { $SecretOk = $false }
        if ($SecretOk) { Good 'The repo can use the release app''s ID and key' }
        else { Warn 'Could not give the repo the release app''s ID and key. An org owner needs to do Step 2A, part D of the SOP: ask Tom.' }
    }

    # ---- Done ----
    $script:Stage = ''
    Say ''
    Say 'Nearly done. Step 3 of the SOP is the one thing GitHub only lets you do on its website:'
    if ($Kind -ne '3') {
        Say "  Add $Name to Bexmedia Release Bot: $AppLink"
        Say '  (Configure > Repository access > add the repo, and its -Updates repo if it has one.)'
    } else {
        Say '  Nothing else needed for an open-source repo.'
    }
    Say ''
    Say "Repo: https://github.com/$Full"
    Say 'From now on, every change follows the Commits and pull requests SOP.'
    Say ''
  }
  catch {
    if ($_.Exception.Message -ne 'Setup stopped.') {
        Write-Host ''
        Write-Host "  XX  Something went wrong: $($_.Exception.Message)" -ForegroundColor Red
        if ($script:Stage) { Write-Host "      Carry on by hand from Step 2A, part $($script:Stage) of the SOP: https://bexmediastudio.monday.com/docs/18439133662" -ForegroundColor Red }
    }
  }
}
