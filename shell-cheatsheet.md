# 🐚 Shell Cheat-Sheet (zsh no WSL · PowerShell no Windows)

Tudo que está instalado nos dois shells, o que cada coisa resolve, e como extrair
o máximo. Mesma regra do Vim: **uma ferramenta nova por semana**, não todas hoje.

---

## 1. O mapa mental

Não são "30 ferramentas soltas". São **6 camadas**, e cada uma resolve um
problema que você tem todo dia:

| Camada | Problema que resolve | zsh (WSL) | PowerShell |
|---|---|---|---|
| **Prompt** | "onde eu estou, como está o git?" | Powerlevel10k | oh-my-posh |
| **Digitação** | "já digitei isso antes" | zsh-autosuggestions + fast-syntax-highlighting | PSReadLine |
| **Histórico** | "qual era aquele comando?" | atuin | PSReadLine (ListView) |
| **Navegação** | "cadê aquela pasta?" | zoxide + fzf | zoxide + PSFzf |
| **Busca** | "onde está esse texto/arquivo?" | ripgrep + fd + fzf | ripgrep + fd + fzf |
| **Leitura** | "me mostra isso de forma legível" | eza + bat | eza + bat + Terminal-Icons |

Os dois shells são **propositalmente diferentes na cor**: WSL é Tokyo Night com
UbuntuSansMono NF, PowerShell é Kanagawa com JetBrainsMono NF. Bateu o olho,
sabe onde está.

---

## 2. Os substitutos modernos

Você já usa sem perceber — os aliases apontam para eles:

| Você digita | Roda de verdade | Ganho |
|---|---|---|
| `ls` | `eza --icons --group-directories-first` | ícones, pastas primeiro |
| `ll` | `eza -lah --icons` | detalhado, com ocultos |
| `lt` | `eza --tree --level=2` | árvore |
| `cat` | `bat --paging=never` | syntax highlight + números de linha |
| `z` | `zoxide` | pula pra pasta por frequência |

**O pulo do gato do `eza`** — ele lê o git:

```sh
eza -l --git            # coluna com o status git de cada arquivo
eza -l --sort=modified  # mais recentes por último
eza -la --total-size    # tamanho real das pastas
lt3                     # (só no PowerShell) árvore nível 3
```

**O pulo do gato do `bat`**:

```sh
bat -A arquivo          # mostra espaços/tabs/CRLF invisíveis — ouro pra debug
bat -r 40:60 arquivo    # só as linhas 40 a 60
bat -l json < resposta  # força a linguagem quando não há extensão
bat --diff arquivo      # só as linhas alteradas no git
```

> `cat` está aliasado com `--paging=never` pra continuar servindo em pipes.
> Precisa do pager de verdade? Chame `bat` direto.

---

## 3. Navegação: pare de digitar `cd`

O **zoxide** aprende as pastas que você visita e ordena por *frecency*
(frequência + recência):

```sh
z workspace       # pula pra pasta mais "quente" que casa com "workspace"
z res work        # múltiplos termos, casa caminho inteiro
zi                # modo interativo: escolhe na lista com fzf
z -                # volta pra anterior (como cd -)
```

Ele só conhece pastas onde você **já entrou** — nas primeiras semanas ainda vai
usar `cd`, e é normal. Depois disso `cd` some da sua vida.

No PowerShell existem ainda `..`, `...`, `....`, `~`, `proj` e `dl` como funções.

---

## 4. Histórico: o atuin é o pulo do gato do WSL

O **atuin** troca o histórico de texto do zsh por um banco SQLite: guarda
diretório, código de saída, duração e host de cada comando.

| Tecla | O que faz |
|---|---|
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | busca no histórico inteiro (UI de tela cheia) |
| <kbd>↑</kbd> | mesma busca, mas filtrada pelo que você já digitou |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> *(dentro da UI)* | cicla o filtro: global → host → sessão → **diretório** |
| <kbd>Tab</kbd> | edita o comando em vez de executar |
| <kbd>Esc</kbd> | sai sem rodar |

O filtro **por diretório** é o mais subestimado: entra no projeto, <kbd>Ctrl</kbd>+<kbd>R</kbd>,
cicla até "directory" e você vê só o que já rodou *ali*.

Fora da UI:

```sh
atuin stats               # seus comandos mais usados — revela o que virar alias
atuin search --limit 20 docker
atuin history list --cwd  # o que já rodou nesta pasta
```

No PowerShell o equivalente é o **PSReadLine em ListView**: a lista de sugestões
aparece abaixo do prompt enquanto você digita, alimentada pelo histórico **e**
pelo `CompletionPredictor` (que sugere a partir dos parâmetros do comando).

---

## 5. fzf: o filtro fuzzy que cola em tudo

| Tecla | zsh (WSL) | PowerShell |
|---|---|---|
| <kbd>Ctrl</kbd>+<kbd>T</kbd> | insere **arquivo** escolhido na linha | idem (PSFzf) |
| <kbd>Alt</kbd>+<kbd>C</kbd> | `cd` na **pasta** escolhida | — |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | (é do atuin) | histórico via PSFzf |

Dentro do fzf: <kbd>Tab</kbd> marca vários, <kbd>Ctrl</kbd>+<kbd>J</kbd>/<kbd>K</kbd> navega,
<kbd>Enter</kbd> confirma.

**O gatilho `**`** (só no zsh) é o recurso mais escondido — funciona depois de
qualquer comando:

```sh
nvim **<Tab>          # escolhe o arquivo numa lista fuzzy
cd **<Tab>            # escolhe a pasta
ssh **<Tab>           # escolhe entre os hosts conhecidos
export **<Tab>        # escolhe entre as variáveis de ambiente
kill <Tab>            # processo, e aqui nem precisa do **
```

E o combo que substitui meia hora de garimpo:

```sh
nvim $(fzf)                        # abre o arquivo escolhido
rg --files-with-matches TODO | fzf # só os arquivos que têm TODO
```

---

## 6. Busca de conteúdo: ripgrep e fd

```sh
rg "minhaFuncao"              # respeita .gitignore por padrão
rg -i erro                    # ignora maiúsculas
rg -w id                      # palavra inteira (não pega "identity")
rg -t ts "useState"           # só arquivos TypeScript
rg -l TODO                    # só os nomes dos arquivos
rg -C 3 "panic"               # 3 linhas de contexto em volta
rg --hidden --no-ignore senha # inclui ocultos e ignorados
```

```sh
fd relatorio                  # arquivo/pasta cujo nome contém "relatorio"
fd -e json                    # por extensão
fd -t d node_modules          # só diretórios
fd -e log -x rm               # executa um comando em cada resultado
```

`rg` procura **dentro** dos arquivos, `fd` procura **pelo nome**. Os dois já
alimentam o fzf por baixo (`FZF_DEFAULT_COMMAND` usa `fd`).

---

## 7. Lendo o prompt

**zsh (Powerlevel10k)** — uma linha só:

```
 nunes  ~/projects/workspace   main !  ❯
  └ usuário  └ diretório       └ git   └ ❯ verde = ok, vermelho = erro
```

- Bloco git **verde** = limpo · **amarelo** = alterações não commitadas
- À direita aparecem, quando fazem sentido: duração do último comando (só acima
  de **3 s**), jobs em background, versões do asdf, contexto do kubectl, perfil
  da AWS, virtualenv
- `p10k configure` abre o assistente e reescreve o `~/.p10k.zsh` do zero

**PowerShell (oh-my-posh)** — mesma ideia, mais blocos: SO, usuário, caminho,
git (com ahead/behind e stash), versões de node/python/go/rust/dotnet e tempo de
execução acima de 1 s. O *transient prompt* encolhe os prompts antigos para só
`❯` quando você roda o próximo comando, deixando o scroll limpo.

---

## 8. Digitação assistida

| | zsh | PowerShell |
|---|---|---|
| Sugestão em cinza | zsh-autosuggestions | PSReadLine InlineView |
| Aceitar tudo | <kbd>→</kbd> ou <kbd>End</kbd> | <kbd>Ctrl</kbd>+<kbd>→</kbd> |
| Aceitar uma palavra | <kbd>Ctrl</kbd>+<kbd>→</kbd> | <kbd>→</kbd> |
| Comando inválido em vermelho | fast-syntax-highlighting | PSReadLine |
| Completar com menu | <kbd>Tab</kbd> | <kbd>Tab</kbd> (MenuComplete) |

> Repare que <kbd>→</kbd> e <kbd>Ctrl</kbd>+<kbd>→</kbd> estão **trocados** entre os dois shells —
> é a única inconsistência real entre eles. Se incomodar, dá pra alinhar.

O **fast-syntax-highlighting** é um corretor ortográfico do shell: se o comando
ficou vermelho antes de você apertar Enter, ele não existe no PATH. Erro de
digitação vira feedback instantâneo em vez de "command not found".

---

## 9. Git

No zsh, o plugin `git` do Oh My Zsh dá ~200 aliases. Os que valem decorar:

| Alias | Comando |
|---|---|
| `gst` | `git status` |
| `ga` / `gaa` | `git add` / `git add --all` |
| `gcmsg "msg"` | `git commit -m` |
| `gd` / `gdca` | `git diff` / `git diff --cached` |
| `gco` / `gcb` | `git checkout` / `git checkout -b` |
| `gl` / `gp` | `git pull` / `git push` |
| `glo` | `git log --oneline --decorate` |
| `grbi` | `git rebase -i` |
| `gwip` | commit "work in progress" rápido |

No PowerShell as funções equivalentes estão no profile: `gs`, `ga`, `gaa`, `gc`,
`gca`, `gp`, `gpl`, `gco`, `gb`, `gd`, `gds`, `glog` (grafo colorido) e **`gcof`**
— que escolhe a branch com fzf, o melhor deles.

O `posh-git` completa nomes de branch no <kbd>Tab</kbd>, e o `gh` (GitHub CLI, no WSL)
resolve PRs sem abrir o navegador: `gh pr create`, `gh pr list`, `gh pr checks`.

---

## 10. Funções exclusivas do PowerShell

Coisas que só existem no profile do Windows e são fáceis de esquecer:

| Função | Faz |
|---|---|
| `port 3000` | mostra **qual processo** está usando a porta |
| `killp node` | mata processo pelo nome |
| `du` | peso de cada pasta do diretório atual, ordenado |
| `myip` | seu IP público |
| `timeit { ... }` | cronometra um bloco |
| `ff "texto"` | busca conteúdo (usa `rg`) |
| `mkcd pasta` | cria a pasta **e** entra nela |
| `e` | abre a pasta atual no Explorer |
| `which cmd` | de onde vem o comando |
| `reload` / `pro` | recarrega / edita o profile |

---

## 11. asdf (só no WSL)

Gerenciador de versões único para todas as linguagens — substitui nvm, sdkman,
pyenv e afins. Hoje ele está instalado mas **sem nenhum plugin**:

```sh
asdf plugin add nodejs        # ou java, python, golang, dotnet
asdf install nodejs latest
asdf set nodejs latest        # global
asdf set -u nodejs 20.11.0    # só neste projeto (cria .tool-versions)
```

O arquivo `.tool-versions` vai pro repositório, e quem clonar roda `asdf install`
e fica com as versões exatas. Assim que houver um plugin instalado, a versão da
linguagem aparece automaticamente no lado direito do prompt.

---

## 12. Roteiro sugerido

Uma por semana, na ordem de retorno sobre esforço:

1. **`z` em vez de `cd`** — o ganho diário mais imediato
2. **<kbd>Ctrl</kbd>+<kbd>R</kbd> com o filtro por diretório** — para de reescrever comando longo
3. **`rg` em vez de abrir o editor pra procurar** — segundos em vez de minutos
4. **<kbd>Ctrl</kbd>+<kbd>T</kbd> e `**<Tab>`** — nunca mais digite caminho inteiro
5. **`gst`/`gd`/`gcmsg`** — o loop do git sem escrever "git"
6. **`atuin stats`** — descobre seus próprios padrões e vira aliases novos

---

## 13. Buracos conhecidos

Coisas que o setup **não** tem hoje, se um dia fizerem falta:

- **`docker`** não está instalado no WSL, mas os aliases `dcu`/`dcd` existem no `.zshrc`
- **`jq`** existe no Windows, não no WSL (`sudo nala install jq`)
- **`delta`** (diff do git colorido lado a lado) não está em nenhum dos dois
- **`FZF_DEFAULT_OPTS`** está configurado só no PowerShell — no zsh o fzf usa o
  visual padrão, sem as cores Tokyo Night e sem preview
- **atuin sem sync** — ele suporta sincronizar histórico criptografado entre
  máquinas (`atuin register`, `atuin sync`), o que uniria WSL e outras máquinas
