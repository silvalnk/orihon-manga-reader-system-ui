# Estado

- Tela padrão: estante (busca + populares); print em `docs/images/estante.jpg`
- Repo: [silvalnk/lua-orihon-manga-reader](https://github.com/silvalnk/lua-orihon-manga-reader) · pasta `lua-orihon/`
- Cabeçalho: só o nome **Orihon** + busca + EN/PT
- Estante: barra de rolagem; sem botões no rodapé (Home/More/Top/Clear saíram)
- Ficha: **Back** · Leitura: **Back / Prev / Next / Single**
- Clique no logo volta à estante (limpa a busca)
- API: `https://api.mangadex.org` (curl `-g --compressed`)
- UI: 3 workers; prefetch 5/3; 3 imagens/quadro (CAP-7 + `tests/perf.lua` + CI)
- Idiomas: en, pt-br
- Spread: duas páginas (RTL); `D` = página única
- Testes: `lua tests/run.lua` verde; `lua tests/live.lua` para smoke
