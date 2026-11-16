<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1238 — Hub 3D: iluminação mais escura, detalhamento ambiental e NPCs entrando/saindo do portal

- **Data:** 2026-11-16
- **Área:** overworld, hub-3d, iluminação, npcs, debug
- **Estado:** **aprovada; em implementação** (delegação lógica via `ds-run.mjs` + direção/melhora visual pelo agente principal).
- **Relacionadas:** [D-1023](D-1023-lab-3d-terceira-pessoa-smt3.md), [D-1028](D-1028-visual-3d-toon-inspirado-nas-tiles-do-pmd.md), [D-1063](D-1063-npcs-overworld-3d-5-pokemon-5-dqt.md), [D-1082](D-1082-melhorias-murky-forest-luz-folhagem-oclusao.md), [D-1083](D-1083-iluminacao-menos-clara-contrastada.md), [D-1086](D-1086-indicadores-overworld-circulos-icones-medroso.md), [D-1091](D-1091-cores-aneis-npc-inimigo.md), [D-1105](D-1105-cards-40-da-base-e-icones-acima-do-nome.md), [D-1116](D-1116-palicada-de-raizes-5-variacoes-nas-paredes.md), [D-1154](D-1154-telemetria-obrigatoria.md), [D-1204](D-1204-debug-obrigacao-extrema-teste-em-menos-de-1-minuto.md), [D-1207](D-1207-pre-jogo-v3-ciclo-campanha-e-hub-3d.md), [D-1211](D-1211-phantastes-rivais-travelers-e-sistemas-pre-campanha.md), [D-1237](D-1237-transicao-nature-hub-variante-carimbo-e-invocacao.md)

## Frases literais do criador

> "melhore o visual do hub, reduza a quantidade de luz, é pra ele ser um pouco mais escuro, deixe-o mais detalhado, mais vivo, com mais NPCS que as vezes entram no portal e somem, surgindo mais tarde depois de um tempo e mais outras melhorias"

> "aprovo" *(aprovando integralmente as 5 recomendações enumeradas do plano)*

## Decisão

1. **Redução de luz e atmosfera mais escura (`dusk` / `day` / `night`):**
   - Reduzir iluminação geral em ~35–40% no preset padrão `dusk` (e proporcionalmente em `day`/`night`), alinhando com [D-1083](D-1083-iluminacao-menos-clara-contrastada.md): `tonemap_exposure = 0.86`, `adjustment_brightness = 0.94`, `contrast = 0.88`, `saturation = 0.90` e vinheta sutil (`shaders/vignette.gdshader`, força `0.30`).
   - Em `dusk`: `ambient_e = 0.28`, `dir_e = 0.20` (`shadow_opacity = 0.55`), bounces reduzidos (`0.22`, raio `6.5 m`), spots de claraboia reduzidos (`1.45 / 0.95 / 0.85`, cone `26°` no centro) e albedo do piso escurecido (`Color(0.32, 0.26, 0.22)` centro / `Color(0.20, 0.16, 0.14)` entorno) para destacar Portão, postes e Guild Hall como ilhas quentes na penumbra.
2. **Elenco expandido para 12 NPCs:**
   - Mantém os 6 originais (`pikachu` Guild Clerk, `squirtle` Gate Warden, `bulbasaur`, `charmander`, `eevee`, `dqt_healslime`);
   - Adiciona os 4 DQT da [D-1063](D-1063-npcs-overworld-3d-5-pokemon-5-dqt.md) (`dqt_dracky`, `dqt_sabrecub`, `dqt_platypunk`, `dqt_fungi`);
   - Adiciona 2 Travelers dinâmicos dentre os protagonistas jogáveis (`abra`, `pancham`, `gible`, `dqt_slime`, `dqt_orc`, `dqt_cyclops`) que não estejam ativos como líder nem seguidores (atualizando ao trocar líder em `F6`). Todos usam modelos completos validados ([D-1211](D-1211-phantastes-rivais-travelers-e-sistemas-pre-campanha.md)).
3. **Ciclo de Portal de Expedição dos NPCs:**
   - NPCs móveis elegíveis (exceto `pikachu` Clerk e `squirtle` Warden) entram periodicamente no `Expedition Gate` (`14–24 s` entre partidas, até 1–2 viajando por vez): caminham pela passarela norte até a boca do portal, pausam brevemente (`0.4 s`), avançam para o vórtice encolhendo/dissolvendo em luz âmbar (`0.55 s`) com pulso no portal;
   - Durante a ausência (`8–14 s`), ficam invisíveis, sem colisão (`collision_layer = 0`), ocultos no minimapa e fora de `_targets()` (nunca interrompendo conversa ativa);
   - Retornam emergindo do vórtice com pulso no portal e escala `0 → 1`, caminhando de volta à praça.
4. **Rotas vivas e micro-interações:**
   - Waypoints em pontos reais de interesse (Expedition Board, balcão da Guild Hall, Plot A/B, encontros sociais entre NPCs virando um para o outro) + anel branco no chão (`overworld_marker_ring.gdshader`, [D-1086](D-1086-indicadores-overworld-circulos-icones-medroso.md)/[D-1091](D-1091-cores-aneis-npc-inimigo.md)).
5. **Detalhamento visual e ambiental 3D:**
   - Partículas (`dust`, `emb`, vaga-lumes) com shader circular suave (eliminando quadrados duros);
   - 6 variações de paliçada ([D-1116](D-1116-palicada-de-raizes-5-variacoes-nas-paredes.md)), vinhas penduradas, raízes, galhos inclinados, samambaias, pedras e cogumelos discretos (com fade de oclusão para câmera);
   - Medalhão central em baixo-relevo com anéis de pedra escura e bronze; meio-fio nas passarelas;
   - Braseiros, degraus chanfrados e moldura detalhada no `Expedition Gate`; caixotes, barris, lanternas, tapete e avisos na `Guild Hall`; estacas/cordas nos `Plots A/B`; postes e bancos detalhados.
6. **Debug < 10 s ([D-1204](D-1204-debug-obrigacao-extrema-teste-em-menos-de-1-minuto.md)):**
   - Novo cenário determinístico `HUB_PORTAL_CYCLE` validando entrada no portal, ausência (visibilidade, colisão, minimapa, interação) e retorno pelo portal.

## Referências

- `scripts/hub/hub_3d_lab.gd`
- `scenes/hub_3d_lab.tscn`
- `scenes/debug/hub_3d_prototype.tscn`
