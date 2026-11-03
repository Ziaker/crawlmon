# D-104 — R48-Q2: Evade é evasão; ataques terminam visualmente sem animação de interrupção

- **Data:** 2026-11-03
- **Origem:** declaração literal do criador na Rodada 48.
- **Estado:** declaração recebida e registrada; **conflitos com decisões anteriores permanecem explícitos e exigem confirmação**, sem supor prioridade nem implementação.

## Declaração literal do criador

> 48 2 - Na verdade ambos sao interrompidos, porem o evade nao e uma defesa perfeita, e uma evasao, ou seja, visualmente, os ataques deles devem terminar pra dai serem interrompidos, sem animacao de interrupcao, interrupcao so ocorre se levarem um ataque durante o trajeto ou o wind up de um ataque

## Conteúdo explícito da declaração

- **Ataques simultâneos:** ao realizar o Evade contra dois agressores, o criador diz que **ambos são interrompidos**, porém esclarece que o **Evade é evasão, não defesa perfeita/parry**: visualmente, **os ataques dos dois agressores devem terminar antes de serem tratados como interrompidos**, sem reproduzir uma animação de interrupção em razão somente da esquiva.
- **Animação de interrupção:** só ocorre se o atacante **receber um ataque durante o trajeto ou o wind-up de um ataque**. Apenas desviar de sua investida não deve produzir essa animação.
- **Contra-ataque extra:** conserva-se D-093 (somente um golpe extra quando vários ataques são evitados perfeitamente), enquanto o modo exato de encerrar logicamente os ataques desviados permanece pendente.

## Divergências com regras anteriormente aprovadas (sem resolução automática)

- **D-017:** especifica interrupção imediata com cambaleio quando ocorre Evade corpo a corpo bem-sucedido. A nova declaração retira a **animação de interrupção causada apenas por Evade** e exige conclusão visual dos golpes. **Não escolher silenciosamente** se o ataque termina como falha normal ou como cancelamento lógico posterior, nem quando o antigo estado de 'interrupção' é substituído.
- **D-092:** um Evade pode evitar dois golpes sobrepostos; a nova declaração esclarece a reação visual dos atacantes e não elimina a regra de evitar dano.

## Referências e pontos em aberto

- **Relacionadas:** D-017; D-019; D-030; D-035; D-092; D-093.
- **Pendências:** O termo 'ambos são interrompidos' junto de 'ataques devem terminar visualmente para só então serem interrompidos' requer distinguir encerramento visual e estado lógico; não definir uma nova fase, duração ou animação sem decisão.
- **Escopo:** somente documentação; nenhum código, teste, animação ou FX do jogo é alterado.
