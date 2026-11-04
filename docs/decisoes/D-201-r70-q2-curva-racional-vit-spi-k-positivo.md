# D-201 — Rodada 70 Q2 (2A): curva racional de resistência VIT/SPI com K positivo ainda pendente

- **Data:** 2026-11-04.
- **Área:** Combate / atributos defensivos / mitigação natural.
- **Origem:** escolha expressa do criador na Rodada 70.
- **Estado:** família matemática aprovada; valor de K não validado e mecânica não implementada nesta atividade.

## Declaração literal do criador

> 2A — Usar curva racional R(x) = x/(x+K), com K positivo a calibrar e validar posteriormente.

## Regra aprovada

- Para mitigação **natural percentual** derivada de **Vitality (VIT)** ou **Spirit (SPI)**, adotar a **curva racional**:
  
  `R(x) = x / (x + K)`, com `K > 0`.

- `x` corresponde ao valor do **atributo defensivo pertinente**: **VIT para dano físico e SPI para dano mágico/especial** (D-130/D-138). `R(x)` representa a **fração do dano mitigada naturalmente**, a converter em porcentagem quando apresentada em percentual.
- A função tem **ganhos marginais decrescentes** para x não negativo e K positivo e mantém a mesma **estrutura matemática** para VIT e SPI, complementando **D-197**. Não fixar o valor de K, nem supor que parâmetros de VIT e SPI tenham obrigatoriamente valor idêntico quando isso ainda não foi decidido.
- Preservar **D-193**: aplicar a resistência natural antes dos estágios comuns de Defense (DEF). Preservar **D-198**: manter precisão fracionária até o arredondamento único final. Preservar o mínimo de 1 para acertos válidos exceto imunidade ou bloqueio completo (D-194).
- Exemplo **apenas matemático, NÃO calibração aprovada**: se `x=50` e `K=100` fictício, `R=50/(50+100)=1/3`, ou aproximadamente `33,33%` de mitigação natural. **K=100 não é valor oficial, recomendado ou aprovado.**

## Limites e pendências

- **K permanece estritamente pendente de calibração e validação posteriores.** Não foi decidido se VIT e SPI compartilharão um mesmo K numérico ou parâmetros distintos, como selecionar os valores nem se haverá limites adicionais sobre efeitos combinados.
- Não criar resistências elementais, fórmula ofensiva nova, escalas de DEF, coeficientes de Move ou limites para atributos permanentes por inferência. D-139 preserva a inexistência de teto superior dos atributos.
- Somente documentação; sem modificações em código, testes, cenas, Move, VFX ou assets.
