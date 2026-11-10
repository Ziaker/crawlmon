# D-1085 — Prompt de interação `[Z] TALK` e idioma das falas de NPC

- **Data:** 2026-11-09.
- **Área:** Exploração / UI / diálogo.
- **Relacionadas:** D-1063 (NPCs/prompt/diálogo), D-1075 (prompt sempre visível), D-413 (UI em inglês), D-1023 (lab).
- **Status:** **teste implementado e verificado** no lab isolado; batalha, 2D, HUD/status, cards e regras não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> 1 - opção de conversar com NPC, seguindo a mesma tipografia e visual torto, com o ícone do botão na esquerda e o que ele faz na direita: "(Z) Talk"

Respostas desta rodada:

> 3- A

> 2 - B

> de resto vamos com suas recomendações

## Decisão

1. **É só o prompt de interação**, não um menu com opções.
2. **Visual:** mesma tipografia pesada e o mesmo *shear*/paralelogramo dos cards de status (D-1074). Keycap `[Z]` à esquerda, `TALK` à direita; `E` como alternativa discreta; nome do NPC em texto menor.
3. **Posição:** embaixo no centro, na mesma área do prompt atual.
4. **Com o diálogo aberto:** o prompt vira `[Z] CLOSE` (depois pode virar `[Z] NEXT`).
5. **Idioma:** as falas dos NPCs continuam em **português** (exceção expressa a D-413); o prompt e os rótulos de UI ficam em **inglês**. O resto da UI continua em inglês por D-413.
6. **Porta/saída:** o prompt da porta continua o label atual; o prompt novo é só para NPCs.
7. **Não muda:** batalha, 2D, HUD/status, cards, câmera, NPCs, regras.

## Ambiguidades

- Posição exata do nome (resolvida: linha menor dentro do prompt).
- Keycap `Z` com `E` pequeno (resolvido).
- Texto de fechar (`CLOSE` vs `NEXT`) será ajustado quando o diálogo tiver páginas/escolhas.

## Teste implementado (2026-11-09)

- **Prompt:** `[Z] TALK` com keycap à esquerda, `E` pequeno, `TALK` e o nome do NPC; mesmo *shear* e tipografia pesada dos cards D-1074; embaixo no centro.
- **Fluxo:** perto do Bulbasaur, prompt visível com `action=TALK` e ícone `quest`; ao interagir, `action=CLOSE`, painel aberto, `talked=true` e ícone `talked`; ao fechar, `action=TALK`, painel fechado e ícone continua `talked`.
- **Prova:** `docs/referencias/exploracao/3d/murky_forest_prompt_z_talk.png`.
- **Idioma:** a fala do NPC continua em português; o prompt/UI está em inglês (exceção expressa a D-413).
- **Porta:** o prompt da porta continua o label antigo, separado do prompt de NPC.

## O que não foi verificado

- Outras resoluções/aspectos e 60 fps.
- O prompt com nomes muito longos (há truncamento em 24 caracteres).
- A cena principal em headless continua bloqueada pelos erros de VFX de outra sessão; teste no lab isolado.

## Estado

Teste implementado e verificado no lab isolado. Prompt `[Z] TALK` funcional, com o fluxo TALK/CLOSE e o ícone de conversa. Commit local; **sem push**.
