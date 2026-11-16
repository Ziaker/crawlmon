> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.

# Tail Whip — auditoria contra a descrição do criador

**Escopo:** proposta de referência no Move Sketch (`TEL.moves.build('tail_whip')`, `TEL.moves.audit()`). Nada foi para o jogo. Decisões aplicáveis lidas: D-418 (sem flash/piscar), D-1222 (Move é 3D), D-235 (independente de personagem e lado), D-138/D-158 (estágios de defesa, só como referência de regra). **Descrição do criador usada como fonte única** (texto colado: giro de costas, cauda com rastro em arco, poeira ou corte de ar, rajada/estalo, alvo recua o olhar e baixa a guarda, brilho ou ícone, sem dano direto).

## 1. Auditoria da versão 1 (descartada)
| Item da descrição | v1 | Veredito |
|---|---|---|
| Sem dano direto, foco no corpo e na reação | Tipo **Melee** com investida | **Errado** (era golpe de contato) |
| Gira 180–360° no próprio eixo | Não havia giro do corpo | **Faltava** (e a ferramenta não tinha giro) |
| Vira de costas antes | Não | **Faltava** |
| Rastro translúcido em arco | Caixa com rastro | Parcial |
| Ponta toca o chão, poeira pequena | Anel de poeira nos pés, sem relação com a ponta | Parcial |
| Rajada cortante / som de chicotada | Coroa de impacto, cruz, domo e estilhaços | **Exagerado**, lia como dano |
| Alvo recua o olhar e baixa a guarda | Nenhuma reação do alvo | **Faltava** (a ferramenta não tinha) |
| Brilho sutil ou ícone "piscando" | Nenhum | **Faltava**; "piscar" conflita com D-418 |
| Som | Nenhum marcador | **Faltava** (a ferramenta não tinha) |

## 2. O que a ferramenta não tinha e foi criado
- **Giro do corpo do atacante** (chaves em ms, graus acumulados, curva) + marcador de frente nos bonecos (agora o giro é visível).
- **Reação do alvo** (recuo, pulo, inclinar, virar o olhar, abaixar a guarda) por chaves.
- **Marcadores de som (cues)** na linha do tempo e no export.
- Tudo entra no export JSON/briefing/GDScript e na telemetria (`yaw.set`, `react.set`, `cue.add`).

## 3. Versão 2 (refeita): resultado da auditoria por dados
Tipo **Status** (afeta o inimigo), 1400 ms, corpo parado, 7 formas, trilhas de mão, cauda (Efeito) e rajada. `TEL.moves.audit()` → **19 de 19 verificações passaram**:
tipo e alvo · corpo parado (x constante) · costas 180° no fim do wind-up · giro de 360° em 380 ms · braços e cauda desenhados no wind-up · rastro 14 cópias + borrão com opacidade 0,35 · ponta no chão (y final 0,03) · poeira pequena (0,22) no instante do contato (702 ms) · rajada de x 0,2 a 0,9 · "snap" em 722 ms = contato · reação do alvo (olhar até 35°, guarda baixa 12%) depois do impacto · brilho e ícone · D-418 opacidade do brilho 20% · D-418 máximo 2,3 Hz · D-418 nada cobre a tela · D-1222 cauda varia em x, y e z · D-235 sem posição absoluta · toda forma aparece · duração ≤ 2 s.
**Conferido no objeto 3D** (não só nos dados): rotação do atacante 0° → 180° (300 ms) → 540° (760 ms) → 720° (1100 ms); atacante em x = −2,5 o tempo todo; alvo com olhar −34°, inclinação −10° e altura 0,88 no pico e de volta a 0 no fim.

## 4. Limites da própria auditoria (honestidade)
- As verificações foram escritas por mim a partir da descrição; algumas só confirmam o que construí (ex.: "tipo = status"). Não substituem o julgamento do criador.
- **Visual:** conferi em spritesheets (todas as formas aparecem, a sequência giro → rajada → brilho e ícone é coerente), mas o **peso, o ritmo e a sensação de chicote** não saem de quadros estáticos. A cauda é uma caixa que afina e ondula, não o osso/malha real de um modelo.
- **"Borrão cinemático"** é aproximado por cópias translúcidas de rastro, não por motion blur real. **"Piscando"** foi trocado por **um único pulso lento** (≈ 2,3 Hz no máximo) e fade, por D-418; se o criador quiser piscar, é decisão dele e precisa respeitar D-418.
- **Som:** só há o marcador de instante; não há áudio.
- Não testado no Godot; nada ligado ao jogo; nenhuma comparação com um modelo real de Pokémon/criatura.

## 5. Pendências do criador (regras, não visual)
1. Efeito de jogo ("queda de resistência defensiva"): quanto, quantos estágios, duração, alvo e relação com D-138/D-158 — **não decidido**.
2. Tipo/categoria, custo, precisão, prioridade e se pode errar.
3. Se a cauda deve ser a do modelo (osso) e como cada criatura (cauda longa, grossa, fofa) varia o visual.
4. Se o ícone de defesa caindo e o brilho do alvo entram no jogo e com qual arte.
5. Se isto vira Move do jogo; se sim, registrar em `docs/decisoes/` antes de qualquer código.
