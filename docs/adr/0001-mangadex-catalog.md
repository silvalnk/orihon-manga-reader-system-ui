# ADR 0001 — MangaDex como catálogo

## Contexto

Orihon precisa de um catálogo gratuito, documentado e sem credenciais. APIs de apps oficiais de editora costumam exigir handshake de dispositivo e tokens de sessão.

## Decisão

Orihon usa só a [MangaDex API v5](https://api.mangadex.org/docs/03-manga/search/), pública e gratuita, com User-Agent identificável.

## Consequências

- Catálogo = obras publicadas na MangaDex.
- Sem paywall, sem extração de secret de celular.
- Stack: Lua/LÖVE e metáfora de orihon.
