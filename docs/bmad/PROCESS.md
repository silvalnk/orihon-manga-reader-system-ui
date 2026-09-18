# Processo BMad neste repo

Usamos o [BMad Method](https://github.com/bmad-code-org/BMAD-METHOD) para o contexto **não morrer** entre sessões: decisões explícitas, artefatos versionados, tamanho certo para o trabalho.

## Loop

1. **Clarify** — o que o usuário quer mudar? (ex.: “estante de dobras, não grade de cards”)
2. **Plan** — spec em `.specify/`, ADR se for decisão
3. **Build** — código Lua + testes + glossário no mesmo turno
4. **Learn** — `memory/LAST_SESSION.md`; volta ao plan se a evidência mudar

## Onde vive o contexto

| Artefato | Papel |
| --- | --- |
| `AGENTS.md` | briefing do agente |
| `.specify/SPEC.md` | contrato |
| `.specify/CONTEXT.md` | estado ao vivo |
| `docs/adr/` | porquês |
| `memory/` | estante, sessão |
| `docs/GLOSSARY.md` | termos para iniciante |
| `docs/images/` | prints da UI (estante) |
| `README.md` | porta de entrada + print |

## Instalar skills BMad (opcional)

A instalação via `npx skills add` é **manual** (você confirma no terminal). O processo já está escrito aqui mesmo sem o plugin:

```bash
npx skills add bmad-code-org/BMAD-METHOD -a cursor -s bmad -y
```

Depois, nesta pasta, peça `bmad setup`. Ver [BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD).
