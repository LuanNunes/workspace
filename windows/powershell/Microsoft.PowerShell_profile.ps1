# ============================================================
#  PowerShell Profile — nunes
#  Editar:  pro     |  Recarregar:  reload
# ============================================================

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:LANG = 'pt_BR.UTF-8'

# ------------------------------------------------------------
#  Prompt (oh-my-posh)
# ------------------------------------------------------------
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $theme = "$env:USERPROFILE\.config\oh-my-posh\theme.omp.json"
    if (-not (Test-Path $theme)) {
        $theme = "$env:POSH_THEMES_PATH\powerlevel10k_rainbow.omp.json"
    }
    oh-my-posh init pwsh --config $theme | Invoke-Expression
}

# ------------------------------------------------------------
#  Módulos
# ------------------------------------------------------------
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module posh-git       -ErrorAction SilentlyContinue
Import-Module CompletionPredictor -ErrorAction SilentlyContinue

# ------------------------------------------------------------
#  PSReadLine — histórico inteligente, cores, edição
# ------------------------------------------------------------
Import-Module PSReadLine

Set-PSReadLineOption -EditMode Windows
# Só habilita predição quando o console é interativo (evita erro com saída redirecionada)
if (-not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
}
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -HistoryNoDuplicates
Set-PSReadLineOption -MaximumHistoryCount 20000
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -ShowToolTips
# Paleta Kanagawa — o WSL fica no Tokyo Night, então dá pra saber num relance
# em qual shell você está.
Set-PSReadLineOption -Colors @{
    Command                = '#7e9cd8'
    Parameter              = '#957fb8'
    Operator               = '#c0a36e'
    Variable               = '#e6c384'
    String                 = '#98bb6c'
    Number                 = '#ffa066'
    Type                   = '#7aa89f'
    Member                 = '#7fb4ca'
    Comment                = '#727169'
    Keyword                = '#957fb8'
    Error                  = '#e82424'
    ContinuationPrompt     = '#727169'
    Default                = '#dcd7ba'
    Emphasis               = '#ffa066'
    Selection              = "`e[48;2;45;79;103m"
    InlinePrediction       = '#54546d'
    ListPrediction         = '#7fb4ca'
    ListPredictionSelected = "`e[48;2;45;79;103m"
}

# ↑/↓ buscam no histórico pelo que já foi digitado
Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
# → aceita a sugestão inline
Set-PSReadLineKeyHandler -Key RightArrow -Function ForwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function AcceptSuggestion
# Ctrl+D sai, Ctrl+W apaga palavra, Alt+D apaga palavra à frente
Set-PSReadLineKeyHandler -Key Ctrl+w -Function BackwardKillWord
Set-PSReadLineKeyHandler -Key Alt+d  -Function KillWord
# Ctrl+Shift+C / V
Set-PSReadLineKeyHandler -Key Ctrl+Shift+c -Function Copy
Set-PSReadLineKeyHandler -Key Ctrl+Shift+v -Function Paste
# Parênteses/aspas automáticos
Set-PSReadLineKeyHandler -Key '"' -BriefDescription SmartQuote -ScriptBlock {
    param($key)
    $line = $null; $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($line[$cursor] -eq '"') {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert('""')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
}

# ------------------------------------------------------------
#  fzf — Ctrl+T arquivos, Ctrl+R histórico, Alt+C pastas
# ------------------------------------------------------------
if (Get-Module -ListAvailable PSFzf) {
    Import-Module PSFzf -ErrorAction SilentlyContinue
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    $env:FZF_DEFAULT_OPTS = @(
        '--height=60%'
        '--layout=reverse'
        '--border=rounded'
        '--info=inline'
        '--pointer=▶'
        '--marker=✓'
        '--color=fg:#dcd7ba,bg:-1,hl:#7e9cd8'
        '--color=fg+:#dcd7ba,bg+:#2d4f67,hl+:#7fb4ca'
        '--color=info:#98bb6c,prompt:#957fb8,pointer:#e82424'
        '--color=marker:#98bb6c,spinner:#e6c384,header:#727169'
        '--color=border:#54546d'
    ) -join ' '
}

# ------------------------------------------------------------
#  zoxide — `z projetos` pula pra pasta mais usada
# ------------------------------------------------------------
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd z | Out-String) })
}

# ------------------------------------------------------------
#  bat — pager colorido
# ------------------------------------------------------------
if (Get-Command bat -ErrorAction SilentlyContinue) {
    # bat não traz um tema Kanagawa. 'ansi' usa as 16 cores do terminal, ou
    # seja, segue o esquema do perfil automaticamente — se o esquema mudar, o
    # bat acompanha sem precisar editar nada aqui.
    $env:BAT_THEME = 'ansi'
    Set-Alias -Name cat -Value bat -Option AllScope -Force
    function less { $input | bat --paging=always }
}

# ------------------------------------------------------------
#  eza — listagens bonitas
# ------------------------------------------------------------
if (Get-Command eza -ErrorAction SilentlyContinue) {
    Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue
    function ls  { eza --icons --group-directories-first @args }
    function l   { eza --icons --group-directories-first -lh --git @args }
    function ll  { eza --icons --group-directories-first -lah --git @args }
    function lt  { eza --icons --group-directories-first --tree --level=2 @args }
    function lt3 { eza --icons --group-directories-first --tree --level=3 @args }
}

# ------------------------------------------------------------
#  Neovim — mesma config do WSL (windows/sync.sh cuida da cópia)
# ------------------------------------------------------------
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    $env:EDITOR = 'nvim'
    $env:VISUAL = 'nvim'
    function vim { nvim @args }
    function vi  { nvim @args }
    function v   { nvim @args }
}

# ------------------------------------------------------------
#  Git — atalhos
# ------------------------------------------------------------
function gs  { git status --short --branch @args }
function ga  { git add @args }
function gaa { git add --all }
function gc  { git commit -m @args }
function gca { git commit --amend --no-edit }
function gp  { git push @args }
function gpl { git pull --rebase @args }
function gco { git checkout @args }
function gb  { git branch @args }
function gd  { git diff @args }
function gds { git diff --staged @args }
function glog {
    git log --graph --abbrev-commit --decorate --all `
        --format=format:'%C(bold blue)%h%C(reset) %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)— %an%C(reset)%C(bold yellow)%d%C(reset)'
}
# Branch fuzzy: escolhe branch com fzf
function gcof {
    $b = git branch --all --format='%(refname:short)' | fzf --prompt='branch ▶ '
    if ($b) { git checkout ($b -replace '^origin/', '') }
}

# ------------------------------------------------------------
#  Navegação e utilidades
# ------------------------------------------------------------
function ..    { Set-Location .. }
function ...   { Set-Location ../.. }
function ....  { Set-Location ../../.. }
function ~     { Set-Location $HOME }
function proj  { Set-Location "$HOME\projects" }
function dl    { Set-Location "$HOME\Downloads" }

function which($cmd) { (Get-Command $cmd -ErrorAction SilentlyContinue).Source }
function touch($f) { if (Test-Path $f) { (Get-Item $f).LastWriteTime = Get-Date } else { New-Item -ItemType File $f | Out-Null } }
function mkcd($d) { New-Item -ItemType Directory -Force $d | Out-Null; Set-Location $d }
function rmrf($p) { Remove-Item -Recurse -Force $p }
function pro    { if (Get-Command nvim -EA SilentlyContinue) { nvim $PROFILE } else { code $PROFILE } }
function reload { . $PROFILE; Write-Host '✓ profile recarregado' -ForegroundColor Green }

# Busca de conteúdo com preview
function ff {
    param([string]$Pattern)
    if (Get-Command rg -ErrorAction SilentlyContinue) { rg --hidden --glob '!.git' $Pattern }
    else { Get-ChildItem -Recurse -File | Select-String $Pattern }
}

# Abre a pasta atual no explorer
function e { explorer.exe (Get-Location).Path }

# Qual processo está usando a porta
function port($n) {
    Get-NetTCPConnection -LocalPort $n -ErrorAction SilentlyContinue |
        Select-Object LocalAddress, LocalPort, State,
            @{n='Process'; e={ (Get-Process -Id $_.OwningProcess -EA SilentlyContinue).ProcessName }},
            OwningProcess
}

# Mata processo por nome
function killp($name) { Get-Process $name -EA SilentlyContinue | Stop-Process -Force }

# Peso das pastas do diretório atual
function du {
    Get-ChildItem -Directory | ForEach-Object {
        $size = (Get-ChildItem $_.FullName -Recurse -File -EA SilentlyContinue |
                 Measure-Object Length -Sum).Sum
        [PSCustomObject]@{ Pasta = $_.Name; MB = [math]::Round($size / 1MB, 1) }
    } | Sort-Object MB -Descending
}

# IP público
function myip { (Invoke-RestMethod 'https://api.ipify.org?format=json').ip }

# Cronometra um bloco
function timeit { param([scriptblock]$s) (Measure-Command $s).TotalSeconds }

# ------------------------------------------------------------
#  Completions
# ------------------------------------------------------------
Set-PSReadLineOption -CompletionQueryItems 100
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

if (Get-Command winget -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.Utf8Encoding]::new()
        winget complete --word "$wordToComplete" --commandline "$commandAst" --position $cursorPosition |
            ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
    }
}

if (Get-Command dotnet -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        dotnet complete --position $cursorPosition "$commandAst" |
            ForEach-Object { [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_) }
    }
}

# ------------------------------------------------------------
#  Boas-vindas
# ------------------------------------------------------------
if ($Host.Name -eq 'ConsoleHost' -and -not $env:CLAUDECODE) {
    if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
        fastfetch --logo-type small
    }
}
