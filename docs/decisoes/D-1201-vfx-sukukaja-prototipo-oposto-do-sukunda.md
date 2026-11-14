# D-1201 — VFX do Sukukaja: protótipo HTML como oposto do Sukunda

> Nota: este documento foi escrito na sessão do protótipo como "D-1196" (branch `claude/adoring-hodgkin-c704e2`, commit `524bc8c2`). Foi trazido para este checkout com o número D-1201 porque o D-1196 daqui já é "Dig e Sand Attack". O texto abaixo é o original, com o número trocado.

- **Data:** 2026-11-12
- **Área:** Visual / VFX (protótipo HTML)
- **Origem:** Conversa com o criador

## O que o criador disse (literal)

> o Sukukaja é o OPOSTO do Sukunda, que já existe no jogo, então é só fazer algo SEMELHANTE ao Sukunda. NÃO é projétil.
> "para fins de teste outra cor, va pelo que recomenda"
> "imagino que tudo" (sobre quais partes do Sukunda se invertem)
> Popup: "AGI + 1"
> Duração/fases: "1,00 s, só as partes do Sukunda"
> Alvo: "No alvo escolhido, como o Sukunda"
> "reduza a opacidade de tudo em 25%"
> Sobre o resultado: "perfeito"

## Decisão

1. O Sukukaja (buff de agilidade) **não é projétil**. É um efeito no alvo, base: o Sukunda (D-035, D-037), com **todas** as partes invertidas.
2. **Cor de teste:** `#5FD8FF` (ciano; recomendada para não colidir com lima, coral, ouro e o roxo do Mago). Definitiva a confirmar.
3. **Inversões em relação ao Sukunda:**
   - relógio/engrenagem no chão destrava e acelera (o Sukunda gira e trava);
   - faixas de estase nos tornozelos soltam e se abrem (o Sukunda contrai);
   - 3 anéis sobem e se abrem (o Sukunda desce e fecha);
   - 6 cubos orbitais sobem e se afastam girando mais rápido;
   - cone central aponta para cima e sobe;
   - sem stutter no alvo (inverso do Sukunda).
4. **Popup:** `AGI + 1`. **Duração:** 1,00 s. **Alvo:** o combatente escolhido, derivado só da posição do alvo (D-235: sem personagem, time ou lado).
5. **Melhorias visuais aprovadas pelo criador:** rastros de velocidade em espiral, cone mais leve, entrada rápida com dissolução no fim, popup acima do efeito e selo do chão maior com destrave marcado.
6. **Opacidade:** todo o efeito e o texto 25% mais transparentes (alfa ×0,75).

## Ambiguidades em aberto

- Cor `#5FD8FF` é "para fins de teste": falta o criador confirmar a cor definitiva.
- Retícula no torso (D-037) não foi incluída no protótipo, por não existir no código do jogo.
- Implementação no Godot ainda não pedida.
- O criador depois definiu o Sukukaja **em grupo** (D-1198): o protótipo mostra o efeito em um único alvo escolhido; como o efeito se repete nos demais aliados é pendente.

## Estado no código

- Só protótipo HTML: `prototypes/sukukaja/sukukaja.html` (agora também neste checkout, não commitado). Nada no Godot.
- Verificado no navegador em instantes selecionados, vistas normal e espelhada. Não verificado: `vfx_room`, auditorias do protocolo, vídeo, movimento contínuo.
