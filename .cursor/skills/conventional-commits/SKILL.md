---
name: conventional-commits
description: Cria commits git do Orihon no formato conventional commits + emoji, em inglês. Use quando o usuário pedir commit, conventional commit, mensagem de commit, git commit, ou um commit por arquivo.
---

# Conventional commits + emoji

Antes de commitar, leia [`.specify/COMMITS.md`](../../.specify/COMMITS.md) e siga à risca.

## Formato

```
<emoji> <type>: <subject>
```

**Inglês.** Subject no imperativo. Corpo opcional = **porquê**.

| Tipo | Emoji |
|------|-------|
| feat | ✨ |
| fix | 🐛 |
| docs | 📝 |
| chore (gitignore) | 🙈 |
| chore (skills do Cursor) | 🤖 |
| refactor | ♻️ |
| test | ✅ |

Padrão: **um commit** para a mudança relacionada.

Se o usuário pedir **um commit por arquivo**: adicione e committe cada caminho separadamente.

## Segurança

- Não committe cache de imagens, `.data/`, `.env` ou segredos
- Não pule hooks
- Não faça push sem pedido
- Nunca altere git config
