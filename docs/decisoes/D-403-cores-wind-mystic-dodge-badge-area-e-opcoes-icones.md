# D-403 — Cores de Fundo (Wind, Mystic, Dodge), Badge de Efeito em Área e Opções Visuais

- **Data:** 2026-11-07
- **Área:** UI / Moves / Alcance / Elementos / Combate / Regras
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; laboratório de prototipação atualizado; documentação oficial atualizada; aguarda seleção do criador para os glifos definitivos de Dodge, Mystic e Wind.

## Declaração literal do criador

> #4ff7ba fundo do wind
> #65B5B3 fundo do mystic
> #fcb900 fundo do dodge novo, pra não correlacionar com o fundo do eletric
> 
> adicione uma badge nova pro tipo e atualize as regras, é o equivalente a moves de efeito em área mas sem processo de trajeto tipo o media e outros moves futuros, Apenas um círculo básico aberto sem fundo no meio. Branco também
> 
> refaça o icone do dodge, o pé está péssimo ou sugira 3 opções alternativas pro icone do dodge,mystic e wind

## Regras aprovadas

1. **Cores de Fundo Oficiais Atualizadas:**
   - **Wind:** Fundo oficial passa a ser `#4ff7ba` (verde-menta neon de alto impacto).
   - **Mystic:** Fundo oficial passa a ser `#65B5B3` (azul-petróleo celestial / teal cósmico).
   - **Dodge:** Fundo oficial passa a ser `#fcb900` (âmbar dourado quente, garantindo distinção absoluta contra o amarelo de Electric `#facc15`).

2. **Nova Badge: Efeito em Área (sem trajeto):**
   - **Glifo:** Círculo básico aberto sem preenchimento central (`○`).
   - **Visual:** Fundo branco com contorno preto (`bg-white text-black`), mantendo a consistência com as demais badges de entrega/alcance de combate (D-396).
   - **Comportamento de Jogo:** Representa movimentos de efeito em área que atingem múltiplos alvos simultaneamente sem trajeto balístico ou transladação física (exemplo canônico: *Media*, que cura instantaneamente o grupo sem emitir projétil).

3. **Revisão e Opções de Glifos para Dodge, Mystic e Wind:**
   - O laboratório visual (`prototypes/icones_moves_lab.html`) implementa 3 opções conceituais distintas para cada um dos três elementos/ações para seleção do criador:
     - **Dodge:**
       - *Opção A:* Rastro Fantasma / Afterimage de Evasão Lateral (duas silhuetas em deslocamento rápido).
       - *Opção B:* Flecha Dupla de Esquiva / Sidestep Swerve (trajetórias angulares contornando impacto).
       - *Opção C:* Asa de Agilidade / Penas Velozes (leveza e evasão acrobática).
     - **Mystic (Almighty):**
       - *Opção A:* Orbe Cósmico Facetado com Anel Orbital (Megido / Megidolaon).
       - *Opção B:* Singularidade / Vórtice Dimensional (distorção gravitacional cósmica).
       - *Opção C:* Sigilo Transcendental de 8 Pontas (runa geométrica arcana).
     - **Wind:**
       - *Opção A:* Tríscele Aerodinâmico de 3 Lâminas em Vórtice (SMT V Force / P5 Garu).
       - *Opção B:* Tornado Espiral Cônico (ciclone ascendente contínuo).
       - *Opção C:* Foices Duplas de Vendaval (cortes curvos kamaitachi).

## Relação com decisões anteriores

- Modifica as paletas de cor definidas em **D-397** e **D-398**.
- Estende a arquitetura de identificação de moves de **D-395**, **D-396** e **D-397**, integrando o marcador de Área (`○`).
