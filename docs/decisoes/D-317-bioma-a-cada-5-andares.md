# D-317 — Bioma muda a cada 5 andares

- **Data:** 2026-11-05
- **Área:** Exploração / visual
- **Origem:** Conversa (respostas Q9 e F5 do plano do overworld)

## O que o criador disse (literal)

- Q9 — frequência: > A cada 5 andares
- F5 — com 5 andares: > Troca no 5º andar
- F5 — espécies: > não é necessário ainda, não vamos importar mais modelos por ora

## Decisão

1. O bioma é **sorteado por dungeon**. Os **4 primeiros andares** usam um bioma; o **5º andar** usa **outro bioma sorteado**, e a **nova dungeon continua com esse bioma**.
2. **Não é necessário definir espécies por bioma agora** e **não serão importados novos modelos** nesta fase; usar os sprites overworld existentes.

## Ambiguidades em aberto

- O sorteio é uniforme entre floresta/fortaleza/caverna?
- O bioma do 5º andar é sorteado entre os outros dois, ou pode repetir o dos 4 primeiros?

## Estado no código

Não implementado. Detalha a D-312.
