# bw-connect

[English](README.md) · **Português**

Desbloqueie o cofre do [Bitwarden](https://bitwarden.com/) no terminal com um único comando e deixe a sessão pronta para uso — por você, por scripts e pelo [Claude Code](https://claude.com/claude-code).

Sem copiar/colar token, sem senha no histórico do shell, sem segredo gravado em disco.

```console
$ bw-connect
? Master password: [hidden]
✅ Bitwarden conectado
   Sessão: /run/user/1000/bw_session
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

O `bw-connect` transforma isso em um comando só: desbloqueia o cofre, captura o token de sessão via `--raw` e o grava no seu diretório de runtime com permissão `600`. Qualquer processo seu (outros terminais, scripts, Claude Code) passa a usar a mesma sessão.

## ⚙️ Como funciona

```
┌─────────────┐   senha (prompt oculto)   ┌──────────────┐
│  bw-connect │ ────────────────────────► │  bw unlock   │
└─────────────┘                           │    --raw     │
       │                                  └──────┬───────┘
       │              token de sessão            │
       │ ◄───────────────────────────────────────┘
       ▼
  $XDG_RUNTIME_DIR/bw_session  (chmod 600, em diretório drwx------)
```

Passo a passo do script ([`bw-connect`](bw-connect)):

1. **Verifica o login** — `bw status`; se a conta estiver deslogada, orienta a rodar `bw login` primeiro
2. **Desbloqueia** — `bw unlock --raw` pede a senha master em prompt **oculto** (o prompt vai para stderr; stdout contém apenas o token). A sessão anterior segue válida durante a digitação, e só é descartada se o desbloqueio falhar — assim nunca sobra um token velho se passando por sessão atual
3. **Persiste a sessão** — grava o token de forma atômica (temporário + `mv`) com `umask 077`, de modo que o arquivo já nasce restrito, nunca existe em estado truncado e nunca falta durante a troca

A senha master **nunca** toca o disco nem aparece em nenhum output. Só o token de sessão (temporário e revogável) é gravado.

### Onde a sessão fica

O arquivo vai para `$XDG_RUNTIME_DIR/bw_session` — um diretório privado por usuário (`drwx------`), que o sistema apaga automaticamente no logout. Em sistemas sem `XDG_RUNTIME_DIR` (macOS, alguns containers), o script cai para `/tmp/.bw_session-$UID`.

Você nunca precisa decorar o caminho: `bw-connect --path` imprime qual está em uso.

## 📦 O que tem neste repositório

| Arquivo | O que é |
|---|---|
| [`bw-connect`](bw-connect) | O script em si |
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
git clone https://github.com/geraldoschuetze/bw-connect-setup.git
cd bw-connect-setup
```

> 🔍 **Leia antes de executar.** São ~70 linhas de bash entre os dois arquivos, e eles participam do desbloqueio do seu cofre. Abra o [`bw-connect`](bw-connect) e o [`install.sh`](install.sh) e confira o que fazem — vale mais do que qualquer selo de verificação.

### 2. Rode o instalador

```bash
bash install.sh
```

O instalador faz exatamente três coisas (e nada além disso):

1. Verifica os pré-requisitos (`bw`, `python3`) — se faltar algo, mostra como instalar e para
2. Copia o script para `~/.local/bin/bw-connect` (com `install -m 755`)
3. Garante que `~/.local/bin` está no `PATH` (adiciona ao `~/.bashrc`/`~/.zshrc` conforme o seu `$SHELL`, sem duplicar se já existir)

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
BW_SESSION=$(cat "$(bw-connect --path)") bw get password "nome-do-item"
BW_SESSION=$(cat "$(bw-connect --path)") bw list items --search "postgres"
```

> ⚠️ **Leia o arquivo a cada comando — não use `export BW_SESSION`.**
>
> Cada `bw unlock` **invalida os tokens de sessão anteriores**. Se você fixar o token no ambiente com `export BW_SESSION=…`, aquele terminal para de funcionar assim que você rodar `bw-connect` em qualquer outro lugar, e volta a pedir a senha master no meio dos seus comandos.
>
> Relendo o arquivo a cada invocação, como nos exemplos acima, todos os seus terminais passam a usar automaticamente a sessão mais recente.

### Auto-lock

O Bitwarden CLI **não tem timeout de inatividade** — sem intervenção, uma sessão desbloqueada vale até você reiniciar o computador. O `bw-connect` agenda automaticamente um travamento **3 horas** após cada desbloqueio:

```console
$ bw-connect
✅ Bitwarden conectado
   Sessão:    /run/user/1000/bw_session
   Auto-lock: em 3h
```

A contagem reinicia a cada `bw-connect`. Para ver quanto falta:

```bash
systemctl --user list-timers bw-autolock.timer
```

Para mudar o prazo ou desativar (aceita o formato de tempo do systemd — `30min`, `3h`, `1d`):

```bash
BW_AUTOLOCK=30min bw-connect   # trava em 30 minutos
BW_AUTOLOCK=off bw-connect     # sem auto-lock (vale até o reboot)
```

> O auto-lock depende do systemd de usuário. Em sistemas sem ele (macOS, alguns containers), o `bw-connect` avisa que não conseguiu agendar e a sessão dura até o reboot.

Para encerrar a sessão manualmente:

```bash
bw lock && rm -f "$(bw-connect --path)"
```

A sessão também some sozinha quando você faz logout do sistema (o `$XDG_RUNTIME_DIR` é apagado junto).

## 🤖 Uso com o Claude Code

Depois de rodar `bw-connect` num terminal comum, o Claude Code consegue usar a sessão nos comandos `bw`:

```bash
BW_SESSION=$(cat "$(bw-connect --path)") bw get password "nome-do-item"
```

Se o cofre travar no meio de uma sessão do Claude, rode `! bw-connect` direto no prompt do Claude — o `!` executa o comando no seu terminal e mostra o resultado na conversa.

## 🔒 Segurança

**Como o script protege suas credenciais:**

- A senha master é digitada em prompt oculto e **nunca é gravada em disco nem aparece em nenhum output**
- O token fica em `$XDG_RUNTIME_DIR`, um diretório privado do seu usuário (`drwx------`) — outros usuários da máquina não conseguem nem listar o conteúdo
- A gravação usa `umask 077` e escrita atômica: o arquivo já **nasce** com permissão `600`, sem janela em que fique legível por terceiros
- O `$XDG_RUNTIME_DIR` é apagado no logout — a sessão morre junto
- O token é revogável a qualquer momento com `bw lock`
- Se o desbloqueio falhar, a sessão anterior é removida: nunca sobra um token velho se passando por sessão válida
- O [auto-lock](#auto-lock) trava o cofre 3 horas após o desbloqueio, limitando a janela de exposição

**O que ele NÃO protege:**

Enquanto a sessão está ativa, **qualquer processo rodando com o seu usuário lê o cofre inteiro sem pedir senha** — basta ler o arquivo de sessão. Isso inclui qualquer código que você executar nesse período: pacotes de dependências, extensões de editor, scripts baixados.

Esse é o trade-off inerente da ferramenta, não um defeito: a conveniência de não redigitar a senha custa exatamente isso. As proteções acima defendem contra *outros usuários* da máquina, não contra código rodando como você. O auto-lock existe para encurtar a janela.

Se isso não for aceitável no seu contexto — máquina compartilhada, servidor, CI, ou um cofre com credenciais de produção de terceiros — não use este script: prefira `bw unlock` pontual a cada operação, ou um gerenciador de segredos com controle de acesso por processo.

**Nunca faça:**

- ❌ Copiar o arquivo de sessão para outro computador ou para dentro deste repositório — ele é um token de acesso ao seu cofre
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

O `~/.local/bin` ainda não está no `PATH` deste terminal. Abra um **novo** terminal (o instalador atualiza o rc do seu shell, que só é lido em sessões novas) ou rode:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

### Comandos `bw` pedem senha mesmo depois do `bw-connect`

Falta passar a sessão pro comando:

```bash
BW_SESSION=$(cat "$(bw-connect --path)") bw get password "item"
```

### Sessão expirou / cofre travou de novo

Normal. O cofre trava pelo [auto-lock](#auto-lock) (3h após o desbloqueio), por um `bw lock` manual, ou porque você reiniciou/deslogou do sistema. O Bitwarden CLI em si **não** trava por inatividade. Basta rodar `bw-connect` de novo.

## 🗑️ Desinstalação

```bash
rm -f ~/.local/bin/bw-connect "$(bw-connect --path)"
bw lock   # opcional: trava o cofre
```

(Se já removeu o script e precisa achar a sessão: ela está em `$XDG_RUNTIME_DIR/bw_session` ou `/tmp/.bw_session-$(id -u)`.)
