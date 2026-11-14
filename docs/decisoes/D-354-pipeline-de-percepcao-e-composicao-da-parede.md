<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-354 — Pipeline de percepção dos tilesets: orientação, preview e contrato de face

- **Data:** 2026-11-06
- **Área:** Ferramentas / assets / exploração
- **Origem:** Depois de o atlas sintético de 42 tiles piorar os lados, o criador pediu melhorias capazes de perceber o erro sozinhas.

## O que o criador disse (literal)

> não sei o que pensar, tem alguma melhoria que poderia ter pra ser capaz de perceber isso naturalmente?

E, depois das 10 propostas:

> prossiga com todas

## Decisão

As 10 melhorias passam a rodar **antes** de o atlas ser usado:

1. **Probe de componente e orientação:** simetria H/V, brilho das linhas e colunas, lado escuro (face) de cada tile, assinatura `N/S/W/E`.
2. **Preview da folha como gabarito:** recorte do quadro verde, escala e composição por template matching.
3. **Teste de costura:** costura entre tiles vizinhos do bloco e autotile (L/R e T/B).
4. **Contrato de face:** cada papel declara os lados abertos esperados; o importador mede o tile e recusa o papel se não bater.
5. **Proibição de síntese entre componentes:** só células reais da mesma categoria; o atlas ativo tem 30 tiles e nenhuma peça sintética.
6. **Golden do preview:** a composição do preview é comparada com as linhas do bloco.
7. **Gate humano:** o `audit_components.py --only <folha> --approve` grava a aprovação; o build avisa quando a folha ativa não tem aprovação ou quando ela ficou velha.
8. **Teste de espelhamento:** pares do bloco (C3↔C5, R0↔R2) medidos; não se usa “espelhado” como desculpa.
9. **Grade de componentes:** imagem `docs/referencias/tilesets/<folha>_components.png` com papel, C/R, lado medido, preview, espelhos, contrato e extras.
10. **Checklist de mesmo componente:** núcleo, extras, colunas do atlas, papéis inesperados e células fora do componente.

## O que o probe descobriu

O bloco **Walls 3×3 não é um autotile de 9 peças independentes**: é uma **massa de parede**.

- Linha 0 = borda de trás/topo (face norte);
- Linha 1 = superfície de topo;
- Linha 2 = face frontal (face sul);
- Colunas 3/5 = laterais com face a oeste/leste.

O preview da própria folha, casado pixel a pixel, mostra a composição pretendida:

```
top surface (row 1) -> front face (row 2) -> floor (Ground)
```

Isso vale nas 16 folhas do Sky. A parede do jogo é uma **massa** (a dungeon é cavada num bloco sólido), então a linha 1 vem da massa acima e a linha 2 é o tile da borda. Por isso a seleção correta é pelo **lado aberto**:

- um lado aberto → `wall_t/l/r/b` do núcleo;
- dois lados opostos → `wall_strip_h/v` reais (C4R3 / C3R4);
- dois adjacentes → cantos do núcleo;
- três → `wall_tip_*` reais;
- quatro → `wall_island` real;
- nenhum, com as quatro diagonais em chão → `wall_cross` real.

Peças sintéticas e a strip C3R4 usada em todo lado ficam proibidas.

## Estado

Implementado: `audit_components.py` (10 melhorias), 16 auditorias, perfil de 30 tiles com `role_sides`/`role_cells`/`side_contract_ok`, seleção por assinatura no jogo e no laboratório, laboratório com sala embutida na massa de parede, câmera 2,3×, 48 px. O contrato passa no Temporal Tower (folha ativa); D-356 fez os 12 perfis sem contrato usarem as pe?as reais por papel. O criador aprovou visualmente o início do jogo (Temporal Tower) em 2026-11-06; o gate formal foi **aprovado** depois de D-355/D-356 (30 tiles, 5+5% Wall Alt) e o build não avisa mais. O próximo risco é o andar 5: o bioma troca e 12 dos 16 perfis usam o fallback por papel (as formas estão certas; a paleta é a de cada folha). Nada foi publicado.
