# D-418 — VFX de Celebração de Nível: Pilar de Energia Dragon Ball e Anéis no Chão sem Flash de Tela

- **Data:** 2026-11-08
- **Área:** Visual / VFX / HUD Post-Combat / Acessibilidade
- **Origem:** Instrução literal do criador via prompt em resposta à tela pós-combate.
- **Estado:** Aprovado em definitivo pelo criador; em vigor imediato.

---

## 1. Declaração literal do criador

> "perfeito, só tira a piscada pq pode dar epilepsia, troque por um pilar de energia, algo meio dragonball com aura boost por .55 segundos e uns aneis que se expandem no chão rapidamente. Seguindo corretamente o angulo da câmera e não obstruindo o visual do personagem, com uma opacidade no pilar, bem baixa"

---

## 2. Regras Aprovadas

1. **Remoção Absoluta de Flashes de Tela (Prevenção de Epilepsia):**
   - É terminantemente proibido utilizar clarões/flashes brancos ou estroboscópicos cobrindo a tela cheia (`screen-flash`), para evitar qualquer risco de fotossensibilidade ou epilepsia.

2. **Pilar de Energia / Aura Boost Dragon Ball (Duração: 0,55 s):**
   - Em vez do flash na tela, o momento de celebração do level up ativa um pilar vertical de energia volumétrica/cilíndrica ao redor do combatente.
   - **Duração exata:** 0,55 segundos (550 ms), com subida enérgica inicial e atenuação suave (*fade out*).
   - **Opacidade baixa e não-obstrutiva:** A opacidade do pilar deve ser mantida intencionalmente muito baixa (15% a 25% com mesclagem aditiva ou translúcida), garantindo que o modelo 3D do personagem permaneça 100% visível e desobstruído durante toda a animação.
   - **Alinhamento de Câmera:** O pilar e a aura são gerados respeitando estritamente o eixo vertical e a perspectiva da câmera da cena.

3. **Anéis de Choque Expansivos no Chão:**
   - Durante os mesmos 0,55 segundos, ondas de choque em formato de anéis concêntricos se propagam no plano do chão ($XZ$) a partir dos pés do personagem, expandindo seu raio rapidamente para fora enquanto se dissipam.
