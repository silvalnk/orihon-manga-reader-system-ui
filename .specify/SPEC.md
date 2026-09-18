# Spec — Orihon v1

## Objetivo

Leitor desktop de mangá, só Lua, com UI própria (orihon / papel / RTL) e catálogo via API gratuita oficial. Sessão persistente no Cursor via SDD + BMad.

## Capacidades

- **CAP-1** — Catálogo MangaDex com páginas de **32** (`limit`/`offset`). A primeira página no arranque; as seguintes entram ao **rolar para baixo** até `total`.
- **CAP-2** — Estante persistente (favoritos em JSON local)
- **CAP-3** — Ficha da obra: capa, sinopse, até **100** capítulos no feed
- **CAP-4** — Ler páginas via MangaDex@Home (`/at-home/server/{chapterId}`), qualidade `data-saver`
- **CAP-5** — Spread RTL (duas páginas) com teclado/mouse; progresso por capítulo
- **CAP-6** — `AGENTS.md` + `memory/` + skill Cursor + glossário
- **CAP-7** — UI não espera `curl`. Números travados: `jobs.N == 3`, prefetch spread/single `5`/`3`, `layout.images_per_frame == 3`. Contratos em `tests/perf.lua` + CI.
- **CAP-8** — Chrome da UI: cabeçalho (logo **Orihon**, busca, EN/PT); barra de rolagem na estante/ficha; rodapé só na ficha (**Back**) e na leitura (**Back / Prev / Next / Single**). Print em `docs/images/estante.jpg`.

## Travas

- User-Agent identificável (`Orihon/0.1`)
- Só `contentRating` `safe` e `suggestive`
- Sem credenciais; sem OAuth
- Cache de imagens no diretório de save do LÖVE (gitignored)
- `src/app.lua` e `main.lua` não chamam `curl` / `http.get` / `mangadex.search(` / `io.popen`
- Módulo `thread` do LÖVE permanece ligado (`conf.lua`)

## Fora de escopo

APIs não documentadas, Tauri, Svelte, APIs pagas, login MangaDex, modo adulto, multiplayer.

## Sucesso

`lua tests/run.lua` verde (CAP-7); CI `.github/workflows/test.yml`; `love .` abre a estante como em `docs/images/estante.jpg`; sessão nova lê `memory/` sem o chat antigo; iniciante explica *orihon*, *spread* e *MangaDex* pelo glossário.
