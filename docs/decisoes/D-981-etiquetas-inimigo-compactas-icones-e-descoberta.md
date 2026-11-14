<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-981 — Etiquetas dos inimigos: sem MP, translúcidas, compactas, com retrato e elementos (com descoberta)

- **Data:** 2026-11-08.

## Frase literal do criador

> 1 - as barras do inimigo só devem mostrar a vida e o atb, MP não
> 2 - as barras tão escuras demais e sem nenhuma opacidade reduzida, reduza um pouco pra ser visível as coisas além de movimentar elas um pouco mais pra cima.
> 3 - as barras do inimigo também devem sofrer este efeito, eu também quero que as barras deles tenham seus ícones e sejam mais compactas

Respostas: ícones = **retrato pequeno e ícones de elemento**, "porém, são pontos de interrogação pretos em um fundo branco no lugar dos icones caso nunca tenhamos descoberto seus elementos, no caso de não ter uma espécie igual na equipe (grupo ou reserva) e não ter descoberto fraqueza / resistência. Além disso faça outra correção, a velocidade com que as huds ficam balançando é um pouco alta demais, reduza um pouco". Opacidade e altura: **só inimigos**.

## Decisão

1. Etiqueta do inimigo mostra só **HP e ATB** (sai a barra de MP).
2. Fundo da etiqueta **um pouco translúcido** e a etiqueta **um pouco mais alta** na tela.
3. Etiqueta **mais compacta**, com **retrato pequeno** e **ícones de elemento** da espécie.
4. **Descoberta:** os ícones de elemento aparecem como **"?" preto em fundo branco** até a espécie ser conhecida: há uma espécie igual na equipe (grupo ou reserva), ou já foi descoberta uma fraqueza/resistência dela.
5. A etiqueta do inimigo também fica **zonza no STUN** (balanço, estrelas, olhos em espiral no retrato).
6. O balanço das HUDs no STUN fica **mais lento**.

## Ambiguidades / limites do código atual

- O jogo **não tem reserva nem resistências** hoje: a descoberta usa o grupo atual e as fraquezas acertadas (acerto com `weak`). Quando reserva/resistência existirem, devem entrar na mesma regra.
- A descoberta vale para a espécie inteira e fica guardada no `GameState` durante a sessão (não há save dessa informação ainda).

## Estado

Implementado para revisão.
