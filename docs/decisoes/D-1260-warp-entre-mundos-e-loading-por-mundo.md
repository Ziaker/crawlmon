> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Nenhum teste >1 min; crie cenário/controle (`--nht-auto --nht-summary --nht-shots`). **MOVE = 3D (D-1222).**

# D-1260 — Warp entre mundos, loading por mundo e placa do local

Estado: **respondida em parte; visual pendente.** Relacionadas: D-1214, D-1219, D-1237, D-1238, D-1208.

## Frases literais do criador (resumo do que ele pediu, sem acréscimos meus)
- O warp deve funcionar com o jogador ESCOLHENDO o lugar e depois ENTRANDO NO PORTAL que surge com a cor característica do mundo, em vez de só escolher na opção.
- Ao entrar num mundo deve haver uma cutscene IGUAL à de entrada no hub (queda do céu, círculo de invocação, câmera), agora dentro do mundo.
- Cores: "siga a mesma paleta de cores do mundo; por exemplo Murky Forest tem verde, roxo e um outro verde mais escuro".
- Limestone Cavern e Temporal Spire "não precisam estar ali": só a Murky Forest existe por ora.
- Loading: o visual das ondas verdes e marrons É o loading; REMOVER os pontinhos; AUMENTAR o número de ondas; cores das ondas baseadas na color scheme do MUNDO em que o jogador entra.
- Placa torta, em forma de paralelogramo, com o NOME DO LOCAL para onde os personagens estão indo (ex.: "MURKY FOREST").

## Decisões
1. Só a Murky Forest no gate; linhas LOCKED removidas. Estrutura em dados por mundo (nome + paleta), nada hardcoded.
2. Mecânica de nature/expedição inalterada (D-1219).

## Respostas da 2ª rodada (frases literais)
- Ondas: "cada uma surge a cada segundo e se separam em forma meio funil pra indicar o raio que vai surgir do céu".
- Loading indo ao Hub: manter as cores atuais (#051322, #d6fa66, #f0c57e) — "perfeito".
- Escolha do lugar: painel só como escolha, fecha ao confirmar — "sim".
- Portal: "mas é JUSTO ESSE, por que seria outro???" (é o próprio Expedition Gate, mudando para a cor do mundo) e "adicione uma cutscene com faixas pretas quando o jogador confirmar pra vermos o portal surgindo em forma procedural de espiral".
- Placa: "similar da forma que é feita as caixas de dialogo, badges dos icones dos personagens (as redondas obviamente das caixas de dialogo) são estampadas no lado inferior direito extremo, tendo uma para cada personagem presente no grupo) em uma animação com entrada e impacto".
- Paleta do loading: aceita a extraída (verde #298c59, roxo #472e6b, verde escuro #144d42) — resposta implícita à pergunta 1, a confirmar.

## Pendente (perguntar antes de implementar)
- Como o portal surge (animação, onde, forma, mesmo Gate mudando de cor ou novo) e como se escolhe o lugar.
- Quantas ondas; cores do loading ao ir para o Hub.
- Placa: tamanho, posição, tipografia, cores, animação.
- Paleta de cada mundo: valores extraídos da cena (a confirmar pelo criador).

## Estado da implementação (2026-11-16)
Feito: `scripts/world/world_defs.gd` (nome+paleta por mundo), gate só com Murky Forest, portal do próprio gate abrindo em espiral com as cores do mundo sob faixas pretas, caminhada para dentro, loading com ondas por segundo em funil (cores do mundo, sem pontinhos) e placa com badges, gancho de chegada na Murky Forest. Debug: `--warp=murky_forest [--party] [--nht-load-min=ms] --nht-shots=<dir> --nht-summary --nht-quit`.
Fechado nesta sessão: câmera top-down até o pouso (hub e mundos) com o que cobre a personagem ficando transparente; loading com as ondas do próprio carimbo em funil de perspectiva; placa no estilo da DialogueBox (card C, sem nameplate) com badges carimbados (opção A) metade dentro, metade fora na ponta inferior direita. O criador aprovou o resultado.
