# D-324 — Escudos: reaplicação, empilhamento e prioridade de absorção

- **Data:** 2026-11-05.
- **Área:** Combate / camadas de escudo.
- **Origem:** respostas diretas do criador à auditoria de Bubble Shield.
- **Estado:** regras de design expressamente aprovadas; detalhes de implementação e tipagem pendentes.

## Declarações literais do criador

> Bubble Shield usado novamente Soma resistência, substitui o escudo anterior ou renova duração? Reseta exceto se for dito no efeito que stacka com equivalentes anteriores do mesmo move. Já outros tipos de escudos de dano sem tipagem específica, ele stacka, a prioridade é: escudo de tipo  > escudo sem tipo > vida. Então pode ter 25 de shield físico e 30 de shield sem tipo

> Dois Moves diferentes concedem escudo Escudos coexistem em reservas distintas ou usam uma reserva unificada? Já expliquei

## Regras expressas

1. **Reaplicação do mesmo Move:** o escudo **reseta**, salvo quando a descrição específica do efeito determinar expressamente que ele acumula (stacka) com aplicações anteriores do mesmo Move. Não assumir empilhamento do mesmo Move por padrão.
2. **Coexistência:** escudos de diferentes naturezas podem coexistir; escudos de dano **sem tipagem específica** podem acumular conforme declarado pelo criador. Não fundir automaticamente todos os escudos à vida.
3. **Prioridade de absorção:** **escudo tipado > escudo sem tipo > HP**.
4. **Exemplo expressamente fornecido:** um combatente pode ter, ao mesmo tempo, **25 de escudo físico** e **30 de escudo sem tipo**. Esses valores são ilustrativos, não parâmetros de Bubble Shield.

## Pendências não decididas

- Qual é a **categoria defensiva da reserva do Bubble Shield**? O Move é de elemento Água (D-323), mas isso não é equiparável automaticamente a escudo tipado Água.
- Quando um escudo tipado pode absorver dano (somente do tipo correspondente, de categorias agregadas ou de outros tipos)? Não inferir.
- "Reseta" foi aprovado como comportamento, mas **se isso repõe magnitude, duração ou ambos** não foi discriminado expressamente.
- Regras de ordem entre vários escudos do **mesmo nível de prioridade**, múltiplos escudos sem tipo, e exceções declaradas por Move permanecem por especificar.
- Ausência de regra aprovada sobre conversão/reembolso de resistência excedente ao alternar reservas; não criar uma.
- Duração, pausa, expiração e operações simultâneas deverão respeitar o relógio e a ordenação aprovados.

## Escopo

Registro documental conforme D-061. Nenhum código, efeito, cena, teste ou ficha operacional implementado.
