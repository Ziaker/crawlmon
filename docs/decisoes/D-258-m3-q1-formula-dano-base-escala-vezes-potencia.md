# D-258 — Fichas de Moves M3-Q1 (1A): somar dano-base e escala antes da potência individual

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / Rodada M3, questão 1.
- **Origem:** decisão expressa do criador (1A).
- **Estado:** regra de design aprovada e documentada; implementação e dados individuais pendentes.

## Declaração literal do criador

> 11A — Adotar (dano-base + coeficiente de STR/MAG × atributo) × potência individual do Move, antes dos demais modificadores já aprovados.

> Observações e regras próprias: Tudo q não é tackle consome MP , não existe previa de dano em seleção e não deve existir, pare de inventar coisa que eu não pedi

## Regra aprovada, alcance e exemplos

- A expressão para a parcela ofensiva inicial do dano de um Move é **(dano-base + coeficiente STR/MAG × valor do atributo aplicável) × potência individual do Move**; **somente depois** entram os demais modificadores de dano já aprovados.

- Manter **dano-base**, **categoria física/mágica**, **coeficiente de atributo** e **potência** como informações separadas da ficha, conforme D-244. Pela D-122, usar STR para dano físico e MAG para dano mágico/especial; não inferir categoria de dano pelo tipo de deslocamento/execução.

- **Exemplo aritmético hipotético, não oficial:** base 40, coeficiente 0,5, STR 20 e potência 1,3 resultam em (40 + 0,5 × 20) × 1,3 = 65 **antes** dos outros modificadores. **40, 0,5, 20, 1,3 e 65 não são valores de nenhuma ficha homologada.**

- Preservar D-193/D-198/D-205: ordem da resistência natural e DEF quando aplicável, precisão fracionária até concluir os modificadores e um único arredondamento final de dano, com metade exata para cima. Preservar as regras preexistentes de fraqueza/crítico, imunidade e mínimo de dano; esta decisão **não muda a ordem não decidida de outros multiplicadores**.

- Preservar D-229/D-230: tooltip em combate apresenta **dano/cura numérico**, sem mostrar fórmula como substituta do número. **Não autoriza prévia de dano na seleção de alvos**, explicitamente proibida na M3-Q2.

- **Pendências:** dano-base, coeficiente, potência e classificação de cada Move específico, interações de efeitos com múltiplas categorias de dano, valores reais após a implementação dos seis atributos. Não inventar valores oficiais ou fórmula de cura por analogia.

## Histórico, fontes e escopo

- Preservar **D-061**, **D-228–D-230**, **D-235**, **D-244–D-249** e todos os demais requisitos pertinentes. As novas regras não autorizam reescrever os registros históricos para apagar escolhas anteriores, apenas explicitar precedência quando houver alteração expressa.
- **Nenhuma ficha de Move operacional, código, HUD, teste, VFX, asset, cena, configuração ou dependência foi modificada nesta atualização; não foram executados testes de gameplay.**
