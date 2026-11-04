# D-204 — Rodada 71 Q1 (1A): K único compartilhado por VIT e SPI

- **Data:** 2026-11-04.
- **Área:** Combate / defesa natural / calibração de VIT e SPI.
- **Origem:** escolha expressa do criador, Rodada 71.
- **Estado:** regra de design aprovada; **valor de K ainda não definido nem validado**; não implementada nesta atividade.

## Declaração literal do criador

> 1A — Usar um único valor de K compartilhado por VIT e SPI.

## Regra aprovada

- Na **curva racional de mitigação natural** aprovada em **D-201**, usar **um só parâmetro positivo K**, com o **mesmo valor numérico para Vitality (VIT) e Spirit (SPI)**:
  - `R_físico(VIT) = VIT / (VIT + K)`;
  - `R_mágico(SPI) = SPI / (SPI + K)`;
  - **o mesmo K > 0** aparece em ambas as expressões.
- Preservar D-130/D-138: VIT fornece resistência natural apenas ao dano físico, SPI apenas ao mágico/especial; a estrutura e o K iguais **não confundem as categorias de dano**. Preservar D-193 (defesa natural antes dos estágios comuns de DEF), D-198 (precisão até o arredondamento final), D-194 (mínimo salvo imunidade ou bloqueio) e D-139 (sem teto permanente de 100 atributos).
- **Exemplo puramente matemático:** se, para ilustração, `VIT = SPI = 50` e `K = 100`, ambos dariam `50 / 150 ≈ 33,33%` de mitigação natural nas respectivas categorias. **O número K=100 é fictício; não foi recomendado, calibrado, medido nem aprovado.**

## Limites e pendências

- **O valor concreto de K e a metodologia de calibração/validação continuam pendentes**. Não escolher K, tolerâncias, regras novas de resistência, limiares ou curvas por espécie por dedução.
- Esta decisão complementa a D-201 e resolve apenas a antiga pendência de usar K igual ou distinto para VIT/SPI, preservando o texto histórico daquela decisão.
- Somente registro documental; nenhuma alteração de código, testes, fichas de Moves, cenas, VFX ou assets.
