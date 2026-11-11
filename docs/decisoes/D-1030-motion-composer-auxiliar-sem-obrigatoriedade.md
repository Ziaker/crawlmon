# D-1030 — Motion Composer é auxiliar; nenhum VFX é obrigado a usá-lo

- **Data:** 2026-11-09
- **Área:** VFX / Processo / Documentação
- **Origem:** resposta do criador à auditoria das ferramentas de VFX (D-1020).

## Frase literal do criador

> "suma com todas menções ao composer ser obrigatório, ele é auxiliar"

## Decisão

1. O **Motion Composer é auxiliar e opcional**. Nenhum VFX de Move/elemento é obrigado a passar por ele.
2. O efeito principal pode ser feito **à mão** com animação, malhas, flipbooks, shaders, partículas e câmera, como já ocorre nos projéteis (D-954/D-956).
3. Quando o Composer ajudar, ele pode cuidar do **movimento secundário e do timing** (poeira, brasas, fumaça, cacos, rastros, ondas, campos e variações determinísticas). Isso não é uma etapa obrigatória.
4. Ficam **removidas as exigências de obrigatoriedade** de:
   - `AGENTS.md` §8, item 3;
   - `docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md` (regra-mãe, construção e correção);
   - `docs/decisoes/D-308-...` item 4;
   - notas operacionais de D-322, D-323, D-335 e D-337 que tratem o Composer como gate.
5. O restante da D-308 continua: vídeo normal + espelhado, quatro fases, transição contínua, qualidade real do Godot, checklist literal, um ajuste por vez e aprovação do criador. A D-308 item 4 fica **superada** por esta decisão.
6. A ordem de D-323 ("melhorar o Composer antes de qualquer efeito") **deixa de ser um gate**. O Composer pode ser melhorado quando o efeito escolhido precisar dele; não é pré-requisito para os efeitos feitos à mão.
7. A D-019 foi **renovada** pelo criador em 2026-11-09 (D-1040): volta a valer. A divergência A2 fica como histórico resolvido.
8. **Nada de código de jogo foi alterado por esta decisão.** É atualização documental.

## Ambiguidades em aberto

Nenhuma. "Auxiliar" foi lido como opcional, não como gate.

## Estado

Documentação atualizada. Código inalterado. Sem commit/push.
