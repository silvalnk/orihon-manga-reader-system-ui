# AGENTS.md

Briefing **independente de sessão** para o Cursor. O histórico do chat é opcional; estes arquivos não.

## Sempre (sessão nova)

1. Se o usuário for iniciante ou aparecer termo técnico, ler [`docs/GLOSSARY.md`](docs/GLOSSARY.md).
2. Ler [`memory/STATE.md`](memory/STATE.md), [`memory/LIBRARY.md`](memory/LIBRARY.md), [`memory/LAST_SESSION.md`](memory/LAST_SESSION.md).
3. Seguir [`.cursor/skills/orihon-reader/SKILL.md`](.cursor/skills/orihon-reader/SKILL.md).
4. Spec manda: [`.specify/SPEC.md`](.specify/SPEC.md). Estado vivo: [`.specify/CONTEXT.md`](.specify/CONTEXT.md).
5. Nunca integrar Manga Plus, scanlation pirata, ou API não documentada. Fonte = **MangaDex API v5** (pública, grátis).
6. Não baixar nem exibir conteúdo `erotica` / `pornographic` na v1.
7. **CAP-7:** não recolocar `curl` / `http.get` / `io.popen` em `src/app.lua` ou `main.lua`. Downloads = `src/jobs.lua`. `lua tests/run.lua` tem de continuar verde.
8. Depois de mudar comportamento, atualizar `.specify/CONTEXT.md`, `memory/STATE.md` e o glossário se um termo novo nascer. Se a estante mudar de cara, atualizar `docs/images/estante.jpg` e o README.
9. Quando o usuário pedir **commit**, seguir [`.specify/COMMITS.md`](.specify/COMMITS.md) (`✨ feat:` / `📝 docs:` / …, **mensagens em inglês**).

## Idioma

- Markdown (incluindo este arquivo): **português**
- Código, erros, identificadores, commits: **inglês**

## Produto

**Orihon** é um leitor desktop de mangá em **Lua + LÖVE 11**. A UI imita um orihon (livro-acordeão): estante de dobras, ficha da obra, leitura em *spread* RTL. Pasta local: `lua-orihon/`. Repositório: [silvalnk/lua-orihon-manga-reader](https://github.com/silvalnk/lua-orihon-manga-reader). Print da estante: [`docs/images/estante.jpg`](docs/images/estante.jpg).

Chrome: cabeçalho (logo, busca, EN/PT); barra de rolagem na estante/ficha; rodapé só em `fold` e `spread`.

## Comandos

```bash
lua tests/run.lua          # testes puros (sem janela)
love .                     # app desktop
```

## Não adicionar na v1

Manga Plus / Shueisha unofficial API, paywall bypass, WebView, Rust/JS, contas de usuário MangaDex, upload, comentários, conteúdo adulto explícito.
