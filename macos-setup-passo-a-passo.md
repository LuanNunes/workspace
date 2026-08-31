# 🍎 Setup guiado — entendendo cada passo

Este documento existe porque rodar um script que faz dez coisas de uma vez não
ensina nada sobre o sistema novo. Aqui cada passo tem: **o que roda**, **o que
muda de verdade no disco**, **como verificar** e **como desfazer**.

Ordem sugerida: leia a Parte 1 inteira (20 min, vale cada minuto — ela explica
90 % dos "por que isso não funciona" que você vai encontrar), depois execute a
Parte 2 um passo por vez.

**Antes de qualquer coisa, veja o que aconteceria sem acontecer nada:**

```sh
./macos/bootstrap.sh --list            # os 10 passos
./macos/bootstrap.sh --dry-run all     # imprime cada comando, não muda nada
```

---

# Parte 1 — os 9 conceitos que explicam o macOS

## ① Um `.app` é uma **pasta**, não um executável

```sh
ls -la /Applications/Ghostty.app          # é um diretório
ls /Applications/Ghostty.app/Contents     # MacOS/ Resources/ Info.plist
```

Um "app bundle" é uma pasta que o Finder desenha como se fosse um arquivo. O
binário de verdade está em `Contents/MacOS/`, os metadados em `Info.plist`.

**Consequência prática:** instalar é copiar uma pasta, desinstalar é apagar a
pasta. Não existe "instalador" nem entradas espalhadas num registro. É por isso
que `brew install --cask` é tão rápido, e por que arrastar pro lixo realmente
desinstala (sobram só preferências em `~/Library`, alguns KB).

## ② `~/Library` é o `AppData`

Fica oculto no Finder de propósito. Do terminal é uma pasta comum:

| Pasta | Equivalente Windows | Contém |
|---|---|---|
| `~/Library/Preferences/` | `HKCU` do registro | os `.plist` de configuração |
| `~/Library/Application Support/` | `%APPDATA%` | dados dos apps |
| `~/Library/Caches/` | `%LOCALAPPDATA%\...\Cache` | cache descartável |
| `~/Library/LaunchAgents/` | pasta Inicializar / Run key | o que sobe no login |
| `~/Library/Logs/` | Visualizador de Eventos | logs de app |

```sh
open ~/Library          # abre no Finder mesmo estando oculta
```

Repare na divisão que confunde: ferramentas **CLI** seguem o hábito XDG e usam
`~/.config/<tool>`; apps **nativos** usam `~/Library/Application Support`. O
Ghostty e o AeroSpace aceitam os dois — nossos symlinks usam `~/.config` para
manter tudo num lugar só.

## ③ `defaults` é o registro — e tem uma pegadinha séria

```sh
defaults domains                              # todos os domínios (bem longo)
defaults read com.apple.dock                  # config atual do Dock
defaults read com.apple.dock autohide         # uma chave
defaults write com.apple.dock autohide -bool true
defaults delete com.apple.dock autohide       # volta ao padrão do sistema
```

Isso grava em `~/Library/Preferences/com.apple.dock.plist`.

> ⚠️ **Não edite o `.plist` na mão.** Existe um daemon, o `cfprefsd`, que mantém
> as preferências em cache na memória e reescreve o arquivo quando bem entende —
> sua edição manual é simplesmente perdida. `defaults` conversa com o daemon; um
> editor de texto, não. Essa é a diferença mais importante entre `defaults` e
> "editar o registro" no Windows.

Muitos apps só releem a config ao iniciar. Daí o `killall Dock` / `killall
Finder` no fim do `defaults.sh` — não é gambiarra, é o jeito certo.

## ④ `launchd` é o `systemd`

Um único supervisor para daemons, serviços e tarefas agendadas.

| systemd | launchd |
|---|---|
| `systemctl list-units` | `launchctl list` |
| `systemctl start x` | `launchctl kickstart` / `brew services start x` |
| `/etc/systemd/system/` | `/Library/LaunchDaemons/` (sistema, no boot) |
| `~/.config/systemd/user/` | `~/Library/LaunchAgents/` (usuário, no login) |
| cron / timers | também launchd (`StartCalendarInterval`) |

`brew services start postgresql` só escreve um `.plist` em `~/Library/LaunchAgents`
e avisa o launchd. Nada mágico.

## ⑤ SIP — por que nem `root` pode tudo

**System Integrity Protection** é proteção no nível do kernel: mesmo como root
você não escreve em `/System`, `/usr` (exceto `/usr/local`), nem injeta código em
processos assinados pela Apple.

```sh
csrutil status        # "System Integrity Protection status: enabled"
```

**Por que isso importa na sua escolha de gerenciador de janelas:** o `yabai`
precisa injetar num processo do sistema para ter os recursos bons, e por isso
pede que você desabilite parte do SIP. O **AeroSpace** foi desenhado para usar só
a API pública de Acessibilidade — funciona com o SIP intacto. Foi por isso que
recomendei ele, e não só por ser mais simples.

## ⑥ TCC — por que o app abre e "não faz nada"

**Transparency, Consent and Control** é o banco de permissões: Acessibilidade,
Acesso Total ao Disco, Monitoramento de Entrada, câmera, microfone, contatos.

A diferença cultural em relação ao Windows: o UAC **pergunta e bloqueia**. O TCC
frequentemente **deixa o app rodar e só nega a capacidade** — sem erro, sem
diálogo. O AeroSpace abre, aparece na barra, e simplesmente não move janela
nenhuma. Nada no log diz por quê.

```sh
# o banco existe, mas é protegido pelo SIP — só a UI escreve nele
ls -l ~/Library/Application\ Support/com.apple.TCC/
```

Onde resolver: **System Settings → Privacy & Security**.

| Permissão | Quem precisa aqui | Sem ela |
|---|---|---|
| **Accessibility** | AeroSpace, Raycast, AltTab, Karabiner | app abre e não faz nada |
| **Input Monitoring** | Karabiner, AltTab | teclas não são capturadas |
| **Full Disk Access** | Ghostty/Terminal, backup | `Operation not permitted` em `~/Library`, Mail, etc. |

> Se você conceder e ainda assim não funcionar: **saia e reabra o app**. A
> permissão só é lida na inicialização do processo.

## ⑦ Gatekeeper, quarentena e notarização

Quando um navegador baixa um arquivo, ele marca com um atributo estendido:

```sh
xattr -l ~/Downloads/algo.dmg        # com.apple.quarantine: 0081;...
```

Na primeira abertura, o Gatekeeper verifica assinatura de desenvolvedor e
**notarização** (o app foi enviado à Apple, que escaneou e carimbou). Sem isso:
"não pode ser aberto".

> ⚠️ **O truque de botão-direito → Open foi removido no macOS Sequoia** e
> continua removido no Tahoe 26. O caminho atual é:
> **System Settings → Privacy & Security** → role até **Security** → **Open
> Anyway**. Esse botão só aparece por **cerca de 1 hora** depois da tentativa
> bloqueada — se sumiu, tente abrir o app de novo e volte lá.

Pela linha de comando, removendo a marca de quarentena:

```sh
xattr -d com.apple.quarantine /Applications/App.app
codesign -dv --verbose=4 /Applications/App.app   # quem assinou, e com o quê
spctl -a -vv /Applications/App.app               # o que o Gatekeeper acha
```

Apps instalados via `brew install --cask` já vêm sem quarentena — o brew remove.

## ⑧ arm64, x86_64 e Rosetta

```sh
uname -m                          # arm64
arch                              # arm64
file $(which brew)                # Mach-O 64-bit executable arm64
lipo -archs /Applications/Foo.app/Contents/MacOS/Foo   # universal? só Intel?
arch -x86_64 zsh                  # força um shell traduzido, para testes
```

Rosetta traduz binários Intel na hora. Duas coisas a saber:

1. **Prefira sempre o build nativo.** No JetBrains Toolbox, escolha "Apple
   Silicon", não Intel.
2. **A Apple aposenta o Rosetta no macOS 28 (outono/2027).** A exceção que ela
   vai manter é justamente binários Intel **dentro de VMs Linux** — que é o caso
   do OrbStack rodando imagem `linux/amd64`. Seu fluxo de container sobrevive;
   apps Intel nativos param.

## ⑨ APFS é *case-insensitive* por padrão

```sh
diskutil info / | grep -i "File System"
```

`Arquivo.ts` e `arquivo.ts` são o **mesmo arquivo**. Um repo vindo do Linux que
contenha os dois vai se comportar de forma estranha no `git status`. Se bater
nisso, crie um volume APFS case-sensitive separado (Disk Utility → `+`) e clone
o projeto lá.

### Bônus: por que seu `PATH` parece embaralhado

O macOS roda `/usr/libexec/path_helper` a partir de `/etc/zprofile`, que
**reconstrói** o `PATH` a partir de `/etc/paths` e `/etc/paths.d/*`. Isso acontece
**antes** do `~/.zshrc`. Por isso o `.zshrc` faz `eval "$(brew shellenv)"` — para
colocar o Homebrew na frente **depois** que o path_helper já fez o dele.

```sh
cat /etc/paths; ls /etc/paths.d/
echo $PATH | tr ':' '\n'
```

---

# Parte 2 — os 10 passos

Cada um roda sozinho: `./macos/bootstrap.sh <passo>`.

---

## Passo 1 — `clt` · Xcode Command Line Tools

```sh
./macos/bootstrap.sh clt
```

**O que é:** clang, make, headers do SDK do macOS e o git da Apple. O
`build-essential` daqui. O Homebrew precisa dele para compilar, e o treesitter
do Neovim para compilar parsers.

**O que muda:** ~1,5 GB em `/Library/Developer/CommandLineTools`. Abre um
instalador gráfico — é normal, não dá para automatizar sem baixar do portal.

**Verificar:**
```sh
xcode-select -p          # /Library/Developer/CommandLineTools
clang --version
```

**Desfazer:** `sudo rm -rf /Library/Developer/CommandLineTools`

---

## Passo 2 — `rosetta`

```sh
./macos/bootstrap.sh rosetta
```

**O que é:** o tradutor x86_64 → arm64 (conceito ⑧).

**O que muda:** instala o daemon de tradução `oahd`. Nada no seu `$HOME`.

**Verificar:**
```sh
pgrep oahd && echo "rosetta ativo"
arch -x86_64 uname -m     # imprime x86_64 = tradução funcionando
```

**Desfazer:** `sudo softwareupdate --install-rosetta` não tem contrapartida
oficial de remoção; na prática não vale desinstalar.

---

## Passo 3 — `brew` · Homebrew

```sh
./macos/bootstrap.sh brew
```

**O que é:** o gerenciador de pacotes. **Formula** = software CLI (compilado, ou
baixado pronto como "bottle"). **Cask** = um `.app` normal copiado para
`/Applications`.

**O que muda:** cria `/opt/homebrew` (no Apple Silicon; `/usr/local` é Intel e
qualquer tutorial que use esse caminho é da era Intel). Pede sua senha uma vez
para criar o diretório.

**Verificar:**
```sh
brew --prefix            # /opt/homebrew
brew config
/opt/homebrew/bin/brew shellenv     # veja exatamente o que o .zshrc avalia
```

**Desfazer:** o script oficial de uninstall do Homebrew, ou `sudo rm -rf /opt/homebrew`.

---

## Passo 4 — `packages` · tudo do Brewfile

```sh
./macos/bootstrap.sh packages     # demora; é o passo mais longo
```

**O que é:** lê `macos/Brewfile` e instala tudo. Esse arquivo **é** o inventário
da máquina — instalou algo à mão depois? Adicione lá e commite.

**O que muda:** binários em `/opt/homebrew/bin`, apps em `/Applications`. Vai
pedir senha para os casks.

**Verificar:**
```sh
brew bundle check --file=macos/Brewfile --verbose    # o que falta
brew list --formula | wc -l
brew list --cask
```

**Desfazer:** `brew uninstall <pacote>` ou `brew bundle cleanup --file=macos/Brewfile`.

> O passo também roda `chmod -R go-w /opt/homebrew/share/zsh`. Sem isso, o
> `compinit` do zsh detecta o diretório como gravável pelo grupo, recusa carregar
> as completions de lá e reclama em toda abertura de shell.

---

## Passo 5 — `omz` · Oh My Zsh

```sh
./macos/bootstrap.sh omz
```

**O que é:** só o framework que seu `.zshrc` já sourceia. **Não** há `chsh` aqui:
o macOS já usa zsh como shell de login desde o Catalina.

**O que muda:** `~/.oh-my-zsh`. O `KEEP_ZSHRC=yes` é essencial — sem ele o
instalador sobrescreve o `~/.zshrc` com o template dele, destruindo o symlink.

**Verificar:** `ls ~/.oh-my-zsh && echo $SHELL` → `/bin/zsh`

**Desfazer:** `uninstall_oh_my_zsh` ou `rm -rf ~/.oh-my-zsh`.

---

## Passo 6 — `links` · os symlinks

```sh
./macos/bootstrap.sh --dry-run links    # veja os destinos primeiro
./macos/bootstrap.sh links
```

**O que muda:**

| Destino | Origem no repo |
|---|---|
| `~/.zshrc` | `.zshrc` |
| `~/.p10k.zsh` | `.p10k.zsh` |
| `~/.ideavimrc` | `.ideavimrc` |
| `~/.config/nvim/init.lua` | `nvim/init.lua` |
| `~/.config/nvim/lazy-lock.json` | `nvim/lazy-lock.json` |
| `~/.config/ghostty/config` | `macos/ghostty/config` |
| `~/.config/aerospace/aerospace.toml` | `macos/aerospace/aerospace.toml` |

Se já existir um arquivo **real** no destino, ele é renomeado para
`<arquivo>.bak.<timestamp>` — nada é destruído.

**Verificar:** `ls -la ~/.zshrc` → deve mostrar `-> .../workspace/.zshrc`

**Desfazer:** `rm ~/.zshrc && mv ~/.zshrc.bak.<ts> ~/.zshrc`

---

## Passo 7 — `secrets`

```sh
./macos/bootstrap.sh secrets
```

Cria `~/.zshrc.secrets` (chmod 600) a partir do template. É git-ignored e
sourceado pelo `.zshrc`. Se você copiou o arquivo real da máquina antiga, o passo
detecta e não sobrescreve.

**Verificar:** `ls -l ~/.zshrc.secrets` → `-rw-------`

---

## Passo 8 — `ssh`

```sh
./macos/bootstrap.sh ssh
```

**O que faz:** escreve **apenas** `~/.ssh/config`. **Nunca gera chaves** — a
`nunes@domo` está registrada na org, regerar te tranca para fora.

**A diferença conceitual em relação ao WSL:** lá, o `keychain` mantém um
`ssh-agent` vivo e você digita a passphrase uma vez por boot. Aqui,
`AddKeysToAgent yes` + `UseKeychain yes` mandam o ssh guardar a passphrase no
**login Keychain** do macOS e carregar a chave sob demanda — você digita **uma
vez, e nunca mais**. É por isso que o bloco do `keychain` no `.zshrc` é pulado
no darwin.

**Depois de copiar os arquivos de chave:**
```sh
chmod 600 ~/.ssh/nunes@domo ~/.ssh/nunes.lfa
ssh-add --apple-use-keychain ~/.ssh/nunes@domo ~/.ssh/nunes.lfa
ssh-add -l                       # o que está carregado
ssh -T git@github.com            # deve saudar luan-nunes_domo
ssh -T git@github-luan           # deve saudar LuanNunes
```

**Verificar onde a passphrase foi parar:** abra o app **Keychain Access**, busque
por `SSH`. Está lá, criptografada pelo login.

---

## Passo 9 — `asdf`

```sh
./macos/bootstrap.sh asdf
```

**O que faz:** só adiciona os plugins (nodejs, java, golang, kotlin, dotnet-core,
python) e gera as completions. **Não instala versões** — isso é lento e você deve
ver acontecer:

```sh
asdf install            # tudo que está em ~/.tool-versions
asdf list               # o que está instalado
asdf current            # o que está ativo aqui
```

**Como o asdf funciona:** ele não troca o `PATH` a cada projeto. Ele põe um
diretório de **shims** no PATH — cada shim é um wrapper minúsculo que lê o
`.tool-versions` mais próximo e despacha para o binário real. É por isso que o
`.zshrc` só precisa de uma linha de PATH.

> ⚠️ **`python 3.6.2` e `2.7.13` do seu `~/.tool-versions` não compilam aqui.**
> São anteriores ao Apple Silicon e quebram contra o OpenSSL 3 e o SDK do macOS
> 26. Fixe um 3.x atual nesta máquina; um `.tool-versions` por projeto mantém as
> versões antigas funcionando no WSL.

---

## Passo 10 — `git`

```sh
./macos/bootstrap.sh git
```

Três ajustes de máquina: `core.autocrlf=false` (o `input` era coisa da era
Windows), `fetch.prune=true`, e um `~/.gitignore_global` com `.DS_Store` — porque
o Finder cria esse arquivo em **toda** pasta que exibe, e sem isso eles vazam nos
seus commits.

**Sua identidade não é configurada aqui** de propósito — você usa duas contas.

```sh
git config --global --list           # ver tudo
git config --show-origin --get user.email    # descobrir de qual arquivo veio
```

---

# Parte 3 — `defaults.sh`, e por que logout

```sh
./macos/defaults.sh
```

**Leia o arquivo antes de rodar** — ele é comentado linha a linha, e agora que
você entende o conceito ③ cada linha faz sentido. Grupos:

| Grupo | Destaque |
|---|---|
| Teclado | `ApplePressAndHoldEnabled=false` — **sem isso, segurar `j` no Neovim não repete**, abre o seletor de acentos |
| Trackpad | tap-to-click e arrastar com 3 dedos |
| Dock / Spaces | `mru-spaces=false` — sem isso o macOS reordena os Spaces por uso e o AeroSpace fica imprevisível |
| Finder | ocultos, barra de caminho, ordenar pastas primeiro |
| Screenshots | vão para `~/Pictures/Screenshots` em vez da Mesa |
| Segurança | Touch ID para `sudo` |

**Por que logout e não só `killall`:** `KeyRepeat`, `InitialKeyRepeat` e
`AppleKeyboardUIMode` são lidos pelo `WindowServer` na criação da **sessão de
login**. `killall` de um app não recarrega isso.

**Touch ID para sudo** merece explicação: gravamos em `/etc/pam.d/sudo_local`, e
não em `/etc/pam.d/sudo`. A Apple criou esse arquivo justamente para
customização — ele **sobrevive a updates do sistema**, enquanto edições no `sudo`
são revertidas a cada atualização.

**Desfazer qualquer linha:**
```sh
defaults delete <domínio> <chave>       # volta ao padrão do sistema
defaults read com.apple.dock            # conferir o estado atual
```

---

# Parte 4 — caixa de ferramentas de investigação

Quando algo não funcionar, estes comandos respondem sozinhos:

```sh
# --- sistema ---
sw_vers                                   # versão do macOS
system_profiler SPHardwareDataType        # chip, RAM, serial
csrutil status                            # SIP ligado?
pmset -g                                  # energia/bateria
diskutil list                             # volumes APFS

# --- apps ---
lsappinfo list                            # o que está rodando, com PID e bundle id
osascript -e 'id of app "Ghostty"'        # descobrir o bundle id de um app
codesign -dv --verbose=4 /Applications/X.app   # assinatura
xattr -l /Applications/X.app              # quarentena?
mdfind -name "algo"                       # busca do Spotlight na CLI

# --- config ---
defaults domains | tr ',' '\n' | sort     # todos os domínios
defaults read com.apple.dock              # config de um app
defaults read-type com.apple.dock autohide

# --- serviços ---
launchctl list | grep -i homebrew
brew services list
ls ~/Library/LaunchAgents/

# --- logs (o Visualizador de Eventos daqui) ---
log show --last 5m --predicate 'process == "AeroSpace"'
log stream --predicate 'eventMessage CONTAINS "denied"'   # ao vivo

# --- rede ---
networksetup -listallhardwareports
scutil --dns
```

O `log show`/`log stream` é o que mais economiza tempo: o TCC registra as
negações lá. Se um app "não faz nada", `log stream` com `denied` costuma mostrar
exatamente qual permissão falta.

---

# Roteiro sugerido, sem pressa

| Quando | O quê |
|---|---|
| Dia 1 | Ler a Parte 1. `--dry-run all`. Passos 1–5. |
| Dia 1 (noite) | Passos 6–10. Abrir o Ghostty, deixar Zinit e lazy.nvim instalarem. |
| Dia 2 | Ler e rodar `defaults.sh`. Logout. Conceder Accessibility. |
| Dia 2 | Copiar as chaves SSH, validar os dois remotes. |
| Dia 3 | `asdf install`, subir um projeto de verdade, ver o que falta. |
| Semana 2 | Só então ligar o AeroSpace para valer (`macos-cheatsheet.md` §6). |

Referência do dia a dia — atalhos, acentos, equivalências Windows→macOS:
**[`macos-cheatsheet.md`](macos-cheatsheet.md)**.
