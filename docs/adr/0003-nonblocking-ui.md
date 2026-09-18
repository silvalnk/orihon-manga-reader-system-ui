# ADR 0003 — UI nunca espera a rede

## Contexto

Downloads síncronos na janela (curl no `love.update` / `love.draw`) deixavam a leitura travada. A v1 ficou fluida com workers e prefetch.

## Decisão

- `curl` só em `src/download_thread.lua`
- Fila `src/jobs.lua` com `jobs.N == 3` e `Channel:pop` (nunca `demand` na UI)
- Prefetch: `layout.prefetch_ahead.spread == 5`, `single == 3`
- GPU: `layout.images_per_frame == 3`
- Contratos em `tests/perf.lua` (CAP-7). Mudar esses números exige mudar o teste de propósito.

## Consequências

- `lua tests/run.lua` quebra se o `curl` voltar para `src/app.lua` ou se os workers/prefetch caírem.
- JSON da MangaDex chega via `jobs.text` + `mangadex.search_url` / `feed_url` / `at_home_url`, não via `mangadex.search(http)`.
