# Plano de construção

Ver ADRs em `docs/adr/` e o processo em `docs/bmad/PROCESS.md`.

1. Scaffold SDD + BMad + memória + skill Cursor
2. JSON + HTTP (curl) + cliente MangaDex testável
3. Persistência da estante e do progresso
4. Layout LÖVE (washi / vermelhão / dobras de orihon)
5. Telas: estante, ficha, spread
6. Testes Lua + smoke HTTP
7. Chrome: barra de rolagem; rodapé só em ficha/leitura; print em `docs/images/estante.jpg`

Stack: Lua 5.4 (testes), LÖVE 11 (UI), `curl` para HTTPS, MangaDex API v5.
