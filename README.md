# bw-connect

Desbloqueie o cofre do [Bitwarden](https://bitwarden.com/) no terminal com um único comando e deixe a sessão pronta para uso — por você, por scripts e pelo [Claude Code](https://claude.com/claude-code).

Sem copiar/colar token, sem senha no histórico do shell, sem segredo gravado em disco.

```console
$ bw-connect
? Master password: [hidden]
✅ Bitwarden conectado
```

## Índice

- [O que ele resolve](#-o-que-ele-resolve)
- [Como funciona](#-como-funciona)
- [O que tem neste repositório](#-o-que-tem-neste-repositório)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação](#-instalação)
- [Uso no dia a dia](#-uso-no-dia-a-dia)
- [Uso com o Claude Code](#-uso-com-o-claude-code)
- [Segurança](#-segurança)
- [Solução de problemas](#-solução-de-problemas)
- [Desinstalação](#-desinstalação)

## 🎯 O que ele resolve

O fluxo padrão do Bitwarden CLI é incômodo:

```bash
# Sem bw-connect 😩
bw unlock
# → imprime um export BW_SESSION="…token gigante…" para você
#   copiar e colar manualmente em cada terminal
```

O `bw-connect` transforma isso em um comando só: desbloqueia o cofre, captura o token de sessão via `--raw` e o grava em `/tmp/.bw_session` com permissão `600`. Qualquer processo seu (outros terminais, scripts, Claude Code) passa a usar a mesma sessão.

## ⚙️ Como funciona

```
┌─────────────┐   senha (prompt oculto)   ┌──────────────┐
│  bw-connect │ ────────────────────────► │  bw unlock   │
└─────────────┘                           │    --raw     │
       │                                  └──────┬───────┘
       │              token de sessão            │
       │ ◄───────────────────────────────────────┘
       ▼
  /tmp/.bw_session  (chmod 600 — só seu usuário lê)
```

Passo a passo do script ([`bw-connect`](bw-connect)):

1. **Verifica o login** — `bw status`; se a conta estiver deslogada, orienta a rodar `bw login` primeiro
2. **Desbloqueia** — `bw unlock --raw` pede a senha master em prompt **oculto** (o prompt vai para stderr; stdout contém apenas o token)
3. **Persiste a sessão** — grava o token em `/tmp/.bw_session`, aplica `chmod 600` e descarta a variável da memória

A senha master **nunca** toca o disco nem aparece em nenhum output. Só o token de sessão (temporário e revogável) é gravado — e em `/tmp`, que é apagado a cada reinicialização.

## 📦 O que tem neste repositório

| Arquivo | O que é |
|---|---|
| [`bw-connect`](bw-connect) | O script em si (~35 linhas de bash) |
| [`install.sh`](install.sh) | Instalador automático |
| `README.md` | Este guia |

**Este repositório NÃO contém nenhuma senha, token ou segredo.** Toda a autenticação acontece só na hora do uso, na máquina de destino.

## ✅ Pré-requisitos

| Dependência | Para quê | Como instalar |
|---|---|---|
| [Bitwarden CLI](https://bitwarden.com/help/cli/) (`bw`) | Acesso ao cofre | `npm install -g @bitwarden/cli` ou `sudo snap install bw` |
| `python3` | Ler o JSON do `bw status` | `sudo apt install python3` (já vem na maioria das distros) |
| `bash` | Rodar o script | Padrão em Linux/macOS |

> ⚠️ Instale o `bw` **somente de fontes oficiais** — npm, snap ou o [binário oficial](https://bitwarden.com/help/cli/#download-and-install).

O `install.sh` verifica tudo isso e mostra as instruções se algo faltar.

## 🚀 Instalação

### 1. Clone o repositório

```bash
git clone git@github.com:geraldoschuetze/bw-connect-setup.git
cd bw-connect-setup
```

*(Sem acesso ao repo? A pasta também pode ser levada por pendrive ou drive — não há segredos nela.)*

### 2. Rode o instalador

```bash
bash install.sh
```

O instalador faz exatamente três coisas (e nada além disso):

1. Verifica os pré-requisitos (`bw`, `python3`) — se faltar algo, mostra como instalar e para
2. Copia o script para `~/.local/bin/bw-connect` (com `install -m 755`)
3. Garante que `~/.local/bin` está no `PATH` (adiciona ao `~/.bashrc`/`~/.zshrc` se preciso)

### 3. Login (só na primeira vez em cada máquina)

```bash
bw login
```

Entre com seu e-mail e senha master do Bitwarden. Isso fica salvo pelo próprio `bw` — não precisa repetir.

## 💻 Uso no dia a dia

```bash
bw-connect
```

Digite a senha master quando pedir (fica **oculta** enquanto você digita). Ao ver `✅ Bitwarden conectado`, o cofre está desbloqueado e a sessão salva.

A partir daí, em qualquer terminal:

```bash
BW_SESSION=$(cat /tmp/.bw_session) bw get password "nome-do-item"
BW_SESSION=$(cat /tmp/.bw_session) bw list items --search "postgres"
```

Para encerrar a sessão manualmente:

```bash
bw lock && rm -f /tmp/.bw_session
```

A sessão também morre sozinha ao reiniciar o computador (o `/tmp` é limpo no boot).

## 🤖 Uso com o Claude Code

Depois de rodar `bw-connect` num terminal comum, o Claude Code consegue usar a sessão nos comandos `bw`:

```bash
BW_SESSION=$(cat /tmp/.bw_session) bw get password "nome-do-item"
```

Se o cofre travar no meio de uma sessão do Claude, rode `! bw-connect` direto no prompt do Claude — o `!` executa o comando no seu terminal e mostra o resultado na conversa.

## 🔒 Segurança

**Como o script protege suas credenciais:**

- A senha master é digitada em prompt oculto e **nunca é gravada em disco nem aparece em nenhum output**
- O token de sessão fica em `/tmp/.bw_session` com permissão `600` (só o seu usuário lê)
- O `/tmp` é apagado a cada reinicialização — a sessão morre junto
- O token é revogável a qualquer momento com `bw lock`

**Nunca faça:**

- ❌ Copiar `/tmp/.bw_session` para outro computador ou para dentro deste repositório — ele é um token de acesso ao seu cofre
- ❌ Passar a senha master por argumento de linha de comando (ficaria no histórico do shell)
- ❌ Instalar o `bw` de fontes não oficiais

## 🩺 Solução de problemas

### `⛔ Você não está logado no Bitwarden`

Você ainda não fez o login nesta máquina (ou fez logout). Rode:

```bash
bw login
```

### `❌ Falha ao desbloquear o Bitwarden (senha incorreta?)`

A senha master digitada está errada — rode `bw-connect` de novo. Se persistir, confira em qual servidor você está logado:

```bash
bw status
# "serverUrl" deve apontar para o servidor certo (bitwarden.com ou self-hosted)
```

### `bw-connect: command not found`

O `~/.local/bin` ainda não está no `PATH` deste terminal. Abra um **novo** terminal (o instalador atualiza o `~/.bashrc`, que só é lido em sessões novas) ou rode:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Comandos `bw` pedem senha mesmo depois do `bw-connect`

Falta passar a sessão pro comando:

```bash
BW_SESSION=$(cat /tmp/.bw_session) bw get password "item"
```

Ou exporte uma vez no terminal atual: `export BW_SESSION=$(cat /tmp/.bw_session)`

### Sessão expirou / cofre travou de novo

Normal — o Bitwarden trava o cofre após timeout ou reinicialização. Basta rodar `bw-connect` de novo.

## 🗑️ Desinstalação

```bash
rm -f ~/.local/bin/bw-connect /tmp/.bw_session
bw lock   # opcional: trava o cofre
```
