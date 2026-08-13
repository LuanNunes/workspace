# 🍎 macOS Cheat-Sheet (transição Windows + WSL → MacBook Pro)

Primeira máquina Apple. Mesma regra do Vim e do shell: **uma coisa nova por
semana**, não todas hoje. O plano de 4 semanas está no fim.

---

## 0. Antes de instalar qualquer coisa

Máquina própria, controle próprio — nada de MDM. A ordem que faz sentido é:
**Software Update → Apple Account → FileVault → Time Machine**, e só então o
ambiente de dev.

FileVault primeiro porque ativar com o disco ainda vazio é instantâneo; depois de
500 GB de projetos, a cifragem inicial leva horas rodando em segundo plano.

> Quer entender o que cada passo do setup faz antes de rodar?
> **[`macos-setup-passo-a-passo.md`](macos-setup-passo-a-passo.md)** — conceitos do
> sistema, e cada passo com "o que muda / como verificar / como desfazer".

### O que trazer da máquina antiga (nada disso o Homebrew reinstala)

| Origem (WSL) | Destino (Mac) | Por quê |
|---|---|---|
| `~/.ssh/nunes@domo{,.pub}` | `~/.ssh/` | chave de trabalho, registrada na Domo — **nunca** regere |
| `~/.ssh/nunes.lfa{,.pub}` | `~/.ssh/` | chave pessoal (GitHub `github-luan`) |
| `~/.zshrc.secrets` | `~/.zshrc.secrets` | `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` |
| `~/.gnupg/` | `~/.gnupg/` | chaves GPG (perdê-las = perder assinaturas antigas) |
| `~/.kube/config` | `~/.kube/config` | contextos de cluster |
| `~/.aws/{config,credentials}` | `~/.aws/` | acesso ao EKS que o `tug` usa |
| `~/.m2/settings.xml` | `~/.m2/` | repositórios/credenciais Maven internos |
| `~/.gradle/gradle.properties` | `~/.gradle/` | idem para Gradle |
| `~/.npmrc`, `~/.nuget/NuGet/NuGet.Config` | idem | registries privados |
| chave de sync do `atuin` | — | `atuin key` na máquina antiga, guarde antes |
| `~/projects/` | `~/projects/` | ou só re-clone tudo, se estiver tudo pushado |

```sh
# da máquina antiga, com o Mac já na rede:
scp ~/.ssh/nunes@domo ~/.ssh/nunes@domo.pub ~/.ssh/nunes.lfa ~/.ssh/nunes.lfa.pub \
    ~/.zshrc.secrets <mac>:~/
```

Depois: `chmod 600` nas chaves e `ssh-add --apple-use-keychain ~/.ssh/nunes@domo`.

> Existe um **Windows Migration Assistant** oficial, mas para máquina de dev ele
> traz lixo e nenhum dos arquivos acima. Use a lista.

---

## 1. As três ideias que destravam tudo

### ① Cmd é o novo Ctrl — e isso é um presente

No Windows, `Ctrl+C` é *copiar* **e** *matar processo*. Esse conflito é a razão de
o terminal do Windows ter atalhos esquisitos. No Mac:

```
   Cmd+C  → copiar          (nível de aplicação)
   Ctrl+C → SIGINT          (nível de terminal)
```

São teclas **diferentes**. O Vim e o zsh recuperam o `Ctrl` inteiro: `Ctrl+R`
(atuin), `Ctrl+T` (fzf), `Ctrl+W`, `Ctrl+A/E` — todos livres, sem conflito.

### ② App ≠ janela

A maior pegadinha para quem vem do Windows:

| Você quer | Windows | macOS |
|---|---|---|
| fechar a **janela** | `Alt+F4` | `Cmd+W` — **o app continua rodando** |
| fechar o **app** | `Alt+F4` | `Cmd+Q` |
| trocar de **app** | `Alt+Tab` | `Cmd+Tab` |
| trocar de **janela do mesmo app** | `Alt+Tab` | `` Cmd+` `` |

A barra de menu no topo pertence ao **app em foco**, não à janela. Por isso ela
muda quando você troca de app.

> Instalamos o **AltTab** justamente porque `Cmd+Tab` por app é irritante no
> começo. Configure o hotkey dele para `Cmd+Tab` e você tem o comportamento do
> Windows de volta. Deixe `Alt+Tab` livre — o AeroSpace usa.

### ③ Por baixo é BSD, não Linux

Os utilitários são os do BSD, com flags diferentes:

```sh
sed -i 's/a/b/' f     # ✅ Linux    ❌ macOS (pede sufixo de backup)
sed -i '' 's/a/b/' f  # ✅ macOS
ls --color            # ❌ macOS
date -d '1 day ago'   # ❌ macOS
```

Por isso o `Brewfile` instala `coreutils`, `gnu-sed`, `gawk`, `grep` — que viram
`gls`, `gsed`, `gawk`, `ggrep`. Eles **não** entram na frente do PATH de
propósito: script que assume BSD quebraria. Chame com o `g` na frente quando
precisar do comportamento Linux.

---

## 2. Tabela de conversão de atalhos

| Ação | Windows | macOS |
|---|---|---|
| Copiar / colar / recortar | `Ctrl+C/V/X` | `Cmd+C/V/X` |
| Colar **movendo** arquivo | `Ctrl+X` → `Ctrl+V` | `Cmd+C` → `Cmd+Option+V` |
| Desfazer / refazer | `Ctrl+Z` / `Ctrl+Y` | `Cmd+Z` / `Cmd+Shift+Z` |
| Salvar / abrir / imprimir | `Ctrl+S/O/P` | `Cmd+S/O/P` |
| Selecionar tudo | `Ctrl+A` | `Cmd+A` |
| Localizar / próximo | `Ctrl+F` / `F3` | `Cmd+F` / `Cmd+G` |
| Nova aba / fechar aba | `Ctrl+T` / `Ctrl+W` | `Cmd+T` / `Cmd+W` |
| Reabrir aba fechada | `Ctrl+Shift+T` | `Cmd+Shift+T` |
| **Início / fim da linha** | `Home` / `End` | `Cmd+←` / `Cmd+→` |
| **Início / fim do documento** | `Ctrl+Home/End` | `Cmd+↑` / `Cmd+↓` |
| Palavra a palavra | `Ctrl+←/→` | `Option+←/→` |
| **Delete para frente** | `Delete` | `Fn+Delete` |
| Renomear arquivo | `F2` | `Enter` (!) |
| Abrir arquivo | `Enter` | `Cmd+↓` ou `Cmd+O` |
| Propriedades / info | `Alt+Enter` | `Cmd+I` |
| Deletar arquivo | `Delete` | `Cmd+Delete` |
| Gerenciador de tarefas | `Ctrl+Shift+Esc` | `Cmd+Option+Esc` (Force Quit) |
| Bloquear tela | `Win+L` | `Ctrl+Cmd+Q` |
| Launcher | `Win` / Flow Launcher | `Cmd+Space` (Raycast) |
| Histórico de clipboard | Ditto | `Cmd+Shift+V` (Maccy) |
| Print screen (área) | `Win+Shift+S` | `Cmd+Shift+4` |
| Print screen (tela) | `PrtScr` | `Cmd+Shift+3` |
| Gravar tela / opções | Xbox Game Bar | `Cmd+Shift+5` |
| Emoji | `Win+.` | `Fn+E` ou `Ctrl+Cmd+Space` |
| Minimizar / ocultar app | `Win+D` | `Cmd+M` / `Cmd+H` |
| Espaço/desktop ao lado | `Ctrl+Win+←/→` | `Ctrl+←/→` |
| Mission Control | `Win+Tab` | `Ctrl+↑` (ou 3 dedos p/ cima) |
| Forçar reload sem cache | `Ctrl+F5` | `Cmd+Shift+R` |

**Dentro do Ghostty/Neovim/zsh, `Ctrl` continua sendo `Ctrl`.** Nada acima
atrapalha seu muscle memory de Vim.

---

## 3. Teclado

### Acentos em português

Configuramos o Ghostty com `macos-option-as-alt = left`. Isso significa:

- **Option esquerdo** = `Alt` de verdade → `Alt+C` do fzf, `Alt+B/F` do readline.
- **Option direito** = tecla morta de composição → acentos:

| Você quer | Digite |
|---|---|
| á é í ó ú | `⌥e` depois a vogal |
| ã õ ñ | `⌥n` depois a vogal |
| â ê ô | `⌥i` depois a vogal |
| ç | `⌥c` |
| à | `⌥\`` depois `a` |
| ü | `⌥u` depois `u` |

Se preferir teclado dedicado, System Settings → Keyboard → Input Sources →
**ABC – Extended** (melhor para dev, mantém o layout US) ou **Brazilian**.

### Ajustes que valem no primeiro dia

| Ajuste | Onde |
|---|---|
| **Caps Lock → Esc** (ouro puro no Vim) | Keyboard → Keyboard Shortcuts → Modifier Keys |
| Key repeat rápido | já feito pelo `defaults.sh` — exige **logout** |
| F1–F12 como função, não brilho/volume | Keyboard → "Use F1, F2 as standard function keys" |
| Tecla 🌐 (Globe) não fazer nada | Keyboard → Press 🌐 to → Do Nothing |

> `defaults.sh` desliga `ApplePressAndHoldEnabled`. Sem isso, **segurar `j` no
> Neovim não repete** — abre o seletor de acentos. É o item nº 1 de frustração de
> quem usa Vim no Mac.

---

## 4. Trackpad — o que você vai sentir falta se voltar

Vale investir 10 minutos aqui. System Settings → Trackpad.

| Gesto | Faz |
|---|---|
| 3 dedos para cima | Mission Control (todas as janelas) |
| 3 dedos para os lados | trocar de Space / tela cheia |
| 4 dedos pinçando | Launchpad |
| Espalhar 4 dedos | mostrar Desktop |
| 2 dedos nas bordas | scroll (natural, invertido — dá pra desligar) |
| **3 dedos arrastando** | mover janela/seleção sem clicar |

O `defaults.sh` já liga **tap to click** e **three-finger drag** (esse segundo
fica escondido em Accessibility na UI).

> Mouse externo com scroll invertido é o clássico: o macOS aplica "natural
> scrolling" ao trackpad **e** ao mouse com a mesma chave. O **LinearMouse** (já
> no Brewfile) separa os dois.

---

## 5. Finder vs Explorer

| Explorer | Finder |
|---|---|
| barra de endereço | `Cmd+Shift+G` → digite o caminho |
| `Ctrl+X` em arquivo | não existe — `Cmd+C` e depois `Cmd+Option+V` |
| mostrar ocultos | `Cmd+Shift+.` |
| nova pasta | `Cmd+Shift+N` |
| subir um nível | `Cmd+↑` |
| voltar | `Cmd+[` |
| abrir terminal aqui | botão direito → Services, ou `open .` no sentido inverso |
| espaço = nada | **espaço = Quick Look** (preview de qualquer arquivo) |

Do terminal, `open .` abre o Finder na pasta atual — o `explorer.exe .` do WSL.

**`.DS_Store`**: o Finder cria esse arquivo em toda pasta que você abre. O
`bootstrap.sh` põe ele num `~/.gitignore_global` para não vazar em commit.

---

## 6. Janelas — AeroSpace

Tiling i3-like, sem mexer no SIP. Config em `macos/aerospace/aerospace.toml`.
Aqui `alt` = **Option**.

| Atalho | Ação |
|---|---|
| `Alt+Enter` | novo Ghostty |
| `Alt+H/J/K/L` | mover **foco** |
| `Alt+Shift+H/J/K/L` | mover a **janela** |
| `Alt+1..9` | ir para workspace |
| `Alt+Shift+1..9` | mandar janela para workspace |
| `Alt+Tab` | voltar ao workspace anterior |
| `Alt+/` | alternar split horizontal/vertical |
| `Alt+,` | virar accordion (empilhar) |
| `Alt+F` | fullscreen |
| `Alt+Shift+F` | soltar a janela (floating) |
| `Alt+-` / `Alt+=` | redimensionar |
| `Alt+Shift+;` | modo service (`r` = resetar layout, `Esc` = sair) |

Workspaces fixos por app: **1** terminal, **2** editor, **3** browser, **4** chat.

> ⚠️ **O AeroSpace captura `Alt+<tecla>` globalmente**, antes do app em foco. Por
> isso `Alt+C` **não** está mapeado — é do fzf. Confira o arquivo antes de
> adicionar binding novo.

> ⚠️ Desligue **System Settings → Desktop & Dock → "Displays have separate
> Spaces"** e faça logout. Com isso ligado, o macOS reposiciona janelas por conta
> própria e briga com qualquer tiler.

---

## 7. Terminal — o que muda vindo do WSL

A mudança mental maior: **acabou a fronteira Windows ↔ Linux**. Não existe mais
`/mnt/c`, nem `\\wsl$`, nem X410, nem `clip.exe`. Um sistema Unix só, e o Finder
enxerga os mesmos arquivos.

| WSL | macOS |
|---|---|
| `explorer.exe .` | `open .` |
| `clip.exe` / `Get-Clipboard` | `pbcopy` / `pbpaste` |
| `wslpath` | — desnecessário |
| X410 + `DISPLAY` | — apps são nativos |
| `nala` / `apt` | `brew` |
| `systemctl` | `launchctl` / `brew services` |
| `~/.config` | `~/.config` **e** `~/Library/Application Support` |
| `/etc/hosts` | `/etc/hosts` (igual) |

```sh
cat id_rsa.pub | pbcopy     # copiar para o clipboard do sistema
pbpaste > arquivo.txt
open -a "Google Chrome" .   # abrir algo com app específico
say "build terminou"        # notificação sonora do fim de um build longo
```

**Neovim:** `clipboard=unnamedplus` passa a funcionar direto via `pbcopy`. Todo
o hack de `clip.exe` no `init.lua` fica desligado sozinho (`vim.fn.has("wsl")`).

**Ghostty:** `Cmd+D` split à direita, `Cmd+Shift+D` embaixo,
`Cmd+Option+setas` navega, `Cmd+Shift+Enter` zoom, `` Cmd+` `` terminal
drop-down, `Cmd+Shift+,` recarrega a config.

> ⚠️ **O APFS é case-insensitive por padrão.** `Arquivo.ts` e `arquivo.ts` são o
> mesmo arquivo. Repo que tem os dois (acontece em projeto grande vindo do Linux)
> vai dar conflito estranho no `git status`. Se bater nisso, crie um volume APFS
> case-sensitive só para aquele projeto.

---

## 8. Pacotes — brew

Um gerenciador só, no lugar de `nala` + `scoop`:

```sh
brew install ripgrep            # CLI (formula)
brew install --cask raycast     # app .app (cask)
brew search <termo>
brew info <pacote>
brew uninstall <pacote>
brew update && brew upgrade     # atualiza tudo, CLI e apps
brew services start postgresql  # daemons (o systemctl daqui)
brew doctor                     # diagnóstico
brew autoremove && brew cleanup # limpar órfãos e caches
```

Tudo o que esta máquina tem está em `macos/Brewfile`. Instalou algo novo à mão?
`brew bundle dump --file=macos/Brewfile --force` e commite.

---

## 9. Dev em Apple Silicon

| Ponto | O que saber |
|---|---|
| Prefixo do brew | `/opt/homebrew`, **não** `/usr/local` (esse é Intel) |
| Imagens Docker amd64 | funcionam via Rosetta no OrbStack; force com `--platform linux/amd64` |
| **Fim do Rosetta** | some no macOS 28 (out/2027). A exceção mantida é binário Intel **dentro de VM Linux** — ou seja, seus containers amd64 sobrevivem; apps Intel nativos, não. Prefira sempre build Apple Silicon |
| `docker` / `docker compose` | idênticos — o OrbStack fornece o mesmo CLI |
| asdf: node, java, go, kotlin, dotnet | têm build arm64 nativo, instalam normal |
| **asdf: python 3.6.2 / 2.7.13** | **não compilam aqui** — anteriores ao Apple Silicon. Fixe um 3.x atual |
| JetBrains | via Toolbox, build "Apple Silicon" (não a Intel) |
| Java | temurin arm64; se um projeto exigir x86, `asdf` tem builds Intel via Rosetta |
| Performance | 48 GB dá folga confortável para IDE + OrbStack + emulação amd64 simultâneos |

---

## 10. "Por que não funciona" — permissões

macOS bloqueia por padrão, e frequentemente **sem mensagem de erro**. Os três
lugares em System Settings → Privacy & Security:

| Permissão | Quem precisa | Sintoma sem ela |
|---|---|---|
| **Accessibility** | AeroSpace, Raycast, AltTab, Karabiner | app abre e simplesmente não faz nada |
| **Full Disk Access** | Terminal/Ghostty, backup | "Operation not permitted" em `~/Library`, Mail, etc. |
| **Input Monitoring** | Karabiner, AltTab | teclas não são capturadas |

**Gatekeeper**: app baixado fora da App Store dá "não pode ser aberto".

> ⚠️ O truque de **botão direito → Open** foi **removido no macOS Sequoia** e
> continua removido no Tahoe 26. Todo tutorial que ensina isso está desatualizado.

O caminho atual: **System Settings → Privacy & Security** → role até **Security**
→ **Open Anyway**. Esse botão só aparece por **~1 hora** depois da tentativa
bloqueada; se sumiu, tente abrir o app de novo e volte lá.

Via CLI: `xattr -d com.apple.quarantine /Applications/App.app`. Apps instalados
com `brew install --cask` já vêm sem quarentena.

---

## 11. Backup e segurança

| Item | Ação |
|---|---|
| **FileVault** | ligue no dia 1 (Privacy & Security). Disco sem cripto em laptop de trabalho é risco |
| **Time Machine** | um SSD externo. É o backup mais indolor que existe — restaura a máquina inteira |
| **Touch ID para `sudo`** | já feito pelo `defaults.sh` via `/etc/pam.d/sudo_local` |
| **Find My Mac** | ligue junto com o Apple Account |
| **Senha de firmware** | opcional; Apple Silicon já protege bem com FileVault + Secure Enclave |

O `sudo_local` sobrevive a update de sistema, diferente de editar `/etc/pam.d/sudo`.

---

## 12. Equivalências do seu stack Windows

| Windows | macOS |
|---|---|
| Windows Terminal | **Ghostty** |
| PowerShell | zsh (o mesmo do WSL) |
| Flow Launcher | **Raycast** |
| Ditto | **Maccy** |
| Windhawk / TranslucentTB | nativo — `background-blur = macos-glass-regular` no Ghostty |
| FancyZones / Win+setas | **AeroSpace** |
| Alt+Tab | **AltTab** (configure para `Cmd+Tab`) |
| Scoop | `brew --cask` |
| Nala / apt | `brew` |
| Docker Desktop | **OrbStack** |
| Registro do Windows | `defaults write` (veja `macos/defaults.sh`) |
| Gerenciador de Tarefas | Activity Monitor + **Stats** na menu bar |
| Bibata cursor | ❌ macOS não tem tema de cursor — só tamanho/contraste em Accessibility |

---

## 13. Plano de 4 semanas

**Semana 1 — não quebrar nada.** Rode `bootstrap.sh` e `defaults.sh`, faça
logout, conceda as permissões de Accessibility, valide `ssh -T git@github.com` e
`git clone` nos dois remotes. Use `Cmd+Space` (Raycast) para tudo. Só isso.

**Semana 2 — mãos.** Decore a tabela da seção 2, especialmente `Cmd+←/→`,
`Fn+Delete` e `Cmd+Q` vs `Cmd+W`. Ative Caps Lock → Esc. Aprenda os 4 gestos de
trackpad.

**Semana 3 — janelas.** Só então ligue o AeroSpace para valer. Comece com
`Alt+1..4` e `Alt+H/J/K/L`. O resto dos bindings vem depois.

**Semana 4 — trabalho pesado.** Suba o ambiente Domo: OrbStack, `kubectl`,
`tug`, `domo-admin`. Aqui você descobre o que ainda falta — e aí ajusta o
`Brewfile` e commita.

---

## Referência rápida

```sh
./macos/bootstrap.sh        # setup da máquina (re-executável)
./macos/defaults.sh         # preferências do sistema
brew bundle --file=macos/Brewfile
aerospace reload-config
ghostty +list-themes
defaults read com.apple.dock                 # ver config atual de um app
defaults delete com.apple.dock <chave>       # reverter uma tweak
```
