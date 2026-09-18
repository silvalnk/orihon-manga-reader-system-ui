---
name: orihon-reader
description: Guia o leitor desktop Orihon (Lua/LÖVE, MangaDex, estante/ficha/spread RTL). Use quando o usuário falar de mangá, capítulo, API, layout, LÖVE, estante ou leitura.
---

# Orihon reader

Usuário iniciante: cada termo técnico aponta para [docs/GLOSSARY.md](../../../docs/GLOSSARY.md).

## Workflow

1. Ler `memory/STATE.md`, `memory/LIBRARY.md`, `memory/LAST_SESSION.md`.
2. Confirmar a spec: busca, estante, ficha, spread RTL, só MangaDex v5.
3. Rodar `lua tests/run.lua` depois de mudar Lua de domínio.
4. UI: paleta washi/vermelhão; dobras de orihon, não grade escura de WebView. Chrome: logo + busca + EN/PT; scrollbar; rodapé só em ficha/leitura. Print: `docs/images/estante.jpg`.
5. HTTP: User-Agent `Orihon/0.1`. Imagens só com `baseUrl` do at-home. Downloads na UI vão para `src/jobs.lua` (threads); nunca `curl` no `love.draw`.
6. Depois de mudar Lua, `lua tests/run.lua` precisa cobrir CAP-7 (contratos em `tests/perf.lua`).

## Comandos

```bash
lua tests/run.lua
love .
```

## Fora

Manga Plus, deviceSecret, paywall, erotica/pornographic, Tauri, Rust.
