# D-032 — Nomes em inglês, rebalanceamento de moves, invulnerabilidade e novos status

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa (Grill-Me)

## O que o criador disse (literal)

> teleporte rapido não faz visualmente o que sua descrição indica, além disso, reduza sua carga pra .5 segundos e seu dano pra 0.7x, dê um custo de 8MP no jogo, além disso, ele some na wind-up do move, não podendo ser acertado por ataques vindos em sua direção, e só surge pra desferir o ataque, atrás do oponente, depois teleporta devolta pra sua posição original
>
> soco rapido: reduz a carga pra .2 segundos, seu dano pra 0.5x e dê um custo de 4mp
>
> golpe de caratê: faça com que sua carga seja de 1sec e tenha 30% de chance de reduzir a velocidade do alvo em 1 estagio ao contato
>
> provocação força o alvo a atacar o seu usuário na sua próxima ação ou na ação que já esteja no wind-up, mas aumenta o atk do mesmo em 1 estágio apenas durante a próxima/ação em wind-up que esteja fazendo
>
> mordida: custo de 2ATB, dano de 1.3x, wind up de 1.2, tem 30% de chance de atordoar o oponente por 2 segundos (quem está atordoado tem seu carregamento de ATB pausado durante a duração do atordoamento, além de não poder realizar ações que não sejam de tática pros aliados)
>
> tiro de areia: wind up de .75 segundos, custo de 1ATB, agora é um projétil que causa efeito de status (desviável por ser projétil), sem dano. Ao contato com o projétil, o alvo fica com cegueira por 4 segundos, tendo 35% de chance de errar seu próximo/ou em wind-up move.
>
> Furia do dragão: 2s de wind up, projétil singular, dano AOE ao contato, no caso, tem um alvo, mas se atingir o mesmo, os seus aliados também sofrem o dano.
>
> investida subterranea: 1s de wind up, invulneravel, sumindo embaixo do chão após o wind up, no trajeto do seu ataque. ao chegar no alvo, ele emerge do chão causando seu dano
>
> usaremos os nomes em ingles dos moves apartir de agora, mude no jogo também

Respostas no Grill-Me:
- MP: "esqueci de colocar o mp do restante, pode riscar a parte do mp"
- Invulnerabilidade no ataque: "erra completamente, exibe MISS! e o inimigo gasta a ação normalmente, não mostra valores de dano"
- Status em invulnerável: "personagens invulneráveis ainda são afetados por efeitos de status"
- Taunt: "taunt só afeta moves de alvo único, inclusive moves de alvo unico com dano aoe, não afeta efeitos de status"
- Atordoamento em wind-up: "cancela e interrompe o ataque que estava preparando... e também o atacante ganha um ponto de ATB caso o interrompa"
- Cegueira duração: "A cegueira permanece ativa pelos 4 segundos inteiros, e TODA ação ofensiva executada dentro desses 4 segundos tem 35% de chance de errar individualmente."
- Dragon Rage no erro: "Se o alvo principal desviar ou estiver invulnerável (MISS), o projétil não detona e os aliados NÃO sofrem dano nenhum. Se acertar o alvo principal, os aliados sofrem o mesmo dano total (1.6x)."
- Nomes em inglês: Mach Punch, Teleport, Karate Chop, Brick Break, Taunt, Confusion, Psybeam, Shock Wave, Bite, Sand Attack, Dragon Claw, Dragon Rage, Dig.

## Decisão

1. **MP descartado**: Os movimentos continuam sem custo de MP, consumindo estritamente ATB.
2. **Nomes em inglês**: O jogo adota nomes oficiais em inglês para todos os movimentos:
   - *Tackle* (Investida)
   - *Mach Punch* (Soco Rápido)
   - *Karate Chop* (Golpe de Caratê)
   - *Brick Break* (Quebra de Telha)
   - *Taunt* (Provocação)
   - *Confusion* (Confusão)
   - *Psybeam* (Raio Psíquico)
   - *Shock Wave* (Onda de Choque)
   - *Teleport* (Teleporte Rápido)
   - *Bite* (Mordida)
   - *Sand Attack* (Tiro de Areia)
   - *Dragon Claw* (Garra do Dragão)
   - *Dragon Rage* (Fúria do Dragão)
   - *Dig* (Investida Subterrânea)
   - SMT: *Media*, *Tarukaja*, *Rakunda*, *Sukunda*, *Mabufula*, *Megido*, *Hassou Tobi*, *Titanomachia*.
3. **Teleport**: Wind-up 0.5s, dano 0.7x, custo 1 ATB. O usuário some durante o wind-up (invulnerável a ataques direcionados; ataques inimigos sofrem MISS! e gastam ação; status ainda afeta). Surge atrás do alvo para golpear e teleporta de volta.
4. **Mach Punch**: Wind-up 0.2s, dano 0.5x, custo 1 ATB.
5. **Karate Chop**: Wind-up 1.0s, dano 1.5x, custo 2 ATB. 30% de chance de aplicar -1 VEL no alvo ao contato.
6. **Taunt**: Custo 1 ATB, wind-up 0.5s. Força o alvo a mirar no provocador na sua próxima ação ou ação em wind-up (apenas para moves de alvo único, inclusive com splash AoE; não afeta status/cura). Concede +1 estágio de ATK ao alvo estritamente durante essa ação provocada.
7. **Bite**: Custo 2 ATB, dano 1.3x, wind-up 1.2s. 30% de chance de atordoar por 2.0s. Atordoado não carrega ATB e só usa táticas. Se o alvo estiver preparando um ataque, o ataque é cancelado e o atacante ganha +1 ATB por interrupção.
8. **Sand Attack**: Custo 1 ATB, wind-up 0.75s, 0 dano. Projétil de status (desviável). Aplica Cegueira por 4.0s: toda ação ofensiva executada nesse período tem 35% de chance de errar (MISS!).
9. **Dragon Rage**: Custo 3 ATB, wind-up 2.0s, dano 1.6x. Projétil singular com dano AoE ao contato. Se o alvo desviar/estiver invulnerável (MISS), o projétil não detona e aliados não sofrem dano. Se acertar, aliados do alvo sofrem o dano total (1.6x).
10. **Dig**: Custo 2 ATB, wind-up 1.0s, dano 1.5x. Invulnerável após o wind-up (trajeto sob o piso). Ataques inimigos sofrem MISS! e gastam ação; status ainda afeta. Emerge no alvo causando o dano.

## Ambiguidades em aberto

Nenhuma. Todas as 8 ramificações foram respondidas e alinhadas via Grill-Me.

## Estado no código

Em implementação nesta sessão.
