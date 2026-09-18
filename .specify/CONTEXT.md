# Contexto da sessão (Orihon)

Atualizado: 2026-09-17

GitHub: [silvalnk/orihon-manga-reader-system-ui](https://github.com/silvalnk/orihon-manga-reader-system-ui) · pasta local: `orihon_manga_ui/`

Print da estante: [`docs/images/estante.jpg`](../docs/images/estante.jpg)

## Estado

- Fonte: MangaDex API v5 (grátis, documentada)
- UI: LÖVE, tema washi; telas `shelf` → `fold` → `spread`
- Cabeçalho: selo + nome **Orihon**, busca, carimbos EN/PT (sem subtítulo)
- Estante: grade + barra de rolagem à direita; `limit`/`offset` ao chegar no fim; **sem rodapé**
- Ficha: rodapé só **Back** (Esc também volta; o logo reseta a estante)
- Leitura: rodapé **Back / Prev / Next / Single**
- Idiomas: EN + PT-BR
- Conteúdo: safe + suggestive
- Persistência: `library.json` + `progress.json` no save dir do LÖVE
- HTTP: curl com `-g` e `--compressed`; na UI, 3 threads (`src/jobs.lua`) para JSON e imagens
- Leitura: pré-carrega as próximas páginas; a janela não trava no `curl`
- CAP-7: números em `layout.prefetch_ahead` / `jobs.N` / `layout.images_per_frame`; testes em `tests/perf.lua`; CI em `.github/workflows/test.yml`
- CAP-8: chrome mínimo; `layout.shows_footer` só em `fold` e `spread`
- ADR: `docs/adr/0003-nonblocking-ui.md`
- Licença do código: MIT (`LICENSE`); obras da MangaDex continuam dos autores

## Como retomar numa sessão nova do Cursor

1. Abrir a pasta `orihon_manga_ui/` (não um chat órfão).
2. Ler `docs/GLOSSARY.md` se algum termo não for óbvio.
3. Ler `memory/STATE.md`, `memory/LIBRARY.md`, `memory/LAST_SESSION.md`.
4. Rodar `lua tests/run.lua`.
5. Opcional: `lua tests/live.lua` (rede).
6. Rodar `love .` para a UI (LÖVE 11 no PATH).
