# Conventional commits + emoji

Fonte da verdade para **mensagens de git** neste repo.  
Skill do agente: `.cursor/skills/conventional-commits/SKILL.md`.

O arquivo é em **português**. As **mensagens de commit** permanecem em **inglês**.

## Formato

```
<emoji> <type>: <subject>

[corpo opcional — o *porquê*, não um dump de arquivos]
```

- Idioma da mensagem: **inglês**
- Subject: imperativo, sem ponto final, ~72 caracteres
- Uma mudança lógica por commit **salvo** se o usuário pedir um commit **por arquivo**

## Tipos e emoji

| Tipo | Emoji | Quando usar |
|------|-------|-------------|
| `feat` | ✨ | Comportamento novo (UI, API, persistência) |
| `fix` | 🐛 | Correção de bug |
| `docs` | 📝 | SPEC, CONTEXT, README, GLOSSARY, ADR, prints em `docs/images/` |
| `chore` | 🙈 | gitignore, tooling |
| `chore` | 🤖 | `.cursor/skills/` |
| `refactor` | ♻️ | Mesmo comportamento, código mais claro |
| `test` | ✅ | Só testes |
| `style` | 💄 | Só formatação |

## Exemplos (este repo)

```
✨ feat: open manga chapters as RTL orihon spreads
📝 docs: add beginner glossary for MangaDex and folds
🤖 chore: add orihon-reader Cursor skill
🙈 chore: ignore LÖVE cache and packaged .love files
```

## Nunca

- Commitar cache de imagens, `.data/`, `.env`, URLs secretas
- `--no-verify` / pular hooks, salvo se o usuário pedir
- Force-push em `main`
- Amend de commit que já está no remoto (salvo pedido explícito)
