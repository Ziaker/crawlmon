<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-407 — Revisão Visual de Wind: Furacão, Redemoinho e Referências SMT/Persona

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Combate / Regras
- **Origem:** decisão direta do criador rejeitando as opções anteriores de Wind e orientando a busca por referências autênticas de furacões, redemoinhos e SMT.
- **Estado:** regra registrada; protótipos visuais atualizados; documentação oficial atualizada.

## Declaração literal do criador

> "pense em furacões, redemoinhos, vento, referencias de smt e shin megami tensei ou outros jogos com elementos de vento
> 
> desaprovo seu resultado"

## Regras aprovadas e diretrizes de revisão

1. **Rejeição Integral das Versões Anteriores de Wind:**
   - As três variantes de D-406 (Wind Whip, Cyclone Funnel notch e Kaze Crest) foram desaprovadas pelo criador por não comunicarem a essência visual de furacão, redemoinho ou vento com apoio semântico evidente.

2. **Diretriz Conceitual Obrigatória para o Glifo de Wind (Fundo `#4ff7ba`):**
   - O elemento Wind deve obrigatoriamente evocar a força atmosférica real de **furacão (hurricane)**, **redemoinho (tornado/whirlwind)** ou **vórtice de vendaval cortante de Shin Megami Tensei (Force/Zan) e Persona (Garu)**.
   - Manter o fundo oficial verde-menta `#4ff7ba` (D-403) com alto contraste contra o glifo preto.
   - Escalar perfeitamente de 64x64 px até 16x16 px sem perder legibilidade.

3. **Três Novas Opções Especializadas no Laboratório de Protótipos (`prototypes/icones_moves_lab.html`):**
   - **Opção 1 (Redemoinho / Tornado Funnel):** Foco literal em "redemoinhos/tornados". Funil vertical cônico de alta rotação composto por prateleiras tempestuosas em discos aerodinâmicos horizontais que afunilam até uma ponta afiada de vórtice no solo (estilo clássico de tornados em JRPGs).
   - **Opção 2 (Furacão / Olho Categórico):** Foco literal em "furacões". Símbolo ciclônico de radar com olho de baixa pressão central envolto por dois braços espirais maciços de vendaval com aletas aerodinâmicas de descompressão.
   - **Opção 3 (SMT Force / Vórtice Garu):** Foco literal em "referências de SMT e Shin Megami Tensei". Tríscele concêntrico de três foices de vento (*Kamaitachi*) em rotação centrípeta de alta velocidade em torno de um núcleo de tempestade.

## Relação com decisões anteriores

- Estende e substitui a diretriz de **D-406**, preservando o fundo `#4ff7ba` (D-403/D-404), os outros 11 elementos oficiais (D-397/D-398/D-404), os tipos de move (D-395/D-396) e os alcances com fundo branco e Área ampliada (D-404).
