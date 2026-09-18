# Glossário Orihon (para iniciante)

> **Única fonte de definições deste projeto.**  
> Não leia tudo de uma vez. Escolha uma seção e 3–5 termos.

| Marca | Significado |
|-------|-------------|
| **Neste projeto** | Aparece no código, na UI ou em `memory/` |
| **Só conceito** | Você pode ouvir no mundo do mangá; a v1 não implementa |

---

## 1. O produto

### Orihon

**Em uma frase:** livro japonês em sanfona, dobrado como um biombo.

**Explicação:** Em vez de páginas soltas grampeadas, o orihon é uma tira contínua dobrada. Este app usa essa metáfora: cada obra é uma tira de dobras.

**Analogia:** Um mapa de estrada que você abre em zigue-zague.

**Erro comum:** Achar que é um leitor web ou o app oficial de uma editora.

**Neste projeto:** o nome do produto; pasta local `lua-orihon/`; repo [silvalnk/lua-orihon-manga-reader](https://github.com/silvalnk/lua-orihon-manga-reader).

### Estante (`shelf`)

**Em uma frase:** tela inicial com busca e favoritos, como uma prateleira de orihons.

**Neste projeto:** tela `shelf` em `src/app.lua`. Print: `docs/images/estante.jpg`.

### Barra de rolagem

**Em uma frase:** trilha à direita da grade (e da lista de capítulos) para ver o resto das dobras.

**Neste projeto:** `layout.scrollbar`; arrastar, clicar ou roda do mouse. Mais obras entram ao chegar no fim (`limit`/`offset`).

### Rodapé

**Em uma frase:** faixa de botões só quando a tela precisa de navegação extra.

**Neste projeto:** a estante **não** tem rodapé. A ficha tem **Back**. A leitura tem **Back / Prev / Next / Single**. `layout.shows_footer`.

### Carimbos EN / PT

**Em uma frase:** filtros de idioma no canto direito do cabeçalho.

**Neste projeto:** `en` e `pt-br` nas buscas e no feed.

### Selo

**Em uma frase:** círculo vermelhão à esquerda do nome; na ficha, o mesmo gesto guarda a obra na estante.

**Neste projeto:** desenhado em vetor (`draw_seal`) — a fonte padrão do LÖVE não traz o ideograma 蔵.

### Ficha / dobra (`fold`)

**Em uma frase:** a obra aberta no meio: capa, texto e capítulos empilhados como dobras.

**Neste projeto:** tela `fold`.

### Spread

**Em uma frase:** duas páginas lado a lado, no sentido de leitura do mangá (direita → esquerda).

**Analogia:** Abrir um caderno no meio e ver a página da direita primeiro.

**Neste projeto:** tela `spread`; tecla `D` força uma página só.

### RTL

**Em uma frase:** right-to-left — lê-se da direita para a esquerda.

**Neste projeto:** clique na metade **direita** avança; na **esquerda**, volta.

---

## 2. Fonte dos mangás

### MangaDex

**Em uma frase:** site/catálogo com API pública e gratuita para listar obras e capítulos.

**Explicação:** Não é a Shueisha nem o MANGA Plus. Editores e scanlators oficiais/parceiros publicam lá com regras próprias.

**Neste projeto:** única API da v1. Docs: https://api.mangadex.org/docs/

### MangaDex@Home

**Em uma frase:** rede que entrega as **imagens** das páginas. A URL muda e vale pouco tempo.

**Neste projeto:** `GET /at-home/server/{chapterId}` em `src/mangadex.lua`. Sempre usar o `baseUrl` devolvido, nunca hardcoded.

### data-saver

**Em uma frase:** versão comprimida da página, mais leve.

**Neste projeto:** qualidade padrão da leitura (banda de WSL/residencial).

### contentRating

**Em uma frase:** classificação da obra (`safe`, `suggestive`, `erotica`, `pornographic`).

**Neste projeto:** só `safe` e `suggestive`.

### feed

**Em uma frase:** lista de capítulos de um mangá.

**Neste projeto:** `GET /manga/{id}/feed`.

---

## 3. Ferramentas

### LÖVE (Love2D)

**Em uma frase:** motor para fazer app/jogo em Lua, com janela, desenho e input.

**Neste projeto:** `love .` abre o Orihon.

### Lua

**Em uma frase:** a única linguagem de código da v1.

### SDD

**Em uma frase:** Spec-Driven Development — a spec diz o que o código deve fazer.

**Neste projeto:** `.specify/SPEC.md` manda se divergir do código.

### BMad

**Em uma frase:** método para o contexto não morrer entre chats (clarify → plan → build → learn).

**Neste projeto:** `docs/bmad/PROCESS.md`.

### jobs / workers

**Em uma frase:** três fios à parte da janela que baixam JSON e imagens com `curl`, para a UI não congelar.

**Neste projeto:** `src/jobs.lua` + `src/download_thread.lua`. Números travados: 3 workers, prefetch 5/3, 3 imagens por quadro. `tests/perf.lua` + CI.

---

## 4. Só conceito (fora da v1)

### MANGA Plus / deviceSecret

App oficial da Shueisha; secret do celular para sessão paga. **Orihon não usa.**
