# D-130 — Novo atributo Spirit para mitigação mágica; Vitality apenas para mitigação física

- **Data:** 2026-11-03
- **Área:** Atributos / redução de dano físico e mágico.
- **Proveniência:** o criador ordenou criar o atributo defensivo mágico e delegou a escolha do nome. **Spirit (SPI)** é nome selecionado pelo assistente a pedido expresso, não uma palavra literal fornecida pelo criador.
- **Estado:** nova regra de design aprovada, documentada; ainda não implementada no jogo.

## Declaração literal do criador

> Criamos um novo status relacionado a redução de dano mágico, que funciona exatamente como vitalidade. Agora vitalidade é apenas pra dano físico, Me escolha em nome em inglês que tenha uma abreviação de 3 letras boa, além disso todos nomes de status devem ser em inglês.
> Depois retornamos as perguntas

## Regra definida

- Passa a existir um **sexto atributo permanente**: **Spirit (SPI)**. Sua função defensiva é análoga à de **Vitality (VIT)**, mas aplicada exclusivamente à **mitigação de dano mágico/especial**.
- **Vitality (VIT) passa a reduzir somente dano físico**. Para dano mágico/especial, a defesa natural derivada do atributo próprio é **Spirit (SPI)**, e não Vitality.
- **Preservar D-124:** Vitality continua participando do cálculo de **HP máximo** por nível e coeficiente da espécie; a nova frase 'apenas pra dano físico' limita a **resistência a dano**, não revoga expressamente sua função já aprovada no HP.
- **Preservar D-122:** Strength (STR) origina dano físico ofensivo e Magic (MAG) dano mágico/especial ofensivo. Spirit é **resistência ao dano mágico**, não um substituto para Magic ofensiva.
- **Preservar D-129:** os seis atributos permanentes seguem o limite **1–100**; buffs/debuffs temporários são calculados separadamente.
- **Preservar estágios de Defesa (D-125):** a decisão não elimina os buffs e debuffs de Defesa já existentes. Ainda falta decidir se os mesmos estágios modificam igualmente a mitigação física e a mágica ou se há especializações distintas.
- **A redação histórica do modelo de cinco atributos (GDD R10-Q1, D-120, D-129)** e a proibição anterior de criar outro atributo de defesa (D-125) **ficam superadas somente na quantidade do catálogo e na separação defensiva**, devido a esta instrução mais recente do criador.

## Pontos não definidos automaticamente

- Não há fórmula de mitigação física/mágica, coeficientes, arredondamento, limites nem mecanismo de resistência elemental aprovado nesta nova ordem.
- A expressão 'funciona exatamente como Vitality' foi aplicada ao **papel de mitigação** explicitamente especificado. Não autoriza supor que Spirit aumente HP ou MP: as funções de recursos continuam com Vitality/HP e Magic/MP até decisão expressa.
- Não foi definido o impacto do novo atributo sobre curvas de crescimento dos aliados, distribuição do ponto obrigatório do protagonista em Spirit, progressão de Nature e variações individuais, além do limite geral; respeitar regras anteriores sem criar taxa ou peso novo.
- Nenhuma modificação de código, modelos, VFX, testes ou arquivos de personagem nesta atividade.

## Complemento posterior — Rodada 56 (2026-11-03)

**D-138 (Rodada 56, Q4A):** os **estágios atuais de Defense** continuam afetando **danos físicos e mágicos**, enquanto **Vitality (VIT)** determina apenas a resistência natural ao dano físico e **Spirit (SPI)** a resistência natural ao dano mágico. Não criar por esta decisão buffs diferentes para Physical Defense/Magic Defense nem alterar os estágios existentes. A integração matemática com as duas resistências ainda precisa de especificação.
