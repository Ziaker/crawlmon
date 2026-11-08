# D-398 — Elemento Mystic (Equivalente a Almighty de Megaten) e Revisão de Wind, Psychic e Sound

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Combate / Regras
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; protótipos visuais atualizados; documentação oficial atualizada.

## Declaração literal do criador

> wind psychic e sound não estão bons, sound precisa remover esse arco e pronto
> 
> De resto cace por referencias no wind de persona/shin megami tensei
> 
> e adicione Mystic como elemento, é o equivalente ao almighty de megaten, coloque nas regras do jogo também

## Regras aprovadas

1. **Novo Elemento Oficial: Mystic (Almighty de Megaten):**
   - O Crawlmon passa a ter **12 elementos oficiais**.
   - **Mystic** é introduzido como o equivalente direto ao elemento **Almighty** (*Bannō*) de *Shin Megami Tensei* e *Persona*.
   - **Mecânica de Combate:** Dano mágico/transcendente puro que ignora as resistências elementais convencionais (dano que não é absorvido nem repelido por afinidades elementais comuns).
   - **Identidade Visual:** Esfera cósmica facetada radiante com flares estelares e anel orbital místico (inspirado em *Megido / Megidolaon* de SMT V). Cor: Lilás Cósmico / Prata Iluminada (`#c084fc` / `#f3e8ff`).

2. **Revisão dos Glifos dos Elementos:**
   - **Sound:** Removidos todos os arcos externos. Permanece exclusivamente a silhueta límpida e sólida da **nota musical**.
   - **Wind (Referência Shin Megami Tensei V / Persona 5):** Inspirado no glifo de *Force (Zan/Garu)* de SMT V e na foice/asa de vendaval de Persona 5: **tríscele aerodinâmico de 3 lâminas curvas de vento cortante em vórtice**.
   - **Psychic (Referência Persona 5 Psy / SMT):** Inspirado no olho hipnótico de P5: **olho místico com espiral hipnótica concêntrica contínua** no núcleo da íris/pupila.

3. **Lista Completa dos 12 Elementos Oficiais (em Inglês):**
   1. **Neutral** (círculo sólido `●`)
   2. **Fire** (labareda ardente)
   3. **Water** (gota fluida)
   4. **Electric** (relâmpago chanfrado)
   5. **Wind** (vórtice de 3 lâminas curvas de vento SMT/P5)
   6. **Psychic** (olho com espiral hipnótica P5)
   7. **Light** (sol sagrado de 8 pontas)
   8. **Dark** (lua crescente abissal)
   9. **Nature** (folha com glândula ácida)
   10. **Sound** (nota musical pura, sem arcos)
   11. **Earth** (picos de montanhas rochosas)
   12. **Mystic** (orbe estelar cósmico / Almighty)

## Relação com decisões anteriores

- Estende **D-118**, **D-396** e **D-397**: consolida o catálogo oficial de 12 elementos, integrando Mystic e aperfeiçoando os glifos de Sound, Wind e Psychic com base no feedback e referências diretas de Atlus.

## Estado no código

- Protótipos visuais atualizados: `prototypes/icones_moves_lab.html` e `prototypes/hud_post_combat.html`.
- Migração no motor Godot (`scripts/data/element.gd`, etc.) aguarda comando do criador.
