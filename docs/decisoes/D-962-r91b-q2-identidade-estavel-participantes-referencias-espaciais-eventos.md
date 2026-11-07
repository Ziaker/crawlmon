# D-962 — Rodada 91B Q2 (2A): participantes estáveis e referências espaciais mecânicas nos eventos

- **Data:** 2026-11-07.
- **Área:** Engine de Moves / eventos estruturados / identificação espacial dos participantes.
- **Origem:** resposta **“Tudo A continue”**, aprovando a alternativa A da questão 2 da Rodada 91B.
- **Estado:** requisito aprovado; **não implementado nem testado**.

## Declaração literal

> Tudo A continue

## Alternativa 2A aprovada (texto apresentado ao criador)

> Eventos mantêm IDs estáveis dos participantes e referências espaciais do instante mecânico; o visual usa transformações reais disponíveis, respeitando as regras aprovadas quando um participante desaparece.

## Regra aprovada

- Os eventos do Move **preservam IDs estáveis dos participantes** envolvidos e as **referências espaciais pertinentes ao instante mecânico** em que ocorreram.
- A apresentação visual deve usar **transformações reais disponíveis** dos participantes, observando as regras já aprovadas para morte, saída, alteração de posição, perda de alvo e cancelamento. **Não criar coordenadas, participantes substitutos, impactos ou retarget** por inferência.
- Preservar D-362/D-959 (identidade da declaração/ocorrência/evento e participantes), D-348/D-954 (instantes mecânicos autoritativos), D-235/AGENTS.md §7 (mesmo Move para qualquer personagem, equipe, anatomia e lado; derivar do atacante e alvo reais).
- **Exemplo não normativo:** um projétil está em voo e o alvo deixa de existir. O evento continua identificando o alvo original, mas sua apresentação respeita as regras já homologadas de término sem dano quando não houver alvo válido, sem usar um nó destruído ou uma posição presumida.

## Limites e pendências

- **Não definidos:** esquema de referência espacial, transformação/localidade, captura e retenção de amostras, tratamento técnico de nós removidos, interpolação/extrapolação, origem de coordenadas, buffers, precisão ou representação de snapshots. Isso não altera as regras existentes de retarget, interceptação e projéteis.
- **Somente documentação; nenhum código, Move, Resource, VFX, cena ou teste modificado.**
