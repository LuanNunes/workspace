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

São teclas **diferentes**. O Vim e o zsh recuperam quase todo o `Ctrl`:
`Ctrl+R` (atuin), `Ctrl+T` (fzf), `Ctrl+A/E` — livres, sem conflito. A exceção é
o `Ctrl+W`, que desde 2026-09-10 fecha janela no AeroSpace (seção 6) e por isso
não chega mais ao zsh nem ao Neovim.

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

> **`Alt+Tab` é o AltTab**, que é um switcher por **janela** — escolher já traz
> a janela. O `Cmd+Tab` continua o nativo, por **app**, e é daí que vem o
> "escolhi o app e ele não abriu": ativar um app não levanta janela nenhuma.
>
> O AeroSpace **não mapeia nada** em `Alt+Tab` nem em `Alt+Shift+Tab`, de
> propósito: esses dois são os atalhos padrão do AltTab, e o AeroSpace captura
> antes do app, então qualquer binding ali comeria o switcher. Foi o que
> acontecia — `Alt+Tab` era `workspace-back-and-forth` e trocava de workspace
> quando você queria trocar de app. Esse comando saiu junto; se fizer falta,
> ponha num chord que não seja tab.
>
> Ele precisa de **Accessibility** para enxergar janela alheia, e de **Screen &
> System Audio Recording** para mostrar título e miniatura (o nome assustador é
> do Sequoia, que juntou o áudio do sistema no mesmo interruptor). Sem a
> primeira ele abre e não faz nada.
>
> `Alt` + `` ` `` continua sendo o ciclo **deste** workspace (seção 6) — o
> AltTab lista tudo, sem filtrar por workspace, e as duas coisas servem para
> momentos diferentes.

> **Uma coisa tentada e desfeita, para não repetir:** remapear `Cmd+Tab` no
> **Karabiner** para o ciclo do AeroSpace. Funciona, mas o Karabiner intercepta
> no nível do HID, então o macOS nunca vê a tecla e o overlay com os ícones
> **some**. A troca vira um pulo cego. Desfeito no mesmo dia.

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

> **`acentos`** no terminal imprime essa tabela. É uma função no `.zshrc` (só
> macOS), para não ter que voltar aqui toda vez que a tecla morta escapar.

Se preferir teclado dedicado, System Settings → Keyboard → Input Sources →
**ABC – Extended** (melhor para dev, mantém o layout US) ou **Brazilian**.

### Ajustes que valem no primeiro dia

| Ajuste | Onde |
|---|---|
| **Caps Lock → Esc** (ouro puro no Vim) | `macos/karabiner/karabiner.json` — vale para **todo** teclado |
| F1–F12 como função, não brilho/volume | idem, mas só no Keychron K2 |
| Key repeat rápido | já feito pelo `defaults.sh` — exige **logout** |
| Tecla 🌐 (Globe) não fazer nada | Keyboard → Press 🌐 to → Do Nothing |

### Keychron K2

O ajuste de `Caps Lock` em System Settings → Keyboard → Keyboard Shortcuts →
Modifier Keys é **por dispositivo**: configurado no K2, ele não vale no teclado
interno, e some quando você pluga outro teclado. Por isso o remap mora no
Karabiner, versionado no repo.

O K2 em modo Mac se anuncia com o vendor ID da **Apple** (`1452`), produto
`591` — o teclado interno é `1452`/`33028`, então os dois são distinguíveis. É
esse par que o `karabiner.json` usa para deixar a fn row como F1–F12 só no K2,
mantendo brilho/volume diretos no teclado do MacBook.

#### `Page Down` vira `Del` (apagar para frente)

O macOS chama de `delete` a tecla que apaga **para trás** — o Backspace do
Windows. Apagar para frente (`⌦`, o `Del` do Windows) é `Fn`+`delete`, um chord
para algo que no Windows era uma tecla só.

O `karabiner.json` remapeia `page_down` → `delete_forward`, **só no K2**. Você
não perde a função de página: `Fn`+`↓` é Page Down nativo no macOS, sem
configuração nenhuma.

Para identificar qualquer tecla deste teclado com certeza — as legendas são
duplas e mudam de papel com a chavinha — abra o **Karabiner-EventViewer** e
aperte a tecla. Ele mostra o nome que o macOS recebeu (`delete_or_backspace`
para o Backspace, `delete_forward` para o Del).

#### A fileira de baixo muda de ordem com a chavinha

Esta é a pegadinha nº 1 de quem vem do Windows, e ela **parece** um bug de
config: "o Alt parou de funcionar".

```
Windows/Android:   Ctrl │  ⊞ Win   │   Alt     │ ␣
Mac/iOS:           Ctrl │ ⌥ Option │ ⌘ Command │ ␣
```

A tecla colada no espaço era `Alt` e virou `⌘ Command`. O dedo vai no mesmo
lugar e sai o modificador errado, então nenhum binding `alt-*` do AeroSpace
dispara. O Option está **uma tecla à esquerda**.

Teste em 5 segundos, sem ferramenta nenhuma: no Spotlight, digite algo, segure a
tecla suspeita e aperte `A`. Selecionou tudo = é `Command`. Saiu `å` = é
`Option`.

Não vale a pena trocar Option↔Command para "devolver" o Alt ao polegar: `⌘` é a
tecla mais usada do macOS, e o remap valeria só no K2 — o teclado interno
continuaria no layout Apple, deixando as duas memórias musculares em conflito.

Dois pré-requisitos físicos, antes de culpar a config:

1. A chave lateral do K2 em **Mac/iOS**, não Windows/Android.
2. O Karabiner precisa ter a **driver extension** aprovada. Sem isso ele fica
   instalado e inerte, sem mensagem de erro nenhuma:

```sh
systemextensionsctl list      # "0 extension(s)" = inerte
```

Aprove em System Settings → General → Login Items & Extensions → Driver
Extensions, e conceda Input Monitoring em Privacy & Security.

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
> no Brewfile, config versionada em `macos/linearmouse/`) separa os dois.

### Velocidade do mouse: um dispositivo, um lugar

| Dispositivo | Onde configurar |
|---|---|
| Mouse externo (Keychron M2) | LinearMouse → *Pointer → Speed* |
| Trackpad | System Settings → Trackpad |

O `linearmouse.json` desliga a aceleração do M2 (`disableAcceleration`). Com ela
desligada o LinearMouse governa o ponteiro daquele dispositivo e a curva do
macOS sai do caminho — então mexer no *Tracking speed* de System Settings quase
não muda nada, e parece que o mouse está quebrado. Ajuste velocidade no mesmo
lugar em que a aceleração está desligada.

O `com.apple.mouse.scaling` do sistema continua valendo como **fallback**, para
o intervalo antes de os login items carregarem ou se o LinearMouse cair. Deixe
num valor razoável — se estiver muito baixo, esse intervalo parece defeito.

---

> **"Notificações" na área de trabalho que não fecham** provavelmente não são
> notificações. Widgets de desktop (Bolsa, Tempo, Calendário) são desenhados
> pelo processo *Notification Center* e ficam numa camada **negativa**, atrás de
> tudo — daí não terem botão de fechar. Para identificar, o dono e a camada
> aparecem em qualquer inspetor de janelas; camada negativa = widget.
>
> O `defaults.sh` já desliga os dois interruptores (`StandardHideWidgets` e
> `StageManagerHideWidgets`). Para remover só alguns em vez de todos, é
> Control-clique na área de trabalho → *Edit Widgets*, e o menos em cada um.

### Notificação travada na tela

Banner que não sai no X nem passando o mouse:

```sh
killall NotificationCenter
```

O agente reinicia sozinho — é do sistema — e os banners na tela vão embora. Não
apaga o histórico da Central de Notificações, só limpa o que está desenhado.

> ⚠️ **Responda antes de matar.** Alguns banners são pedidos de decisão, não
> avisos: os de *App Background Activity* (agentes e daemons pedindo para subir
> no login) e os de permissão de notificação têm `Allow` / `Don't Allow`
> aparecendo ao passar o mouse. Descartar sem responder deixa o pedido pendente
> — e no caso dos daemons do Karabiner, isso significa o remap parar de
> funcionar no próximo boot, sem erro nenhum.
>
> Aviso puramente informativo, como *"Login Item Added"*, pode matar à vontade.

Se o banner **não** responde ao `killall`, provavelmente não é notificação: veja
a nota sobre widgets de desktop acima.

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
| `Alt+Shift+Enter` | focar o Ghostty (abre um se não houver) |
| `Alt+H/L` | mover **foco** na horizontal — atravessa os monitores |
| `Alt+J/K` | mover **foco** na vertical — **fica** neste workspace |
| `Alt+Shift+H/L` / `Alt+Shift+J/K` | mover a **janela**, mesmas fronteiras |
| `Alt+A` | voltar à janela anterior (dentro do mesmo workspace) |
| `Alt` + `` ` `` | **próxima** janela deste workspace |
| `Alt+Shift` + `` ` `` | a anterior, mesma volta ao contrário |
| `Alt+1/2/3` | trocar os **três monitores** de uma vez (desktop 1/2/3) |
| `Alt+4..9` | mover **uma** tela só (quebra o trio de propósito) |
| `Alt+Shift+1..9` | mandar janela para workspace |
| `Alt+Ctrl+1/2/3` | mandar janela para outro **desktop**, na mesma coluna |
| `Alt+Tab` / `Alt+Shift+Tab` | **AltTab**, não AeroSpace — ver acima |
| `Alt+Ctrl+H/J/K/L` | mover o **foco** entre monitores |
| `Alt+Ctrl+Shift+H/J/K/L` | mandar a janela para outro **monitor** |
| `Alt+/` | alternar split horizontal/vertical |
| `Alt+,` | virar accordion (empilhar) |
| `Alt+F` | fullscreen |
| `Alt+Shift+F` | soltar a janela (floating) |
| `Ctrl+W` | fechar a janela — e **encerrar o app** se for a última |
| `Alt+M` | minimizar para o Dock |
| `Alt+Shift+M` | trazer de volta as janelas do app em foco |
| `Alt+-` / `Alt+=` | redimensionar (150px por toque) |
| `Alt+Shift+;` | entrar no modo service (tabela abaixo) |

`Alt+Tab` é entre **workspaces**, `Alt+A` é entre **janelas** — é o que você quer
quando dois apps dividem o mesmo workspace.

`Alt` + `` ` `` percorre **todas** as janelas do workspace em ordem de árvore e
dá a volta no fim, enquanto `Alt+A` só alterna entre as **duas últimas**. O
`--boundaries workspace` no binding é o que segura o ciclo dentro do workspace:
sem ele o `dfs-next` atravessa para o workspace do monitor vizinho.

O `Alt+H/L` **atravessa os monitores** desde 2026-09-10, e antes não: o `focus`
do AeroSpace assume `--boundaries workspace` quando você não diz nada, e com isso
o foco nunca saía da tela atual — num workspace com duas janelas ele só ficava
pulando entre as duas, que é exatamente a cara de "o atalho está preso neste
monitor". O `--boundaries all-monitors-outer-frame` nos bindings é o que solta,
e o `move` ganhou o mesmo por simetria.

**O `Alt+J/K` não recebeu isso, e no mesmo dia recebeu e foi desfeito.** As
colunas desta mesa ficam lado a lado, então horizontal é o eixo que significa
"próxima tela"; vertical só significa "a outra janela deste workspace". Com a
tampa **aberta** a diferença aparece: o MacBook fica fisicamente **abaixo** dos
externos, e aí o `Alt+J` parava de significar "a janela de baixo" e passava a
significar "cair no painel do laptop". Pior no `Alt+Shift+J`, que jogava a
janela para lá — e uma janela que muda de monitor muda de **workspace** junto,
em silêncio, então o `Alt+1/2/3` seguinte mostrava ela num lugar que você não
escolheu. No Mancer em retrato, com Teams em cima e Slack embaixo, é exatamente
a tecla que você usa para ir de um para o outro.

Nada se perdeu: viagem deliberada entre painéis é o `Alt+Ctrl+H/J/K/L`, que age
no **monitor** e dá a volta. É também o que você quer quando **não há** janela
na direção pedida — a tela vizinha está vazia, ou você só quer pular de painel.

**Modo service** — `Alt+Shift+;` e depois **uma** tecla; toda opção já volta
sozinha para o modo main:

| Tecla | Ação |
|---|---|
| `Esc` | recarrega a config e sai |
| `R` | resetar o layout que você embaralhou |
| `F` | alternar floating/tiling |
| `Backspace` | fechar todas as janelas menos a atual |
| `Alt+Shift+H/J/K/L` | juntar esta janela no container do vizinho |

Os monitores se comportam como **uma tela só**: uma tecla troca todas as telas
ao mesmo tempo. Ideia portada do `windows/glazewm/config.yaml`.

Existem **três layouts**, um por contagem de tela, porque uma forma só nunca
serve às três: o arquivo de três telas esconde um terço dos workspaces atrás dos
outros quando só há duas, e o de duas telas deixa metade deles **sem tecla**
quando só há uma (a história está na seção de uma tela, abaixo). O
`macos/aerospace/apply-layout.py` mescla `aerospace.base.toml` com um fragmento
e recarrega:

```sh
./macos/aerospace/apply-layout.py          # detecta as telas e aplica
./macos/aerospace/apply-layout.py 3mon     # força um layout
./macos/aerospace/apply-layout.py --dry-run
```

> ⚠️ **Abrir ou fechar a tampa muda a contagem de telas** — e portanto o layout
> certo. Na mesa em clamshell são duas (`2mon`); levantar a tampa faz três
> (`3mon`); desplugar tudo e sair de casa faz uma (`1mon`).
>
> Isso é automático desde 2026-09-08, via o LaunchAgent `displaywatch`
> (`./macos/bootstrap.sh displaywatch`). Nada no sistema oferecia esse gatilho:
> o launchd dispara em arquivo, não em tela, e o AeroSpace 0.21.3 só tem
> `on-focus-changed`, `on-focused-monitor-changed` e `on-window-detected` —
> nenhum dispara quando um painel aparece ou some. O `display-watch.swift`
> preenche o buraco ouvindo o CoreGraphics e chamando o `apply-layout.py`.
>
> Dois atrasos deliberados lá dentro: **3s** depois do último evento, porque um
> único plug gera uma rajada de callbacks *e* porque o `apply-layout.py` pergunta
> a contagem ao AeroSpace, que demora um instante para concordar com o
> CoreGraphics — disparar na hora lê a contagem **antiga**. E **10s** no arranque,
> que é a corrida com o servidor do AeroSpace subindo no login.
>
> Mudança de resolução **não** dispara nada (o `setModeFlag` está fora do filtro
> de propósito): ela não muda a contagem de telas, então não pode mudar o layout.
>
> ```sh
> tail -f ~/Library/Logs/aerospace-display-watch.log
> launchctl print gui/$UID/dev.luannunes.aerospace-display-watch
> ```

**Layout de duas telas** (`layout-2mon.toml`) — seis workspaces, desktops em
par. **É o layout do dia a dia**, porque as duas configurações desta máquina são
pares: na mesa, Alienware + Mancer com o MacBook **fechado**; na rua, MacBook +
ARZOPA. As colunas são por papel, então o mesmo arquivo serve os dois:

| | Coluna A (secundária) | Coluna B (principal) |
|---|---|---|
| **`Alt+1`** trabalho | ws 1 ← Ghostty, Toggl, Hoppscotch | **ws 2** ← IntelliJ, VS Code |
| **`Alt+2`** chat | ws 3 ← Teams em cima, Slack embaixo | **ws 4** ← Claude, Codex, WhatsApp, Spotify |
| **`Alt+3`** browsers | ws 5 ← Notion | **ws 6** ← Chrome, Safari |

Na mesa a coluna A é o **Mancer em retrato** e a B é o **Alienware**; na rua a A
é a tela do **MacBook** e a B é o **ARZOPA**. Nenhuma linha do arquivo muda entre
os dois — quem decide é qual monitor tem a menu bar.

`Alt+4/5/6` mexem numa tela só. `Alt+7/8/9` ficam **sem binding** — seis
workspaces precisam de seis teclas, e cada `Alt+<tecla>` não usado é uma tecla
devolvida ao zsh e ao Neovim.

**Teams e Slack ficam com a coluna A do desktop de chat inteira**, um em cima do
outro — ws 3 no layout de duas telas, ws 4 no de três. Na mesa essa coluna é o
Mancer em retrato (1440x2560), onde o `default-root-container-orientation =
'auto'` resolve para split **vertical**, então duas janelas ali já viram metade
de cima e metade de baixo. Chat é a única coisa que fica melhor alta do que
larga, e é para isso que o painel serve. Claude, Codex, WhatsApp e Spotify
foram para a tela larga junto.

Quem garante **Teams em cima** e não "o que você abriu primeiro" é o segundo
comando da regra: o `on-window-detected` não sabe dizer "insira na posição 0",
então a janela é colocada e depois empurrada — Teams um passo para cima, Slack
um para baixo.

```toml
{ if.app-id = 'com.microsoft.teams2', run = ['move-node-to-workspace 3 --focus-follows-window', 'move --boundaries workspace --boundaries-action stop up'] },
```

> ⚠️ **Cada regra tem que caber numa linha só.** O re-alojamento do
> `apply-layout.py` lê o bloco `APP_RULES` com regex de uma linha; regra quebrada
> em duas é regra que ele ignora em silêncio, e aí o app fica no workspace que o
> layout antigo deu. O `--boundaries-action stop` também não é enfeite: o padrão
> do `move` é `create-implicit-container`, que em vez de não fazer nada
> embrulharia a janela num container aninhado quando ela já estivesse na ponta.

> Na rua essa mesma coluna é a tela do MacBook, que é **paisagem** — o `auto`
> divide na horizontal e os dois ficam lado a lado, com os empurrões não fazendo
> nada. Tudo bem: o par é o que importa, a orientação é assunto do monitor.

**Layout de três telas** (`layout-3mon.toml`) — nove workspaces, desktops em
trio, com uma terceira coluna: `Alt+1` = ws 1/2/3, `Alt+2` = 4/5/6, `Alt+3` =
7/8/9, e `Alt+4..9` como saída de emergência.

Nesses dois, as colunas são por **papel**: a coluna A é `secondary` (a tela que
não é a principal) e a B é `main`. Trocar qual monitor é o principal inverte as
colunas sozinho.

**Layout de uma tela** (`layout-1mon.toml`) — os mesmos seis workspaces do layout
de duas telas, **uma tecla cada**: `Alt+1..6` vão literalmente para o workspace
de mesmo número. É o único layout em que `Alt+<n>` quer dizer exatamente isso.

| | tecla | |
|---|---|---|
| ws 1 | `Alt+1` | Ghostty, Hoppscotch, Toggl |
| ws 2 | `Alt+2` | IntelliJ, VS Code, Android Studio |
| ws 3 | `Alt+3` | Teams em cima, Slack embaixo |
| ws 4 | `Alt+4` | Claude, Codex, WhatsApp, Spotify |
| ws 5 | `Alt+5` | Notion |
| ws 6 | `Alt+6` | Chrome, Safari, Firefox |

> ⚠️ **Este arquivo nasceu de um bug, em 2026-09-11.** Até então uma tela só era
> servida pelo `layout-2mon.toml`, na teoria de que um layout de pares "degrada"
> para seis workspaces numa tela. Ele não degrada — ele **quebra**. As teclas de
> lá são pares:
>
> ```toml
> alt-1 = ['workspace 1', 'workspace 2']
> ```
>
> e os dois comandos caem no **mesmo** monitor quando só existe um, então o
> segundo sobrescreve o primeiro e você chega sempre no workspace **par**.
> `Alt+1/2/3` iam para ws 2, 4 e 6; **ws 1, 3 e 5 não tinham tecla nenhuma**, e o
> `Alt+4/5/6` não socorria porque também é a metade par. Não é canto: ws 1 é o
> terminal e ws 3 é Teams + Slack, ou seja, os dois workspaces mais procurados
> eram os dois inalcançáveis. Descoberto no café, com o Ghostty parado na ws 1 e
> nenhuma tecla capaz de chegar nele.

**Por que seis workspaces e não três.** Uma tela mostra um workspace, então o
par não tem mais nada a dizer e dobrar cada desktop num workspace só parece o
movimento óbvio. É o errado: juntaria de volta o terminal e a IDE, que o layout
de duas telas separa justamente porque dividir um workspace deixa a IDE com um
terço de tela. Seis workspaces com um slot de app cada mantêm **cada app no
mesmo número nos três layouts** — e é isso que torna fechar a tampa de graça: o
`apply-layout.py` re-homeia janelas abertas quando o layout muda, e com os
números idênticos dos dois lados ele não acha nada para mover.

**As regras de app não são copiadas, são herdadas.** O `layout-1mon.toml` declara

```toml
# ---8<--- APP_RULES = layout-2mon.toml
```

e o `apply-layout.py` vai buscar aquela seção no outro arquivo. Qual app mora em
qual workspace é decisão sobre **apps**; quantos workspaces aparecem ao mesmo
tempo é decisão sobre **telas**. Só a segunda muda quando a tampa fecha, então
instalar um app novo continua sendo editar **um** arquivo — `layout-2mon.toml` —
e nada mais. A herança é de **um nível só** e o corpo da seção que herda tem que
ser comentário: as duas coisas são checadas, com erro na cara em vez de silêncio.

**O terminal e o IDE ficam em colunas diferentes de propósito.** Dividindo um
workspace, o IDE ficava com um terço da tela, e o reflexo era apertar `Alt+F`
para compensar — que nunca segura, porque o `fullscreen` do AeroSpace significa
"a janela em foco ocupa o workspace", não um estado de maximizado. Não há ajuste
para torná-lo persistente: conferi todas as chaves de configuração do binário do
0.21.3. Uma janela por workspace é a resposta que o bloco `[gaps]` já assumia.

> **Resolução das três telas — a conta é sempre pontos por polegada.** Nenhuma
> delas roda no padrão que o macOS escolhe sozinho, e o motivo é o mesmo nas
> três: a densidade da tela do MacBook (~125 ppi) é a referência, e o padrão do
> macOS erra para os dois lados dependendo do tamanho do painel.
>
> | Tela | Modo | ppi efetivo | Por quê |
> |---|---|---|---|
> | **Alienware AW3225QF** 32" 4K | 3008×1692 HiDPI @240Hz | ~109 | o padrão era 1920×1080 (~70 ppi) — UI com quase o dobro do tamanho da do MacBook |
> | **Mancer TE-3217G** 24" 2K | 1440×2560 retrato, 1:1 | ~123 | nativo já casa com o MacBook; HiDPI aqui cortaria a área útil pela metade |
> | **ARZOPA** 16" portátil | 1920×1200 HiDPI | ~141 | o macOS só expunha até 1280×800 (~94 ppi), menos área que o MacBook apesar da tela maior |
>
> ```sh
> betterdisplaycli set --namelike=AW3225QF --resolution=3008x1692 --hiDPI=on
> betterdisplaycli set --namelike=ARZOPA   --resolution=1920x1200 --hiDPI=on
> ```
>
> **No Alienware o HiDPI não é opcional.** É um painel QD-OLED, cujo subpixel é
> triangular em vez de listrado — texto renderizado em 1:1 sai com franja
> colorida nas bordas. O modo escalado renderiza no dobro e reduz, e é o que
> mantém o texto limpo. Os 240Hz sobrevivem à escala.
>
> Pedi 3200×1800 e o macOS encaixou em **3008×1692**: 3200 não está na lista que
> este painel expõe. É o vizinho, e a diferença de densidade é de ~7 ppi.
>
> **O ARZOPA foi escolha deliberada contra a minha recomendação inicial** de
> igualar densidade (1600×1000, ~118 ppi): UI corporativa densa — Domo, VID
> Central e afins — precisa de largura, e cortar conteúdo custa mais que texto
> pequeno. Se um dia pesar na vista, `--resolution=1600x1000` desfaz.
>
> **O Mancer trava em 72Hz** nessa resolução — é o teto que o painel oferece
> pela conexão atual, não uma configuração. Para uma tela de terminal e chat não
> incomoda; se um dia incomodar, o suspeito é o cabo/hub antes do monitor.
>
> Nada disso vive no repo: são preferências do BetterDisplay, e o `defaults.sh`
> não reproduz. Em máquina nova o `brew bundle` instala o app e os modos são
> refeitos à mão. Vale ligar *Protect resolution* no menu do app para o macOS
> não reverter ao reconectar.
>
> **Não confie no `get` dessa chave.** O CLI 4.3.6 devolve uma string de
> interpolação quebrada (`true ? ON : OFF)`) e o valor é **constante**: mandar
> `--protectResolution=off` e reler continua dando `true`. Pior, `=false` é
> rejeitado com `Failed.` enquanto `=off` e `=0` passam calados, então dá para
> desligar a proteção achando que não desligou. Quem responde de verdade é o
> plist:
>
> ```sh
> defaults read pro.betterdisplay.BetterDisplay | grep protectResolution
> ```
> ```
> "protectResolution@Display:3" = "1920x1200 HiDPI";   # ARZOPA
> "protectResolution@Display:4" = "3008x1692 HiDPI";   # Alienware
> "protectResolution@Display:5" = "1440x2560 LoDPI";   # Mancer
> ```
>
> Não existe booleano de liga/desliga: **a presença da string é o estado
> ligado**, e ela guarda o modo fixado. O `@Display:N` é o `tagID` do
> BetterDisplay, **não** o `displayID` — os dois se cruzam entre painéis. Para
> saber quem é quem, `betterdisplaycli get --identifiers`, ou ache o built-in
> pelo `builtIn@Display:N = 1`.
>
> O mesmo vale para o **refresh rate**: `--protectRefreshRate=on` fixa o valor
> atual e grava `protectRefreshRate@Display:4 = 240Hz`. Vale ligar junto com a
> resolução — é o mesmo tipo de reversão no reconectar.

> **Brilho: o Alienware aceita DDC, o Mancer não.** Em clamshell as teclas de
> brilho não têm mais a tela do MacBook para controlar, e o que resolve é o
> BetterDisplay falar DDC com o monitor. Testado nos dois, em 2026-09-08:
>
> ```sh
> betterdisplaycli get --namelike=AW3225QF --ddc --vcp=luminance   # -> 100
> betterdisplaycli get --namelike=TE-3217G --ddc --vcp=luminance   # -> Failed.
> ```
>
> No Alienware a escrita também funciona (`set --hardwareBrightness=70%` e a
> leitura DDC volta `70`), e depois disso o plist ganha um controlador que antes
> não existia: `value@hardwareBrightness-DDCController@Display:4`. É brilho de
> **backlight** de verdade, não o overlay escuro do software dimming. O Mancer
> fica só com `softwareBrightness`, que lava a imagem em vez de escurecê-la.
>
> ⚠️ **`--hardwareBrightness=100%` não devolve exatamente 100.** Voltou `94` na
> leitura DDC — a escala do BetterDisplay não mapeia 1:1 no VCP. Para um valor
> exato, escreva o VCP direto:
>
> ```sh
> betterdisplaycli set --namelike=AW3225QF --ddc --vcp=luminance --value=100
> ```
>
> **Fazer as teclas F1/F2 controlarem o Alienware é passo de interface.** Não há
> feature de CLI para isso (conferido no `betterdisplaycli help` inteiro, 313
> linhas) e não existe chave no plist até ser ligado na primeira vez — é o painel
> **Settings → Keyboard** do app. O DDC já está pronto embaixo; falta só mandar o
> app interceptar as teclas.

> **Trocar o monitor principal também tem CLI**, e é mais rápido que o Arrange…:
> `betterdisplaycli set --namelike=AW3225QF --main=on`. Desfazer não existe —
> só designando outra tela como principal.

> **Com duas telas, a coluna C engole janelas.** Ela colapsa na mesma tela da
> coluna B, então os ws 3/6/9 disputam o monitor principal com os ws 2/5/8 — e o
> `Alt+1..3` termina mostrando a coluna B. Uma janela que caia na coluna C
> simplesmente some de vista, e parece que os monitores pararam de trocar juntos.
>
> Só chega lá app **sem regra**, que nasce onde o foco estiver. Se um app sumir
> assim, o conserto não é mexer nas colunas — é dar uma regra a ele em
> `on-window-detected`. Foi o caso do Hoppscotch, hoje fixado no ws 1, e do
> Notion, fixado no ws 5 em 2026-09-10.

> **`on-window-detected` dispara em janela que NASCE, e desminimizar não é
> nascer.** Descoberto testando a regra nova do Notion: ele estava rodando com a
> única janela minimizada — invisível para o `aerospace list-windows`, porque
> janela minimizada sai da árvore —, e o `open -a Notion` **restaurou** aquela
> janela em vez de criar uma. Ela voltou no workspace onde o foco estava, não no
> ws 5, e a regra pareceu quebrada. Depois de um `quit` de verdade e um relaunch,
> foi para o ws 5 na primeira tentativa.
>
> Vale para o `Alt+Shift+M` também, que é exatamente essa restauração: ele traz a
> janela de volta, mas não a re-roteia. Se ela voltar no lugar errado, é
> `Alt+Shift+<n>` para empurrar — não é a regra que falhou.

> **Qual tela é a principal decide onde o trabalho acontece**, porque a coluna B
> é `main` e a A é `secondary`. Trocar o monitor principal inverte as duas
> colunas automaticamente, sem editar nada — foi assim que o ARZOPA passou de
> painel lateral a tela de trabalho, e é o que faz o mesmo `layout-2mon.toml`
> servir a mesa e a rua.
>
> Troca-se o principal em System Settings → Displays → **Arrange…**, arrastando
> a barra branca. Não é `defaults write`, então o `defaults.sh` não reproduz.
>
> **Com duas telas nenhum monitor é nomeado**, e é de propósito: `^arzopa$` na
> coluna A colidiria com a coluna B no instante em que o ARZOPA virasse
> principal, e os workspaces empilhariam numa tela só. Já aconteceu duas vezes.
>
> **Com três telas um nome é inevitável.** `main` e `secondary` particionam duas
> telas exatamente, mas na terceira o `secondary` casa com *duas* e não sabe
> separar a coluna A da C. A regra que mantém isso seguro: **só nomear tela que
> nunca é a principal**. Por isso o `layout-3mon.toml` nomeia o Mancer (coluna
> A) e o `built-in` (coluna C), e deixa o Alienware sem nome — o que faz dele o
> principal designado. Mover a menu bar para outra tela exige mover os nomes
> junto.
>
> Visto ao vivo em 2026-09-08, nas duas pontas. Com a tampa aberta e o MacBook
> ainda principal, os ws 2/5/8 **e** 3/6/9 caíram todos no built-in e o
> Alienware ficou sem workspace nenhum — exatamente a colisão descrita acima.
> Fechada a tampa e rodado o `apply-layout.py`, o par ficou limpo:
>
> ```
> 1,3,5 -> TE-3217G     (coluna A, retrato)
> 2,4,6 -> AW3225QF     (coluna B, principal)
> ```
>
> O `layout-2mon.toml` não precisou de **uma linha** editada para o hardware
> novo. É o retorno de ter escrito as colunas por papel.

Abrir um app **te leva junto** até o workspace dele
(`--focus-follows-window` em todas as regras). Sem isso, clicar no Dock movia a
janela para um workspace possivelmente invisível e você ficava olhando para a
tela antiga achando que o app não abriu.

Duas consequências disso, ambas esperadas:

Abrir um app **quebra o trio** — só a tela daquele workspace muda, as outras
duas ficam onde estavam. Um `Alt+1..3` depois re-sincroniza as três.

No **login**, com vários apps restaurando de uma vez, cada um que casa com uma
regra puxa o foco quando sua janela aparece. Os primeiros segundos pulam entre
telas antes de assentar no último que subiu.

A regra só dispara quando a janela **nasce** — app já aberto não se muda sozinho
depois de um `reload-config`. Use `Alt+Shift+<n>` uma vez, ou feche e reabra.

> **Trocar de layout é a exceção, desde 2026-09-08.** O `apply-layout.py`
> re-aloja as janelas já abertas quando — e **somente quando** — o layout muda de
> fato. Sem isso, abrir ou fechar a tampa deixava cada app no workspace que o
> layout *anterior* tinha dado: o Safari aberto com a tampa levantada ia para o
> ws 8 pela regra do `3mon`, e fechar a tampa o deixava lá — num workspace que o
> `2mon` nem sequer mapeia tecla, então **invisível e inalcançável pelo teclado**.
> Parecia janela que "não expande".
>
> O gatilho é a mudança de layout, não a execução do script: rodar
> `apply-layout.py` de novo sem trocar de layout não mexe em nada, para não
> desfazer o que você posicionou à mão. Ele imprime o que moveu:
>
> ```
> apply-layout: com.apple.Safari 6 -> 8
> ```
>
> `--no-rehome` desliga o comportamento numa execução. E o re-alojamento não usa
> `--focus-follows-window` de propósito: as regras usam para abrir um app te
> levar junto, mas aqui uma dúzia de janelas pode mover de uma vez, e seguir cada
> uma deixaria o foco em lugar aleatório.

> **Fechar saiu do `Alt+W` em 2026-09-10.** O Option é a tecla de acento deste
> teclado, então escrever português é morar em cima do modificador que fecha
> janela — e como o fechar leva o app junto (bloco abaixo), um escorregão em
> "ação" derrubava a sessão inteira. Casar com o `win+w` do GlazeWM não vale
> isso.
>
> **O `Ctrl+W` custa mais caro do que o `Alt+W` que ele substitui**, e é bom
> saber disso antes de estranhar: o AeroSpace captura `Ctrl+W` globalmente do
> mesmo jeito que captura `Alt`, então o zsh perde o `backward-kill-word` (o
> `Ctrl+W` que existe em todo shell) e o Neovim perde o `Ctrl+W`, prefixo dos
> comandos de janela. Se essa metade doer mais que a outra, o `Ctrl+Shift+W` não
> é de ninguém e a troca é uma linha em `aerospace.base.toml`.
>
> O `Alt+M` continua cobrando o `copy-prev-shell-word` do zsh. O `Alt+.`
> (inserir último argumento), o realmente usado no dia a dia, segue intacto.

> **Minimizar tira a janela da árvore.** Ela passa a viver no Dock, o AeroSpace
> deixa de enxergá-la e o `Alt` + `` ` `` não a encontra, porque ele só percorre
> o que ainda está na árvore. O `Alt+Shift+M` é a volta (bloco abaixo). Se a
> intenção era só tirar a janela da frente, `Alt+Shift+F` (soltar como floating)
> costuma ser o que você queria.

> ⚠️ **"Dei `Cmd+Tab`, escolhi o app e nada aconteceu."** Não é o AeroSpace
> comendo a tecla: o `Cmd+Tab` do macOS ativa um **app**, nunca uma janela. Se
> o app não tem janela para mostrar, ele vira frontmost e a tela não muda. O
> ícone do Dock funciona porque um clique nele manda um evento de *reopen*, que
> é outra coisa — pede ao app que restaure ou crie uma janela.
>
> Dois estados chegam nisso, e um app pode estar nos dois:
>
> - **janelas minimizadas** — o `Cmd+Tab` só restaura se você segurar `⌥` antes
>   de soltar o `⌘`. Esse truque é nativo e funciona sem nada instalado.
> - **nenhuma janela** — um `Cmd+W` na última deixa o app vivo e vazio. Foi
>   assim que Finder e Claude foram pegos no diagnóstico. O `Ctrl+W` não produz
>   esse estado: o `--quit-if-last-window` leva o app junto.
>
> `Alt+Shift+M` resolve os dois com uma chamada só: `open -b <bundle-id>`, o
> mesmo evento de *reopen* do clique no Dock. O tratamento padrão do AppKit para
> ele é exatamente o que se quer — sem janela visível, desminimiza a última, ou
> cria uma se não houver nenhuma. Testado em Spotify, Slack e Teams.
>
> É um script (`macos/aerospace/raise-frontmost.sh`) só porque o AeroSpace não
> tem comando para disparar isso. **Ele não toca no Accessibility de propósito:**
> a primeira versão limpava o `AXMinimized` janela a janela pelo System Events,
> funcionava, e deixava a tecla tão confiável quanto uma permissão que a gente
> viu cair sozinha no meio da sessão (`osascript is not allowed assistive
> access`, -25211). `lsappinfo` e `open` passam pelo LaunchServices, que não pede
> nada.
>
> Onde a janela reaparece depende do caso: quando o `open -b` **cria** janela, a
> regra de `on-window-detected` dispara e ela vai para o workspace de sempre;
> quando só desminimiza, nada é criado, a regra fica calada, e ela já voltou
> tanto no workspace da regra quanto no que estava visível. `Alt+Shift+<n>` move
> se cair no lugar errado.

> Vale para o AltTab também: janela **minimizada** ele não lista, porque o que
> está no Dock não é janela que ele possa oferecer. Nesse caso o `Alt+Shift+M` é
> o único caminho de volta.

> **`Ctrl+W` encerra o app junto com a última janela** (`--quit-if-last-window`),
> como no Windows e no Omarchy — e ao contrário da convenção do macOS, onde o
> app fica vivo com a menu bar vazia. Foi escolha deliberada: app que você não
> vê mas continua rodando é exatamente o estado que um tiling WM existe para
> evitar.
>
> O custo aparece nos apps cuja janela **é** a sessão: a última janela do
> Ghostty leva os shells junto, e a última do browser encerra o browser. Quando
> você quiser fechar só a janela e manter o app, `Cmd+W` continua ali.

> ⚠️ **O AeroSpace captura `Alt+<tecla>` globalmente**, antes do app em foco. Por
> isso `Alt+C` **não** está mapeado — é do fzf. Confira o arquivo antes de
> adicionar binding novo.
>
> Vale igual para o `Ctrl+W`, o único binding aqui fora do `Alt`. Que fique o
> único: o `Ctrl` é onde o terminal guarda tudo, e o `Alt` ao menos tinha teclas
> sobrando.

> **Monitor principal.** O display "principal" do macOS é o que tem a menu bar,
> e por definição é o que está na origem `(0,0)`. Na mesa é o **AW3225QF**, não
> a tela do MacBook; na rua é o **ARZOPA**. Troca-se em System Settings →
> Displays → **Arrange…**, arrastando a barra branca para o monitor desejado —
> as posições relativas das outras telas são preservadas. Não é um
> `defaults write`, então o `defaults.sh` não reproduz isso: é passo manual em
> máquina nova.
>
> O macOS guarda o arranjo **por configuração de telas**, e clamshell é uma
> configuração diferente de tampa aberta — arrastar a barra branca com a tampa
> aberta não decide nada sobre o modo fechado.
>
> Na prática, fechar a tampa **já colocou a menu bar no Alienware sozinho**
> (verificado em 2026-09-08): sem o built-in, o macOS promove uma das externas e
> escolheu a de maior resolução. Não precisou de Arrange… nenhum. Só volte lá se
> ele promover a errada.

> ⚠️ **"Displays have separate Spaces"** precisa estar desligado — com ele ligado
> o macOS reposiciona janelas por conta própria e briga com qualquer tiler. O
> `defaults.sh` já escreve isso (`com.apple.spaces spans-displays`), mas só vale
> depois de um **logout**; a chave é lida no login.

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
| **Screen & System Audio Recording** | AltTab | lista as janelas, mas sem título nem miniatura |
| **Full Disk Access** | Terminal/Ghostty, backup | "Operation not permitted" em `~/Library`, Mail, etc. |
| **Input Monitoring** | Karabiner | teclas não são capturadas |

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
| Alt+Tab | **AeroSpace** — `Alt` + `` ` `` cicla as janelas do workspace; `Cmd+Tab` segue o switcher de apps do macOS |
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
