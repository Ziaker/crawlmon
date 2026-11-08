# Dossiê visual de referências — 20 componentes VFX

> **SLASH ARC VERIFICADO TECNICAMENTE.** Três referências principais com quadro real e protótipo
> com paleta de fogo, carga em zigue-zague, volume cruzado, atlas de respingos e vistas
> lado/trás/topo (`SLASH_SEGUNDA_PASSADA.md`). **Aguardando sua aprovação visual.**
> A coroa segue **incompleta** (2 de 3 principais). Os outros 18 componentes continuam na
> primeira passada.
>
> **Nada foi declarado aprovado.** O Crown não foi reconstruído.
Este dossiê existe para o criador julgar a direção antes de qualquer implementação.

## Método

- **20 categorias** = os 20 componentes do catálogo (`LIB-VFX-01`…`20`), que continua inteiro.
- **5 candidatos por categoria** = 100 fichas na primeira passada.
- **3 selecionadas por categoria** = 60 referências na primeira passada.
- A primeira passada usou, em vários casos, a **capa** da página; isso foi rejeitado. A segunda
  passada exige **quadro do efeito**, com vídeo/ID e timestamp ou frame do GIF.
- **39 páginas-fonte únicas**: alguns reels/packs demonstram mais de um fenômeno e aparecem em
 mais de uma categoria com fichas diferentes. Não é preenchimento: cada ficha aponta o aspecto
 específico daquela obra. Se o criador quiser 100 páginas distintas, é uma expansão a fazer.
- Fontes: ArtStation, RealTimeVFX, VFX Apprentice, 80.lv, Epic Developer Community, CGHOW,
 Framestore, SideFX, CGcircuit, Rebelway, Fab, Steam, YouTube e portfólios individuais.
- Nenhum link foi inventado. Todos abrem a obra ou o artigo citado; quando a imagem de capa
 não pôde ser baixada (ArtStation/Fab bloqueiam), a ficha diz isso e mantém o link.
- **Imagens:** 53 das 60 selecionadas têm capa baixada da própria fonte. Em alguns casos a capa
 é o *hero* do artigo, não o quadro exato do efeito — está anotado no contato e na ficha.
 São imagens de estudo, **não assets** e não entram no jogo nem no Git como arte final.

## As sete fases da biblioteca

As sete fases (`START → WIND-UP → RELEASE → TRAJECTORY → PRELUDE → IMPACT → POST-IMPACT`) são
**opções para composições e sequências**, não uma obrigação de preencher sete animações em cada
componente isolado. A coroa, o vortex e os demais componentes não têm timeline de sete fases
nesta pesquisa.

A D-308 trata das **quatro fases dos VFX elementais do jogo** (Wind-up, Release, Trajeto, Impacto).
Ela **não** substitui as sete fases da biblioteca e não foi usada para encurtar a timeline.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `SLASH_SEGUNDA_PASSADA.md` | **Slash — 3 referências com quadro real + protótipo verificado tecnicamente** |
| `COROA_SEGUNDA_PASSADA.md` | **Coroa — segunda passada com quadros reais; incompleta (2 de 3 principais)** |
| `00_flagship_coroa_vortice.md` | Status dos dois flagships após a rejeição; nada aprovado |
| `01_formas.md` | LIB 01–05: vórtice, tornado, fita, hélice, erosão |
| `02_movimento.md` | LIB 06–12: thrust, speed lines, trail, aura, poeira, frenagem, arranhão |
| `03_impacto.md` | LIB 13–16: shockwave, coroa, blast cone, fratura |
| `04_complementos.md` | LIB 17–20: flipbook, faíscas, detritos, slash |
| `refs.json` | As 100 fichas da primeira passada (a entrada da coroa está desatualizada) |
| `crown_frames/` | Quadros extraídos da segunda passada |
| `contatos/COROA-*.png` | Folhas da segunda passada (quadros, sequência, comparativo) |
| `contatos/contato-<id>.png` | Folhas da primeira passada (não aprovadas) |
| `images/` | Capas da primeira passada |

## Índice dos contatos

`contato-vortex`, `contato-funnel`, `contato-ribbon`, `contato-helix`, `contato-dissolve`,
`contato-thrust`, `contato-speedlines`, `contato-motiontrail`, `contato-aura`, `contato-dust`,
`contato-scuff`, `contato-scratch`, `contato-shockwave`, `contato-crown`, `contato-blastcone`,
`contato-fracture`, `contato-flipbook`, `contato-sparks`, `contato-debris`, `contato-slash`.

## Lacunas de imagem (honestas)

- `vortex` ref. 1 (Framestore/Doctor Strange): sem `og:image`; link verificado.
- `motiontrail` refs. 1–2 (Fab/ArtStation): bloqueio 403.
- `aura` ref. 1 (ArtStation): bloqueio 403.
- `slash` ref. 1 (ArtStation): bloqueio 403.
- Em `dust`, `scuff`, `shockwave` e `blastcone`, a capa do Brais é o grid do sketchbook, não o
 efeito — o efeito está no post (GIFs); o link está na ficha.

## O que ainda falta para fechar a pesquisa

- Substituir as 7 capas bloqueadas por quadros extraídos dos vídeos/reels (requer download de
 vídeo e permissão de uso — não foi feito).
- Confirmar autoria/licença de cada obra para qualquer uso além de estudo interno.
- O criador escolher a referência-âncora e aprovar a direção; só então um efeito é reconstruído.

## O que este dossiê **não** faz

- Não declara nenhum efeito aprovado.
- Não altera os 20 componentes, as 5 demos, a câmera, o POV espelhado nem o código.
- Não troca Three.js, não troca a arquitetura de partículas e não adiciona complexidade técnica
 como substituto de silhueta.
- As sete fases são **opções para composições**; não são impostas a cada componente isolado.
- Os 6 flagships que eu havia refeito antes deste dossiê continuam no código, mas **não estão
 aprovados** e não serão estendidos até a aprovação da direção.
