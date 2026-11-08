# D-954 — Motion Composer é a camada de movimento secundário, não o autor do golpe

- **Data:** 2026-11-06.
- **Área:** VFX / Motion Composer / pipeline.
- **Origem:** resposta do criador à pergunta “o que o Motion Composer deve ser no projeto?”, depois de reprovar e descartar os resultados do melee (D-953).
- **Estado:** decisão registrada; **VFX segue pausado** até o pipeline por shot ser definido. Nenhum código novo, nenhum efeito alterado, nenhum Move ligado.

## Frase literal do criador

> Camada de movimento secundário

Resposta à pergunta “O que o Motion Composer deve ser no projeto?”.

## Decisão

1. **O Motion Composer é a camada de movimento secundário.** Ele existe para poeira, brasas, fumaça, cacos, detritos, rastros, ondas, campos e variações determinísticas — e para o **timing de fases** (wind-up, prelúdio do ataque, release, trajeto, impacto, retorno).
2. **O golpe principal não é autoral do Composer.** A silhueta do ataque, o contato e o movimento do corpo vêm de um **shot feito à mão**: animação/pose do personagem, frame de contato, afterimages/smear, malhas/flipbooks e câmera/composição.
3. **O Composer não é dono de:** animação esquelética, câmera/composição, escala de tela, materiais finais, post-processing, régua de qualidade ou decisão de acerto. Nada disso muda por causa dele.
4. **Régua de qualidade:** as referências aprovadas do projeto — **HTML/Quarks**, **impacto do Tackle (D-041)** e **Abra v9 (D-170)** — são o alvo. O Composer **apoia** esses shots; não os substitui.
5. **Nada existente muda:** nenhum efeito, Move, regra, tempo ou asset existente é alterado por esta decisão. O experimento melee descartado continua isolado em `tests/`, marcado como REJECTED e sem uso no jogo.
6. **O VFX continua pausado** (D-953) até o pipeline por shot e a primeira régua serem definidos. Esta decisão define o **papel** do Composer, não autoriza implementar efeito.

## O que fica em aberto

- O **pipeline por shot**: quem autora, em que arquivo, com quais ferramentas (AnimationPlayer/Tween, malhas, flipbooks, shaders, câmera) e como o Composer entra só no secundário.
- O **primeiro shot**: qual Move, qual câmera, qual frame de contato e qual referência (HTML/Quarks, D-041 ou outro).
- **Post-processing:** o jogo não tem bloom/glow hoje (D-337); se o alvo é o look do HTML, isso é uma decisão de cena inteira.
- Se o Composer será usado no primeiro shot ou se o primeiro shot será 100% à mão para calibrar a régua.
- Como medir a qualidade: A/B com personagens reais, câmera do jogo, normal + espelhado, um ajuste por vez.

## Relações

D-953, D-308, D-322, D-323, D-235, D-041, D-170, D-061.

## Estado no código

**Nenhum.** Decisão de papel e processo. O VFX está pausado; nenhum código, teste ou efeito novo foi criado por esta decisão.
