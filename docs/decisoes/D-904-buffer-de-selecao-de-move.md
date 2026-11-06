# D-904 — Seleção de Move na pausa de status e buffer de seleção

> **Renumerada em 2026-11-06:** D-161 → D-904. O ID D-161 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-03
- **Área:** Combate / Menu
- **Origem:** Conversa

## O que o criador disse (literal)

> moves não estão podendo ser selecionados durante a pausa de efeitos de status, corrija isso [...] além disso permita um "buffering" de seleção de move, onde vc pode, após confirmar um move, já selecionar outro pra ser realizado no segundo que finaliza o delay-pós fim de animação e realização do move

Respostas às perguntas:

> opção B só pra ver se pode causar bugs, caso cause muitos, iremos pra opção A

(B = "Fim do golpe, antes do pulo": começa quando a animação do golpe acaba, sem esperar o retorno; na pausa de status, também espera a pausa acabar. A = "Fim do retorno".)

> Paga ao executar

(Uma vaga só; escolher outro substitui. Permite escolher sem ter ATB ainda; se faltar ATB na hora de executar, o move é descartado.)

## Decisão

1. O líder pode escolher um Move durante a pausa de status e durante a própria ação. O Move fica guardado em **uma única vaga**; escolher outro substitui o anterior.
2. **Início (opção A):** quando o golpe atual termina tudo, incluindo o pulo de volta. Durante a pausa de status, espera a pausa acabar (D-031/D-038 preservadas: nada fura a pausa).
3. **Custo:** pago na execução. Dá para escolher sem ATB; se faltar ATB na hora, o Move é descartado.
4. A opção B foi testada e descartada: o preparo seguinte acontecia ao lado do inimigo, o melee seguinte corria sem sair do lugar e, depois de um status, o personagem deslizava de volta para casa. Depois desse resultado, o criador respondeu: "Trocar para A".

## Escolhas do agente, para o criador conferir

- O Move guardado é descartado se o alvo morreu, se o personagem ficou atordoado ou se a ação atual foi interrompida por um golpe (por analogia a D-064/D-065). Como nada foi pago, não há estorno.
- Itens não entram no buffer: não foi pedido.

## Ambiguidades em aberto

D-041/D-035 dizem que o golpe extra do contra-ataque não precisa esperar o retorno; com o buffer na opção A, ele espera. Falta o criador decidir se o contra-ataque é exceção.

## Estado no código

Implementado com a opção A (`battle.gd`, `battle_scene.gd`, `combatant.gd`).
