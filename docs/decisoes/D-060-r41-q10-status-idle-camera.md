# D-60 — R41-Q10 (10B): Pausa seletiva de status com idle e câmera

- **Data:** 2026-11-02
- **Origem:** decisão direta do criador, R41; eventuais complementos posteriores estão reproduzidos abaixo.
- **Estado:** decisão de design aprovada; nenhuma implementação afirmada por este documento.

## Declaração do criador (literal)

> 10B — Durante o efeito de um Move de status, o que acontece com a câmera e as animações dos demais personagens?: As demais ações congelam, mas animações ociosas continuam; a câmera acompanha o efeito.

## Regra aprovada

Durante o efeito visual de status, as outras ações lógicas permanecem congeladas; animações ociosas continuam e a câmera acompanha o efeito de status.

## Relações e questões de compatibilidade

- **Referências:** D-014; D-019; D-020; R39-Q8.
- **Observação:** Não inferir permissão de reintroduzir locomoção ociosa removida pela D-020.
- **Implementação:** não modificar comportamento do jogo apenas pela criação deste registro; avaliar divergências antes da implementação.
