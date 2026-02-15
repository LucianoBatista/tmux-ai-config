# Workflow: tmux + Claude Code + Git Worktrees

## Objetivo

Maximizar a capacidade de trabalhar em múltiplos projetos/branches simultaneamente, usando tmux como orquestrador, Claude Code como agente por contexto, e git worktrees para eliminar fricção de troca de branches.

---

## Arquitetura Geral

```
tmux session: "omr/main"          → worktree: ~/projects/omr-worktrees/main
tmux session: "omr/unit-test"     → worktree: ~/projects/omr-worktrees/unit-test
tmux session: "omr/new-reader"    → worktree: ~/projects/omr-worktrees/new-reader
tmux session: "essay/agent"       → worktree: ~/projects/essay-worktrees/agent
```

Cada sessão tmux contém:
- **Pane principal**: Claude Code rodando no diretório da worktree
- **Pane auxiliar (30%)**: shell livre para git, testes, logs

---

## Componentes do Plano

### 1. Git Worktrees com repo bare

Estrutura de diretórios por projeto:

```
~/projects/omr-system-worktrees/
├── .bare/                    # repo bare
├── main/                     # worktree: branch main
├── unit-test/                # worktree: branch unit-test
├── feat-new-reader/          # worktree: feature
└── fix-calibration-bug/      # worktree: hotfix
```

Setup inicial:

```bash
git clone --bare <repo-url> ~/projects/omr-system-worktrees/.bare
cd ~/projects/omr-system-worktrees/.bare
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch origin
git worktree add ../main main
```

### 2. Convenção de nomes para sessões tmux

Padrão: `projeto/branch` — facilita filtragem por fuzzy search.

```
omr/main
omr/unit-test
omr/new-reader
essay/agent
essay/redacoes
data/backend-loader
spike/hypothesis-testing
```

### 3. Script helper: criar worktree + sessão tmux

Script `~/bin/wt` que unifica a criação de worktree e sessão:

```bash
#!/bin/bash
# uso: wt omr feat/new-reader

REPO_BASE="$HOME/Documents/work"
PROJECT="$1"
BRANCH="$2"
BARE="$REPO_BASE/${PROJECT}-worktrees/.bare"
WT_DIR="$REPO_BASE/${PROJECT}-worktrees/$(basename $BRANCH)"
SESSION="${PROJECT}/$(basename $BRANCH)"

# Cria worktree se não existe
if [ ! -d "$WT_DIR" ]; then
    git -C "$BARE" worktree add "$WT_DIR" "$BRANCH" 2>/dev/null || \
    git -C "$BARE" worktree add "$WT_DIR" -b "$BRANCH" origin/main
fi

# Cria sessão tmux se não existe
if ! tmux has-session -t "=$SESSION" 2>/dev/null; then
    tmux new-session -d -s "$SESSION" -c "$WT_DIR"
    tmux send-keys -t "$SESSION" "claude" Enter
    tmux split-window -t "$SESSION" -h -p 30 -c "$WT_DIR"
fi

# Attach ou switch
if [ -z "$TMUX" ]; then
    tmux attach -t "$SESSION"
else
    tmux switch-client -t "$SESSION"
fi
```

### 4. Session switcher com fzf (substitui Ctrl-b s)

Fuzzy search com preview do conteúdo de cada sessão:

```bash
# ~/.tmux.conf
bind s display-popup -E -w 80% -h 70% '\
  bash ~/bin/tmux-switcher.sh | \
  fzf --ansi \
      --preview "tmux capture-pane -t {1} -p | tail -30" \
      --preview-window=right:50% \
      --delimiter=" " \
      --header "🔴 = aguardando aprovação | ⚙️ = trabalhando | ✅ = idle" | \
  awk "{print \$1}" | \
  xargs tmux switch-client -t'
```

### 5. Indicadores visuais de status do Claude Code

Script `~/bin/tmux-switcher.sh` que detecta o estado de cada sessão:

- 🔴 **WAITING** — Claude Code aguardando aprovação (tool use, file write, etc.)
- ⚙️ **WORKING** — Claude Code processando
- ✅ **IDLE** — Claude Code esperando input do usuário

Detecção via `tmux capture-pane` + grep nos padrões de output do Claude Code.

### 6. Contador de pendências na status bar

Script `~/bin/tmux-pending-count.sh` que mostra na barra do tmux quantas sessões aguardam aprovação:

```bash
# ~/.tmux.conf
set -g status-right '#(bash ~/bin/tmux-pending-count.sh) | %H:%M'
set -g status-interval 5
```

Resultado: `🔴 2 pending` aparece na barra quando há sessões esperando ação.

### 7. CLAUDE.md por worktree

Cada worktree pode ter um `CLAUDE.md` com contexto específico da branch, lido automaticamente pelo Claude Code ao iniciar:

```markdown
# CLAUDE.md
## Branch: feat/new-reader
- Objetivo: reimplementar o leitor usando pipeline modular
- Foco: src/reader/ e tests/reader/
- NÃO modificar: src/legacy_reader/
```

---

## Fluxo de Trabalho Diário

1. **Início do dia**: rodar script de bootstrap que levanta sessões tmux para cada worktree ativa
2. **Nova task**: `wt <projeto> <branch>` cria worktree + sessão + Claude Code
3. **Navegar**: `Ctrl-b s` abre fzf com status visual — ir direto na sessão 🔴
4. **Monitorar**: barra do tmux mostra `🔴 N pending` para aprovações pendentes
5. **Limpeza**: após merge, `git worktree remove` + `tmux kill-session`

---

## Próximos Passos

- [ ] Padronizar nomes das sessões existentes
- [ ] Instalar e configurar os scripts (`wt`, `tmux-switcher.sh`, `tmux-pending-count.sh`)
- [ ] Calibrar os patterns de grep para os prompts exatos do Claude Code v2.1
- [ ] Adicionar `CLAUDE.md` nos projetos principais
- [ ] Configurar `tmux-resurrect` para persistir layout entre reboots
