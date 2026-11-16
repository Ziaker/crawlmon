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

## Pendente (perguntar antes de implementar)
- Como o portal surge (animação, onde, forma, mesmo Gate mudando de cor ou novo) e como se escolhe o lugar.
- Quantas ondas; cores do loading ao ir para o Hub.
- Placa: tamanho, posição, tipografia, cores, animação.
- Paleta de cada mundo: valores extraídos da cena (a confirmar pelo criador).
