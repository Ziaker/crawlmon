# D-362 — PROPOSTA: eventos temporais (calor, chuva e neblina maior)

- **Data:** 2026-11-06
- **Área:** Exploração / visual / clima / VFX
- **Origem:** O criador pediu ideias de eventos temporais depois de a névoa/ambiente por bioma entrar.
- **Status:** **escopo aprovado (D-381):** só visual, os três eventos, frequência rara e distorção temporal. A cadência exata de "raramente", a duração e o mapeamento por bioma ainda estão pendentes. Nada implementado.

## O que o criador disse (literal)

> além disso o que acha de propor eventos temporais, tipo um overlay de calor ondulado meio earthbound, uma animação de chuva caindo no chão com efeitos visuais, neblina maior

## Proposta

Um `WeatherController` na cena de exploração escolhe um clima por bioma/andar, com duração e intervalo determinísticos pelo seed do andar. Tudo **visual**, sem mexer em combate, movimento, colisão, câmera ou geração. O clima entra/sai com fade e não se acumula.

### 1. Calor ondulado (EarthBound)

- Overlay de tela inteira num `CanvasLayer` acima do mapa, abaixo da névoa/UI.
- Shader: duas senoides de deslocamento de UV (`x/y`), ruído lento e um leve RGB shift; color grade âmbar/rosado; scanline opcional bem fraca.
- Intensidade baixa para não atrapalhar a leitura; duração 12–20 s; entrada/saída por fade.
- Biomas: barren, dark wasteland, deep boulder, deep limestone, limestone. Em Temporal, uma variante “distorção temporal” (ondas mais lentas e dessaturadas) pode ser estudada.

### 2. Chuva com respingo no chão

- `GPUParticles2D` de gotas em **espaço de mundo**, emitindo acima da câmera; as gotas caem e reiniciam, sem seguir o personagem.
- Respingo: um emissor de splashes amostra células de chão perto do jogador e cria partículas curtas no piso; um tint/brilho úmido no chão por shader ou overlay.
- Sem colisão real de partícula com TileMap (2D não tem isso pronto); o respingo é dirigido pelas células de chão.
- Biomas: 4th Station, murky forest, spacial cliffs, temporal spire. Nos gelos, **neve** em vez de chuva; no dark wasteland, **cinza**.
- Performance: um sistema de gotas + um de respingos, com limite; sem nós por gota.
- **Correção técnica (D-381):** o projeto é `gl_compatibility`; usar `CPUParticles2D` (ou shader), não `GPUParticles2D`, que o protocolo proíbe.

### 3. Neblina maior

- Reutiliza o `fog_smooth.gdshader`: hoje o explorado é 100% limpo (`EXPLORED_ALPHA = 0`); o clima “neblina” adiciona um **véu de baixa alpha nas células exploradas**, além de aumentar densidade/warp do que já existe.
- Uma vinheta/screen mist suave completa a leitura; a névoa continua com as duas cores laterais por bioma (D-360).
- Biomas: murky forest, spacial cliffs, 7th Station, icicle forest, vast ice, temporal spire/tower.

### 4. Distorção temporal (opcional)

- Em Temporal Tower/Spire: afterimages/clock dust bem sutis, sem alterar regra. Só entra se o criador quiser “tempo” além de clima.

## Ordem de implementação sugerida

1. **Neblina maior** (reusa o shader da névoa; menor risco e já visível).
2. **Calor ondulado** (shader de tela; sem partículas).
3. **Chuva/neve** (partículas + respingo; maior custo).
4. **Distorção temporal** (opcional).

## Limites e protocolo

- **D-308 (VFX):** calor/chuva/neblina são efeitos de ambiente, não Moves. Antes de implementar, eu verifico se o Motion Composer cobre uma representação de tela/partículas de clima; se não cobrir, **atualizo o Motion Composer primeiro** (D-323/D-327), em vez de fazer um efeito avulso. Se o criador considerar que o protocolo de 4 fases não se aplica a clima, preciso da exceção explícita.
- **D-235:** nada depende de personagem, time, lado ou posição fixa; a chuva cai no mundo e o calor é de tela.
- **D-344/D-329:** câmera 2,3×, 48 px, geração e colisão intactas.
- **Performance:** um overlay de tela + no máximo dois sistemas de partículas; medir antes/depois.
- **Água decorativa** (D-357) continua pendente e é independente; a chuva não usa os tiles de Water do sheet.

## Perguntas para o criador

1. Clima é **só visual** ou afeta algo (ex.: escorregar, visibilidade)? Recomendo só visual.
2. Quer os três (calor, chuva, neblina) ou começamos pela neblina?
3. Frequência: um clima por andar, ou eventos aleatórios a cada 40–90 s?
4. A distorção temporal em Temporal Tower/Spire entra ou fica fora?

## Respostas do criador (2026-11-06)

> 1 - so visual

> 2 - sim

> 3 - raramente

> 4 - acho que sim

Registradas em D-381. A cadência exata de "raramente" e a duração ainda não foram definidas.

Nada foi implementado ou publicado.
