# D-436 — Revisão do SkillInfoPanel: Desobstrução Visual da Arena e Descrições Técnicas Objetivas dos Moves

**Status:** Aprovada e em Implementação  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-001 (Regras do Jogo no Combate), D-135 (Design System Flat Neo-Brutalist), D-235 (Independência de Personagem/Lado), D-416 (Paralelogramas de ATB), D-417 (Padrão Visual Fichas Flat e Expansão para Todas as HUDs), D-419 (Layout Ficha de Move), D-420 (Fichas sem Repetições e Eixos de Conteúdo), D-434 (Battle Strips e Omissão de 0MP), D-435 (Números de Atalho Sobre Ícones)

---

## 1. Frases Literais do Criador

> *"vamos rever o problema principal*
> 
> *1 - é grande demais e obstrui visão*
> *2 - as descrições estão mal feitas e não resumem corretamente o efeito do move e suas descrições, além de não ter "*
> 
> *(Ao ser consultado sobre a continuação da frase:)*  
> *"esqueci o que era pra faltar mas no geral é isso"*
> 
> *(Ao receber a proposta de card lateral esguio e estrutura de descrições em 3 eixos objetivos:)*  
> *"prossiga"*

---

## 2. Decisão e Diretrizes de Design

### 1. Eliminação da Oclusão Central (Problema 1)
- O painel legado de **480×374px** posicionado no centro da tela (`Vector2(366, 296)`) é formalmente cancelado.
- Os detalhes do Move selecionado no Fight passam a ser exibidos em um **Card Esguio Lateral** (largura de ~260–280px, altura de ~200–220px), ancorado na lateral esquerda junto da seleção de golpes (`x: 295, y: 440`).
- O centro focal da tela, o modelo 3D do inimigo, os marcadores no piso e os balões de telegraph de perigo iminente (`TACKLE > ABRA`) permanecem **100% livres e visíveis** em tempo real durante todo o processo de seleção de golpes.

### 2. Reformulação Completa das Descrições dos Moves (Problema 2)
- Fica proibido o uso de textos genéricos, termos vagos (como *"costs no status"*) e a menção indiscriminada a "ATK" em golpes mágicos que escalam com MAG.
- Seguindo a D-420, toda descrição de habilidade em combate (`scripts/data/skill.gd`) deve ser condensada em 3 linhas objetivas de alta relevância tática:
  1. **Linha 1 — Ação e Entrega Mecânica:** Definição do golpe e sua cinemática de deslocamento (ex.: *"Projétil psíquico teleguiado"*, *"Investida corporal direta"*, *"Feixe concentrado em linha reta"*, *"Descarga elétrica em área"*).
  2. **Linha 2 — Propriedades Táticas Reais:** Efeitos mecânicos concretos em combate (ex.: *"Quebra Guarda (+1 ATB)"*, *"Ignora 25% de redução de guarda"*, *"Concede invulnerabilidade temporal"*, *"Pode interromper canalização inimiga"*).
  3. **Linha 3 — Escala & Timing:** Atributo real de escalamento (`MAG` para habilidades mágicas, `STR` para habilidades físicas) e tempo exato de preparo/wind-up (ex.: *"Escala com 140% MAG · Wind-up: 0.65s"*).

### 3. Eliminação de Redundâncias Visuais (D-420)
- Não repetir no corpo do texto o custo de ATB, o custo de MP nem o nome do elemento, uma vez que esses dados já estão graficamente presentes nos paralelogramas de ATB (`/ /`), no chip de MP (`4MP`) e na cor/marca d'água elemental da ficha (D-417/D-434).

### 4. Independência Estrita de Personagem (D-235)
- Nenhuma descrição ou efeito de move pode conter menções a personagens específicos, lados do campo ou alianças. Todo Move é universal e pode ser executado por qualquer combatente.
