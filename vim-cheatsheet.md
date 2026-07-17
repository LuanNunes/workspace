# 🎯 Vim Cheat-Sheet (Neovim · IdeaVim · VS Code)

Configuração pessoal — `<leader>` = **Espaço**, `jk` = **Esc** nos três editores.
Imprima, deixe do lado do monitor, e consulte sem culpa. Um movimento novo por semana.

---

## 1. A ideia que destrava tudo: Vim é uma *linguagem*

Você **compõe** comandos: `verbo` + `movimento`/`objeto de texto`.
Aprende ~8 verbos e ~15 movimentos, e eles se **multiplicam**.

```
   verbo        objeto/movimento         resultado
   ─────        ────────────────         ─────────
   d (delete)   w  (palavra)         →   dw    apaga a palavra
   c (change)   i) (dentro de "()")  →   ci)   troca o que está entre ( )
   y (yank)     2j (2 linhas abaixo) →   y2j   copia 2 linhas
   > (indent)   ap (um parágrafo)    →   >ap   indenta o parágrafo
```

Você nunca "decora" `ci"`, `dap`, `yi{` — eles **caem da gramática**.

---

## 2. Modos

| Modo | Entra com | Pra que serve |
|------|-----------|---------------|
| **Normal** | `Esc` ou `jk` | navegar e operar (é a "casa" — fique aqui) |
| **Insert** | `i a o I A O` | digitar texto |
| **Visual** | `v` `V` `Ctrl-v` | selecionar (char / linha / bloco) |
| **Command** | `:` | comandos (`:w`, `:q`, `:s/...`) |

> **Regra de ouro:** parou de digitar → `jk` (volta pro Normal). Setas são muleta; evite.

Entrar no Insert: `i` antes do cursor · `a` depois · `I` início da linha · `A` fim ·
`o` linha nova abaixo · `O` acima.

---

## 3. Movimentos (onde o cursor vai)

| Tecla | Vai para |
|-------|----------|
| `h j k l` | ← ↓ ↑ → |
| `w` / `b` | próxima / anterior início de palavra |
| `e` | fim da palavra |
| `0` / `^` / `$` | início da linha / 1º caractere / fim |
| `gg` / `G` | topo / fim do arquivo |
| `{n}G` ou `{n}gg` | vai pra linha `n` (use os números relativos!) |
| `{` / `}` | parágrafo anterior / próximo |
| `Ctrl-d` / `Ctrl-u` | meia tela ↓ / ↑ |
| `f{c}` / `t{c}` | pula pro caractere `c` (`f`=em cima, `t`=antes) na linha |
| `;` / `,` | repete o último `f`/`t` (frente / trás) |
| `%` | pula pro par `() {} []` correspondente |
| `*` / `#` | busca a palavra sob o cursor (frente / trás) |

**Contagem:** quase tudo aceita número antes → `5j` desce 5, `3w` avança 3 palavras.

---

## 4. Verbos / operadores (o que fazer)

| Tecla | Ação |
|-------|------|
| `d` | delete (recorta) |
| `c` | change (apaga e entra em Insert) |
| `y` | yank (copia) |
| `p` / `P` | paste depois / antes |
| `x` | apaga 1 caractere |
| `r{c}` | substitui 1 caractere por `c` |
| `>` / `<` | indenta / desindenta |
| `~` | inverte maiúscula/minúscula |

**Dobrou = linha inteira:** `dd` apaga linha · `yy` copia linha · `cc` troca linha · `>>` indenta.

**Essenciais de ouro:**
- `.` → **repete** a última mudança (o comando mais poderoso do Vim)
- `u` → desfaz · `Ctrl-r` → refaz
- `ciw` → troca a palavra inteira (não importa onde o cursor está nela)

---

## 5. Objetos de texto (combine com `d` `c` `y` `v`)

| Objeto | Significa | Exemplo |
|--------|-----------|---------|
| `iw` / `aw` | palavra (inner / a-word com espaço) | `diw` apaga palavra |
| `i"` `i'` `` i` `` | dentro de aspas | `ci"` troca o texto entre "" |
| `i(` `i{` `i[` | dentro de parênteses/chaves/colchetes | `yi{` copia o bloco |
| `ip` / `ap` | parágrafo | `dap` apaga o parágrafo |
| `it` / `at` | tag HTML/XML | `cit` troca o conteúdo da tag |

`i` = *inner* (só o conteúdo) · `a` = *around* (inclui as bordas/espaço).

---

## 6. Busca e substituição

| Comando | Faz |
|---------|-----|
| `/texto` `Enter` | busca pra frente · `n`/`N` = próximo/anterior |
| `?texto` | busca pra trás |
| `<leader>nh` | **limpa o destaque** da busca (configuramos) |
| `:s/velho/novo/` | substitui na linha atual |
| `:%s/velho/novo/g` | substitui no arquivo todo |
| `:%s/velho/novo/gc` | idem, **confirmando** cada um |

---

## 7. ⭐ Seus atalhos `<leader>` (Espaço) — iguais nos 3 editores

Aperte **Espaço** e (no IdeaVim/Neovim com Which-Key) o menu aparece sozinho.

### Buscar / navegar
| Atalho | Ação |
|--------|------|
| `<Space> f f` (ou `Ctrl-p`) | procurar **arquivo** |
| `<Space> f g` | **grep** no projeto (buscar texto) |
| `<Space> f b` | **buffers** / abas abertas |
| `<Space> f s` | ir a **símbolo** |
| `<Space> f a` | paleta de **ações**/comandos |

### Código (nos IDEs / VS Code)
| Atalho | Ação |
|--------|------|
| `g d` | ir para **definição** |
| `g r` | **referências** (usos) |
| `g i` | **implementação** |
| `K` | ver **documentação** (hover) |
| `] e` / `[ e` | próximo / anterior **erro** |

### Refatorar / rodar (IdeaVim / VS Code)
| Atalho | Ação |
|--------|------|
| `<Space> r n` | **renomear** símbolo |
| `<Space> c a` | **code actions** / quick fix |
| `<Space> r f` | **formatar** arquivo |
| `<Space> r r` / `<Space> r d` | **rodar** / **debug** (JetBrains) |
| `<Space> b` | breakpoint (JetBrains) |

### Janelas / painéis
| Atalho | Ação |
|--------|------|
| `<Space> e` | explorer / árvore de arquivos |
| `<Space> t` | terminal |
| `<Space> g` | painel de git |
| `<Space> s v` / `s h` | split vertical / horizontal (JetBrains) |
| `Ctrl-h/j/k/l` | mover entre splits (JetBrains) |

> **Neovim** é mais enxuto (`ff`, `fg`, `fb`, `fh` ajuda, `fk` ver atalhos).
> Os IDEs têm os extras de navegação/refactor acima.

---

## 8. Surround & comentários (plugins já ativos)

**Surround** (`surround`):
- `cs"'` → troca `"` por `'`
- `ds"` → remove as `"`
- `ysiw)` → envolve a palavra com `()`
- `yss"` → envolve a linha toda com `"`

**Comentários** (`commentary` no Vim/IdeaVim · nativo no VS Code):
- `gcc` → comenta/descomenta a linha
- `gc{movimento}` → `gcap` comenta o parágrafo

---

## 9. Salvar / sair (o clássico "como saio daqui?!")

| Comando | Faz |
|---------|-----|
| `:w` | salva |
| `:q` | sai (`:q!` descarta mudanças) |
| `:wq` ou `ZZ` | salva e sai |
| `:qa` | sai de tudo |

---

## 10. Seu plano de 2 semanas

1. **Hoje:** rode `vimtutor` no terminal (30 min, prático).
2. **Semana 1:** viva no Normal mode. Use só `h j k l`, `w b`, `i a o`, `dd`, `dw`, `u`, `.`
3. **Semana 2:** adicione objetos de texto (`ciw`, `ci"`, `dap`) e `f`/`t`.
4. **Depois:** um truque novo por semana — `*`, macros (`q`), `Ctrl-v` bloco…

Travou? `Esc`/`jk` e respira. O mouse ainda está aí. Você não pode quebrar nada. 🚀
