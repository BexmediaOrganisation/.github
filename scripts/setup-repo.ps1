# Bexmedia repo setup
# Does the setup in the "Starting a new repo" SOP for you, on a new or an existing repo:
# https://bexmediastudio.monday.com/docs/18439133662
#
# Windows (PowerShell):  irm https://raw.githubusercontent.com/BexmediaOrganisation/.github/main/scripts/setup-repo.ps1 | iex
# Mac (Terminal): curl -fsSL https://raw.githubusercontent.com/BexmediaOrganisation/.github/main/scripts/setup-repo.sh | bash
#   (setup-repo.sh installs PowerShell and the GitHub CLI if needed, then runs this script)

& {
  try {
    $ErrorActionPreference = 'Stop'
    $Org = 'BexmediaOrganisation'
    $StandardsRepo = "$Org/.github"
    $SopLink = 'https://bexmediastudio.monday.com/docs/18439133662'
    $AppLink = "https://github.com/organizations/$Org/settings/installations"
    $LastPassNote = 'Bexmedia Release Bot'
    $ReleaseBotAppId = '5694548'   # Bexmedia Release Bot's App ID (not secret)

    # Run a command whose error output we don't care about. Windows PowerShell 5.1
    # treats any error output from git or gh as fatal, so switch that off just here.
    function Quietly([scriptblock]$Cmd) {
        $Old = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try { & $Cmd 2>&1 | Out-Null } catch { } finally { $ErrorActionPreference = $Old }
    }
    # Read and write text as UTF-8 without a BOM, the same on every PowerShell version.
    function Read-Text($Path) { [IO.File]::ReadAllText($Path) }
    function Write-Text($Path, $Text) { [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding $false)) }

    # Turn hidden (secure) input back into text, on every PowerShell version.
    function Plain($Secure) {
        if (-not $Secure) { return '' }
        $Ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Secure)
        try { [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr) }
    }

    function Say($m)  { Write-Host $m }
    function Good($m) { Write-Host "  OK  $m" -ForegroundColor Green }
    function Warn($m) { Write-Host "  !!  $m" -ForegroundColor Yellow }
    $script:Stage = ''
    $script:NoVersions = $false
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
    Quietly { gh auth status }
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
    if ($Name -eq '.github') { Fail 'This script is not for the .github standards repo. Change .github by hand, through a pull request.' }

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
    Quietly { gh repo view $Full --json name }
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
    # Squash merging only: each pull request lands on main as one commit named after its
    # PR title, with an empty body, so release-please reads only the checked PR titles.
    $script:Stage = 'B'
    gh api -X PATCH "repos/$Full" -F allow_merge_commit=false -F allow_squash_merge=true -F allow_rebase_merge=false -F delete_branch_on_merge=true -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=BLANK --silent
    if ($LASTEXITCODE -ne 0) { Fail 'Could not change the repo settings. You may need admin rights on this repo.' }
    Good 'Squash merging only, using the PR title, and branches delete themselves after merging'

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
                    $Text = Read-Text $F.FullName
                    if ($RelSlash -eq 'CLAUDE.md') { $Text = $Text -replace '\[Repo name\]', $Name }
                    if ($RelSlash -eq '.release-please-manifest.json' -and $Exists) {
                        $LastTag = git -C $Repo tag --list --sort=-v:refname | Select-Object -First 1
                        if ($LastTag -and $LastTag -match '^[vV]?(\d+\.\d+\.\d+)$') {
                            $Text = $Text -replace '0\.0\.0', $Matches[1]
                            Good "Releases will carry on from $LastTag"
                        } else {
                            $script:NoVersions = $true
                        }
                    }
                    Write-Text $Dest $Text
                    Good "Added $RelSlash"
                }
                elseif ($RelSlash -eq 'CLAUDE.md') {
                    $Mine = Read-Text $Dest
                    if ($Mine -notmatch '## Bexmedia standards') {
                        $Tmpl = Read-Text $F.FullName
                        $Section = ($Tmpl -split '(?m)^## About this repo')[0] -replace '(?s)^.*?(?=## Bexmedia standards)', ''
                        $Lines = $Mine -split "`r?`n", 2
                        if ($Lines[0] -match '^# ') { $New = $Lines[0] + "`n`n" + $Section.Trim() + "`n`n" + $Lines[1] }
                        else { $New = $Section.Trim() + "`n`n" + $Mine }
                        Write-Text $Dest $New
                        Good 'Added the Bexmedia standards section to the existing CLAUDE.md (your notes are kept)'
                    }
                }
                elseif ($RelSlash -eq '.gitignore') {
                    $MineText = Read-Text $Dest
                    $Have = $MineText -split "`r?`n"
                    $Missing = (Read-Text $F.FullName) -split "`r?`n" | Where-Object { $_ -and $_ -notmatch '^#' -and $Have -notcontains $_ }
                    if ($Missing) {
                        Write-Text $Dest ($MineText.TrimEnd() + "`n`n# Added by Bexmedia repo setup`n" + ($Missing -join "`n") + "`n")
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
                if ($LASTEXITCODE -ne 0) { Fail "Could not push the standard files to $Branch." }
                Good "Standard files committed to $Branch (the one time that's allowed)"
            }
            else {
                git -C $Repo commit --quiet -m 'chore: add bexmedia standards'
                # The branch belongs to this script, so if an earlier run left one, replace it.
                git -C $Repo push --quiet --force -u origin $FixBranch
                if ($LASTEXITCODE -ne 0) { Fail "Could not push the branch $FixBranch." }
                $Pr = gh pr list --repo $Full --head $FixBranch --state open --json url --jq '.[0].url'
                if ($Pr) {
                    Good "Updated the pull request that was already open: $Pr"
                } else {
                    $Pr = gh pr create --repo $Full --base $Branch --head $FixBranch --title 'chore: add bexmedia standards' --body 'Adds the Bexmedia standard files, following the Starting a new repo SOP. Check nothing important was changed, then merge.'
                    if ($LASTEXITCODE -ne 0 -or -not $Pr) { Fail 'Pushed the branch, but could not open the pull request.' }
                    Good "Opened a pull request with the standard files: $Pr"
                }
            }
        }
        finally {
            Remove-Item -Recurse -Force $Work -ErrorAction SilentlyContinue
        }
    }

    # Existing repos: point out anything the SOPs need tidying.
    if ($Exists -and $UsesWorkflows) {
        $Open = gh pr list --repo $Full --state open --json number,title | ConvertFrom-Json
        $Bad = @($Open | Where-Object { $_.title -notmatch '^(feat|fix|docs|chore|ci|refactor|test)(\([^)]+\))?!?: ' })
        if ($Bad.Count -gt 0) {
            Warn 'These open pull requests need their titles changing to the type: what changed format before merging, or they will not count towards a release:'
            foreach ($P in $Bad) { Say "        #$($P.number)  $($P.title)" }
        }
        if ($script:NoVersions) {
            Warn 'This repo has no versions yet. To start at 1.0.0, see "Starting versions on an existing repo" in the Versioning and releases SOP.'
        }
    }

    # ---- Step 2A, part D: release app ID and key ----
    $script:Stage = 'D'
    if ($UsesWorkflows) {
        Say ''
        Say "Last part: give the repo Bexmedia Release Bot's key. It's in LastPass, in the secure note '$LastPassNote'."
        Say 'Only people with access to that note can do this.'
        Say ''
        Say '  1  In LastPass, copy the whole private key (including the BEGIN and END lines).'
        Say '  2  Come back to this window and just press Enter. DON''T paste it here.'
        Say '     (To skip this part, press Enter without copying anything.)'
        Say ''
        # Hidden input, so if someone pastes the key anyway, none of it shows on screen.
        $First = Plain (Read-Host 'Press Enter when the key is copied' -AsSecureString)
        if ($First -match 'BEGIN') {
            Warn 'Looks like the key was pasted. Catching the rest of it, so none of it shows on screen or runs as commands...'
            $Line = $First
            while ($Line -and $Line -notmatch 'END [A-Z ]*PRIVATE KEY') { $Line = Plain (Read-Host -AsSecureString) }
            Good 'Caught it. Nothing was shown or saved. The copy on your clipboard will be used.'
        }
        $Key = ''
        try { $Key = (Get-Clipboard -Raw) } catch { $Key = '' }
        if ($Key -and $Key.Trim() -match '^-----BEGIN [A-Z ]*PRIVATE KEY-----' -and $Key.Trim() -match '-----END [A-Z ]*PRIVATE KEY-----$') {
            $Key.Trim() | gh secret set RELEASE_BOT_PRIVATE_KEY --repo $Full
            $KeyOk = ($LASTEXITCODE -eq 0)
            try { Set-Clipboard -Value ' ' } catch { }
            if (-not $KeyOk) { Fail 'Could not save the key into the repo. You may need admin rights on this repo.' }
            Good 'Key saved into the repo, and your clipboard has been cleared'

            $AppId = $ReleaseBotAppId
            if (-not $AppId) { $AppId = (Read-Host "Now the App ID (a number, in the same LastPass note)").Trim() }
            if ($AppId -notmatch '^\d+$') { Fail 'The App ID should be a number.' }
            gh variable set RELEASE_BOT_APP_ID --repo $Full --body $AppId
            if ($LASTEXITCODE -ne 0) { Fail 'Could not save the App ID into the repo.' }
            Good 'App ID saved into the repo'
        }
        else {
            try { if ($Key) { Set-Clipboard -Value ' ' } } catch { }
            Warn "Skipped: no private key on the clipboard. Releases won't work until someone with the LastPass note does Step 2A, part D."
        }
    }

    # ---- Done ----
    $script:Stage = ''
    Say ''
    Say 'Nearly done. Step 3 of the SOP is the one thing GitHub only lets you do on its website:'
    if ($Kind -ne '3') {
        Say "  If it isn't there already, add $Name to Bexmedia Release Bot: $AppLink"
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
