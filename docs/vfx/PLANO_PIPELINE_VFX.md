# Plano — Pipeline de VFX do Crawlmon (para revisão externa)

> **Para a IA revisora:** este documento é autocontido. Leia o contexto, critique a arquitetura, aponte riscos, furos e simplificações, e proponha um primeiro corte. **Não escreva código ainda.** O VFX está pausado; este plano não autoriza execução.
>
> **Pedido:** revise como arquiteto de VFX/Godot. O objetivo é qualidade visual alta com o menor custo de criação possível, sem inventar regra de jogo.

## 1. Contexto do projeto

- **Engine:** Godot **4.7.2**, renderer **GL Compatibility**. Sem GPUParticles, decals, sub-emitters ou particle trails de GPU. O jogo usa CPUParticles, malhas, shaders e flipbooks.
- **Jogo:** batalha 3D com personagens em cel-shading, estética anime/SMT/Persona/Genshin/Pokémon. Câmera fixa de batalha (CINEMA/TÁTICA/IMPACTO), sem zoom/shake animado por padrão.
- **Pipeline atual de VFX:** o **Motion Composer** (MC) gera movimento paramétrico (M01–M26), composto em camadas, com representações (tubo, fita, lâmina, arco, casca, fragmentos, fogo, fumaça, faísca, flipbook, anel, marca, luz). Ele é determinístico, avaliado em tempo explícito, e não decide dano/acerto/duração.
- **Efeitos de referência aprovados no jogo:**
 - **Abra v9** (D-170): Confusion, Psybeam, Shock Wave, Teleport — feitos à mão com `AbraMoveVfx`/`AbraCanvas` (camadas 2D/3D, additive, câmera fixa).
 - **Tackle D-041:** impacto com shock cone 3D, flipbook de impacto, faíscas, poeira radial, squash do alvo; poeira de corrida (arranque, esteira, frenagem).
 - **Moves do atelier** (D-335/D-337): Media, Mabufula, Dig, Sand Attack, Dragon Rage, Splitter Flames — coreografias completas, malhas 3D, flipbooks, shaders, câmera.
- **Experiência recente (D-953):** uma V1 de melee feita **sobre o MC** foi reprovada pelo criador ("tá um lixo completo"; "o problema é o motion em si"). O experimento foi **descartado e desligado do jogo**. Tackle/Brick Break do jogo continuam intactos.
- **Decisão vigente (D-954):** o **MC é a camada de movimento secundário** (poeira, brasas, fumaça, cacos, rastros, ondas, timing de fases). O **golpe principal é um shot feito à mão** (animação/pose/contato, afterimages/smear, malhas/flipbooks, câmera/composição).
- **Estado:** VFX **pausado** até este plano ser aprovado. Ferramentas de apoio instaladas: VFX Animation Player (MIT), Brackeys Particle Controls (MIT), TrailRenderer (MIT). Nenhum efeito novo foi criado.

## 2. Problema a resolver

O criador não consegue pedir efeitos com precisão e os resultados anteriores ficaram "genéricos" ou "desligados do jogo". Causas identificadas:

1. **Motion procedural x animação do personagem:** o MC anima caminhos matemáticos; não lê o `AnimationPlayer`, a pose, o membro ou o frame de contato. O efeito é um sistema separado do corpo.
2. **Falta de escopo por shot:** o HTML/Quarks é autorado como **um plano** (câmera, enquadramento, escala de tela, timing, camadas juntos). O MC foi testado em laboratório com marcadores e no jogo com alvo a ~30 m.
3. **Render:** o HTML usa bloom/aditivo/tela; o Godot está em GL Compatibility e o jogo não tem bloom/glow (D-337). O material do MC é plano.
4. **Excesso de camadas sem contato:** a V1 melee tinha 31 camadas, mas nenhuma nascia do contato real; o impacto era uma nuvem/explosão, não um golpe direcional.
5. **Vocabulário:** o criador não tem nomes estáveis para pedir "thrust cone", "shockwave ring", "impact crown", "dust trail"; sem vocabulário, cada pedido vira interpretação.

## 3. Arquitetura proposta

### 3.1 Princípio

**Herói por shot; secundário pelo Composer.**

- **Herói:** silhueta do ataque, contato, movimento do corpo, câmera, materiais principais e impacto. Autorado à mão, com referência aprovada.
- **Secundário:** poeira, brasas, fumaça, cacos, detritos, rastros, ondas, campos e timing de fases. Pode usar o MC.
- **Regra:** o MC não é dono de animação esquelética, câmera/composição, escala de tela, bloom/post ou régua de qualidade (D-954).

### 3.2 Camadas do pipeline

1. **Vocabulário visual** — glossário + cards HTML + brief de 7 linhas.
2. **Shot brief** — uma página por Move: referência, silhueta, movimento, fases, impacto, material/escala, "o que NÃO deve ter".
3. **Herói** — animação/pose/frame de contato do personagem; afterimages/ghost snapshots; smear; malhas/flipbooks; AnimationPlayer/Tween.
4. **Secundário** — MC para poeira/brasas/fumaça/cacos/rastros/ondas e timing de fases.
5. **Look** — shaders, materiais, flipbooks, luz; pós-processamento só se for decisão de cena inteira.
6. **Verificação** — batalha real (`vfx_room`), personagens reais, normal + espelhado, quadros, vídeo, orçamento, sobras.

## 4. Fases de execução

### Fase 0 — Vocabulário e biblioteca (sem efeito)

**Entrega:**
- `docs/vfx/GLOSSARIO_FORMAS.md` (termos PT/EN, definição, fase, como o projeto faz).
- Página HTML local com cards de 3–5 s, filtros por fase/forma, botão "copiar brief".
- Brief de 7 linhas no topo.

**Critério de aceite:** o criador consegue pedir um efeito usando 3–6 cards e o brief, sem termos técnicos novos.

### Fase 1 — Diagnóstico A/B (sem efeito novo)

**Entrega:** comparar **um** efeito de referência no HTML/Quarks e no Godot, na mesma câmera/tempo, e listar as diferenças concretas (bloom, escala, timing, animação, composição, camadas).

**Critério de aceite:** lista priorizada do que falta; nenhuma suposição.

### Fase 2 — Um impacto (primeiro corte)

**Entrega:** escolher **um** Move (recomendado: Tackle/Brick Break, referência D-041) e construir **só o impacto** como shot:
- contato real (frame do clipe + ponto no alvo);
- silhueta direcional (cone/crescente), flash, cacos, poeira, anel no chão, luz;
- no máximo **5–7 camadas**;
- personagens reais, câmera do jogo, normal + espelhado, vídeo.

**Critério de aceite:** o impacto lê em 3 quadros; nada sobra; A/B contra D-041; aprovação do criador.

### Fase 3 — O shot completo

**Entrega:** prelúdio do ataque, wind-up, release, trajeto, impacto e retorno do mesmo Move. Um ajuste por vez.

**Critério de aceite:** vídeo normal + espelhado; checklist do criador item a item; sem regressão de regra.

### Fase 4 — Segundo Move/elemento

**Entrega:** repetir o pipeline em outro Move/família, medindo tempo, camadas, orçamento e reuso.

**Critério de aceite:** o pipeline é reutilizável sem começar do zero.

### Fase 5 — Ferramentas e escala

**Entrega:** decisão de toolchain (Pixelpart, EmberGen, Quarks, Pixel Dreamer, packs) com teste em projeto separado; documentar licenças e compatibilidade.

**Critério de aceite:** uma ferramenta escolhida por evidência, não por entusiasmo.

## 5. Quality gate (obrigatório em toda fase)

- Batalha real (`scenes/debug/vfx_room.tscn`), **personagens reais**, câmera do jogo.
- **Vista normal e espelhada**, no mesmo vídeo.
- Quadros em tamanho real nos instantes do checklist; procurar também **o que não deveria existir**.
- A/B contra a referência aprovada, mesma semente quando aplicável.
- Orçamento medido: nós, triângulos, luzes, overdraw; nada sobra aos 4 s.
- Nada de dano, acerto, esquiva, duração ou alcance alterados.
- Nada de personagem/time/lado fixo (D-235).
- Tamanho medido na tela, para ler igual nas duas vistas.

## 6. Ferramentas e assets

**Já instaladas:** VFX Animation Player, Brackeys Particle Controls, TrailRenderer (MIT).
**Candidatas externas:** Pixelpart (editor pago + plugin MIT), EmberGen (flipbooks, pago/trial), Quarks (HTML, referência do criador), Pixel Dreamer VFX Collection (pago, 1.187 efeitos), Vefects/FULGUR (Forward+, não recomendados), Particle Scene Compositor (MIT, instalação complexa).
**Regra:** testar em projeto separado; não instalar pacote pago sem decisão; checar licença e GL Compatibility.

## 7. Restrições e não-objetivos

- Não alterar regra de combate, dano, ATB, Evade, duração ou alcance.
- Não reintroduzir o experimento melee descartado.
- Não usar GPUParticles/decals/sub-emitters/particle trails de GPU.
- Não prometer bloom sem decisão de cena inteira.
- Não criar efeito novo antes de o pipeline e a régua serem aprovados.
- Não comparar o MC com um shot final: o MC é uma camada, não o produto.

## 8. Riscos e mitigações

| Risco | Mitigação |
|---|---|
| Escopo explodir | Uma fase por vez, um Move por vez, um ajuste por vez. |
| Ferramenta não funcionar no GL Compatibility | Teste isolado antes de integrar; preferir flipbooks/malhas. |
| Pacote pronto não casar com o estilo | Usar como peça/layer, não como efeito final; régua D-041/Abra. |
| Performance | Orçamento desde o primeiro corte; medir nós/tris/luzes. |
| Perder o que já funciona | Nenhum efeito existente é alterado; branch/scratch. |
| Licença de asset | Checar antes de instalar/comercializar. |

## 9. Perguntas para a IA revisora

1. A divisão **herói por shot + secundário no Composer** é a mais robusta para este projeto? Há alternativa melhor?
2. O primeiro corte deveria ser **só o impacto** ou o shot completo? Por quê?
3. Como medir "qualidade" de forma objetiva sem cair em gosto pessoal?
4. Qual toolchain é mais realista: **EmberGen + Godot**, **Pixelpart**, **Quarks + flipbook** ou **packs prontos**?
5. O que está faltando no pipeline (câmera, luz, post, LOD, orçamento, versionamento de presets)?
6. Qual seria o **primeiro entregável** que prova a tese com o menor risco?

## 10. O que não fazer

- Não começar codando um efeito antes de o pipeline e a régua serem aprovados.
- Não tentar "consertar" o MC para o golpe principal; ele é secundário por decisão.
- Não usar o laboratório com marcadores como prova final; a prova é a batalha real com personagens.
- Não adicionar camadas sem função; a V1 melee mostrou que 31 camadas não salvam uma silhueta.
