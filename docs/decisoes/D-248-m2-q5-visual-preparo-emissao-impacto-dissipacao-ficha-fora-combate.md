# D-248 — Fichas de Moves M2-Q5: descrição visual externa ao combate organizada por fases

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / Rodada M2 / questão 5.
- **Origem:** escolha **5A** expressamente enviada pelo criador, sem observações próprias.
- **Estado:** regra de design documental aprovada; **não implementada** nesta atividade.

## Declaração literal do criador

> 5A — Na ficha fora de combate, dividir a descrição visual em preparação, movimento ou emissão, impacto e dissipação, quando aplicáveis.

> Observações e regras próprias: Nenhuma.

## Regra aprovada, exemplos e limites

- Na **ficha consultada fora de combate**, organizar a **descrição visual** de cada Move por **preparação**, **movimento ou emissão**, **impacto** e **dissipação**, **quando aplicáveis**. Não inventar fase para um Move que não a utilize ou detalhar uma fase ainda não descrita oficialmente.
- Preservar **D-229/D-230**: a **tooltip em combate** apresenta apenas metadados acima e descrição **mecânica integrada, com dano/cura em números**. Não transferir para ela partículas, estilo cinematográfico ou instruções de VFX. Mencionar projétil, movimento ou contato na tooltip apenas se necessários para esclarecer o funcionamento mecânico.
- Preservar **D-235/AGENTS.md §7**: VFX e fases não dependem de personagem, espécie, equipe, lado da arena nem posição/câmera fixa; referenciam atacante, alvo e dimensões reais, e um mesmo Move deve funcionar em qualquer lado.
- **Exemplo esquemático, sem criar arte:** na descrição visual de um Move que efetivamente tem projétil, os campos podem ser `preparação: [pendente]`, `emissão: [pendente]`, `impacto: [pendente]`, `dissipação: [pendente]`. Nenhum visual, animação ou tempo foi aprovado por essa anotação.
- **Pendências:** descrição artística de cada Move, tempos/cues de cada fase, coordenadas relativas ao modelo, recursos visuais específicos, câmera e integração ao runtime. A escolha é somente de **organização documental**; não autoriza implementação.

## Relações e escopo

- **Decisões relacionadas:** D-003/D-042–D-046/D-077/D-229/D-230/D-235.
- **Processo:** registrar conforme D-061, preservar histórico, conflitos e descrições anteriores; não interpretar autorização documental como implementação.
- **Somente documentação:** nenhum código, Move/ficha operacional, IA, HUD, teste, cena, animação, VFX, asset ou dependência alterado por este registro.
