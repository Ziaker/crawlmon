<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1250 — Loja de suprimentos e economia de expedição no Hub

- **Data** — 2026-11-16
- **Área** — Hub 3D / comércio / expedição
- **Estado** — Direção de design aprovada. Implementação e validação pendentes.
- **Relacionadas** — [D-1207](D-1207-pre-jogo-v3-ciclo-campanha-e-hub-3d.md), [D-1208](D-1208-integracao-pre-jogo-hub-3d-e-expedicao.md), [D-1238](D-1238-hub-3d-mais-escuro-detalhado-e-npcs-no-portal.md), [D-1248](D-1248-murky-forest-gatilho-e-ordem.md) e [GDD §7.18–7.20](../GDD.md).

## Frase literal do criador

> sigo suas recomendacoes

## Direção aprovada

1. O Hub terá uma loja simples de suprimentos para preparar a próxima expedição. O estoque básico será previsível e usará consumíveis do catálogo, com opções de cura e recuperação de MP. A compra apresenta o preço e o efeito do item.
2. O primeiro recorte demonstra o ciclo completo. Conforme a [D-1251](D-1251-moedas-exploracao-e-economia-inicial.md), o jogador encontra uma recompensa em moedas no mapa, volta ao Hub, compra um consumível e leva a compra à próxima expedição. O item comprado precisa sobreviver à transição pelo Portão. A forma de reposição do kit inicial segue em aberto.
3. Uma fala curta de um NPC que usa o Portão pode ligar a passagem pelo Hub à revisita da Murky Forest. A D-1248 define a fala e a marca na mata como pistas. A recompensa desse primeiro evento é a descoberta, conforme a D-1247.
4. Após a validação do ciclo básico, a direção para a primeira novidade comercial é uma opção adicional de compra ligada a um acontecimento reconhecível no jogo.

## Pendências

- Local e comerciante, catálogo exato, preços e saldo inicial.
- Regras de concessão e contabilização das moedas, persistência do saldo e tratamento em derrota ou retirada.
- Regra de reposição gratuita do kit inicial compatível com os itens comprados.
- Item adicional, acontecimento associado e critério de disponibilidade.
