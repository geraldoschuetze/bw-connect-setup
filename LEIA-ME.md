# bw-connect — Instalação em outro computador

Pacote portátil para instalar o `bw-connect`, o script que desbloqueia o
Bitwarden no terminal e deixa a sessão pronta para uso (inclusive pelo
Claude Code).

## ✅ O que tem neste pacote (e o que NÃO tem)

| Arquivo | O que é |
|---|---|
| `bw-connect` | O script em si |
| `install.sh` | Instalador automático |
| `LEIA-ME.md` | Este guia |

**Este pacote NÃO contém nenhuma senha, token ou segredo.** Pode ser
copiado por pendrive, e-mail ou drive pessoal sem risco — toda a
autenticação acontece só na hora do uso, no computador de destino.

## 📦 Passo a passo de instalação

### 1. Copie a pasta para o novo computador

Leve a pasta `bw-connect-setup` inteira (pendrive, Google Drive, etc.)
para qualquer lugar do novo PC — por exemplo, `~/Downloads`.

### 2. Rode o instalador

Abra um terminal na pasta e rode:

```bash
cd ~/Downloads/bw-connect-setup
bash install.sh
```

O instalador:
- Verifica se o Bitwarden CLI (`bw`) está instalado — se não estiver,
  mostra as opções oficiais de instalação e para (rode de novo depois)
- Copia o script para `~/.local/bin/bw-connect`
- Garante que `~/.local/bin` está no PATH

Se precisar instalar o Bitwarden CLI, use **somente fontes oficiais**:

```bash
npm install -g @bitwarden/cli    # via npm
# ou
sudo snap install bw             # via snap (Ubuntu)
```

Binário oficial: https://bitwarden.com/help/cli/#download-and-install

### 3. Primeira vez neste computador: login

```bash
bw login
```

Entre com seu e-mail e senha master do Bitwarden (só precisa uma vez
por máquina).

### 4. Uso no dia a dia

```bash
bw-connect
```

Digite a senha master quando pedir (ela fica **oculta** enquanto você
digita). Ao ver `✅ Bitwarden conectado`, o cofre está desbloqueado e a
sessão salva em `/tmp/.bw_session`.

## 🔒 Segurança — como funciona e o que nunca fazer

**Como o script protege suas credenciais:**
- A senha master é digitada em prompt oculto e **nunca é gravada em
  disco nem aparece em nenhum output**
- O token de sessão fica em `/tmp/.bw_session` com permissão `600`
  (só o seu usuário lê)
- O `/tmp` é apagado a cada reinicialização — a sessão morre junto
- Para encerrar a sessão manualmente: `bw lock && rm -f /tmp/.bw_session`

**Nunca faça:**
- ❌ Copiar o arquivo `/tmp/.bw_session` para outro computador ou
  para dentro deste pacote — ele é um token de acesso ao seu cofre
- ❌ Passar a senha master por argumento de linha de comando
  (ficaria no histórico do shell)
- ❌ Instalar o `bw` de fontes não oficiais

## 🤖 Uso com o Claude Code

Depois de rodar `bw-connect` num terminal comum, o Claude Code consegue
usar a sessão nos comandos `bw`:

```bash
BW_SESSION=$(cat /tmp/.bw_session) bw get password "nome-do-item"
```

Se o cofre travar no meio de uma sessão do Claude, rode `! bw-connect`
direto no prompt do Claude (o `!` executa no seu terminal e mostra o
resultado na conversa).
