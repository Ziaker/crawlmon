# CRAWLMON — BUBBLE SHIELD
## Protótipo HTML 3D / especificação visual proposta e registro de execução

**Data:** 6 de novembro de 2026  
**Artefato:** `bubble_shield_vfx_lab.html`  
**Natureza:** laboratório visual isolado do Godot (HTML + JavaScript + WebGL2; offline, sem bibliotecas externas).  
**Estado de aprovação:** proposta de VFX, **não** homologação de nova regra de combate.  
**Repositório de referência conferido:** `Ziaker/crawlmon`, branch `main`; documentos `AGENTS.md`, `docs/REGRAS_DO_JOGO.md`, índice e decisões D-323 a D-326, D-031 e D-235.  
**Escopo da entrega:** protótipo navegável + documentação; **sem alteração do projeto Godot e sem publicação no GitHub nesta entrega**.

---

## 1. Fonte de verdade: ficha expressamente aprovada

| Propriedade | Valor aprovado |
|---|---|
| Nome | Bubble Shield |
| Elemento do Move | Water |
| Categoria | Status |
| Seleção / facção | ALL ALLIES, incluindo o lançador |
| Custo | 3 ATB |
| Wind-up | 0,7 s |
| Proteção | 25 + MAG do lançador **para cada aliado**, não compartilhados |
| Duração | 8 s por escudo, ou até sua resistência se esgotar |
| Custo de MP | **Pendente:** obrigatório para Moves diferentes de Tackle, salvo regra de Burst (D-263/D-270) |
| Tipagem defensiva da reserva | **Pendente:** Water é o elemento do Move, não necessariamente a tipagem do escudo |

**Fontes normativas:** D-012 (alvos amigáveis e próprio usuário), D-019 (linha de tempo única), D-031 (pausa do motor em Moves de status), D-235 (Move independente de personagem, equipe ou lado), D-323 (ficha), D-324 (reservas e prioridade), D-325 (interrupção e dano periódico), D-326 (Brick Break).

## 2. Comportamento de escudos aprovado, mas NÃO simulado integralmente

1. **Reaplicação:** o mesmo Move reseta o escudo, salvo autorização expressa de *stack* com aplicações anteriores do mesmo Move. A especificação não define explicitamente quais campos o reset recupera; o laboratório **recria visualmente** a reserva e a duração, mas não estabelece essa escolha como regra.
2. **Acumulação:** reservas tipadas e sem tipo coexistem; foi dado o exemplo de 25 de escudo físico e 30 de escudo sem tipo. A prioridade é **tipado > sem tipo > HP**. O laboratório ilustra **somente uma reserva Bubble Shield por alvo**, para não inventar sua tipagem.
3. **Interrupções:** a proteção total do dano não gera anti-interrupção automática; somente a descrição expressa de um efeito pode impedir interrupções de Moves. Bubble Shield não inclui essa propriedade na ficha atual.
4. **Burn e Poison:** seu dano deve consumir escudos elegíveis. O controle **BURN / −7** demonstra uma redução isolada da reserva, não uma implementação do status, de ticks ou de elegibilidade elemental.
5. **Brick Break:** quebra escudos, incluindo Bubble Shield. O controle **RUPTURA** aciona **somente** a animação genérica de rompimento no alvo selecionado. Ele não implementa a ficha de Brick Break nem escolhe quantos escudos o ataque quebra.
6. **Interação com aplicação de outros status:** ainda não homologada. O protótipo não aplica status nem regras de interrupção.

## 3. Direção artística visual recomendada

**Conceito:** “aegis aquática”. Não é uma esfera de plástico nem um vidro azul opaco. A proteção é uma **membrana fina de água tensionada** que oscila, reflete a luz nas bordas e deixa o monstro interior visível. As peças fluidas devem transmitir pressão, superfície e viscosidade; o efeito não deve virar um cilindro ou overlay opaco que cubra a arena.

### 3.1 Preparação / WIND-UP — 0,00–0,70 s

- **0,00–0,25 s:** partículas/gotas tornam-se visíveis ao redor do lançador e iniciam trajetórias ascendentes.
- **0,25–0,55 s:** um fluxo helicoidal de água começa a comprimir-se em torno do centro geométrico do lançador; o deslocamento cresce com o progresso do cast.
- **0,55–0,70 s:** aparece um núcleo concentrado ciano no centro superior do modelo, preparando a expansão.
- A conjuração não requer braços, dedos, rosto ou qualquer outro ponto anatômico obrigatório; sua origem é derivada da posição e do envelope do monstro.

### 3.2 Release / aplicação coletiva

- Ao concluir **0,70 s**, o laboratório aplica o estado do escudo simultaneamente aos três combatentes da equipe do lançador.
- Um anel fino se propaga a partir do lançador **apenas visualmente**: não se trata de um projétil nem altera a simultaneidade da aplicação.
- Em cada destinatário, uma esfera fina se expande do centro do corpo, apresenta um breve excesso de escala e estabiliza.
- O release demonstra uma duração visual de aproximadamente **0,46 s**, dentro de uma estase estética de aproximadamente 1 s usada no protótipo. Esse valor não aprova nova duração de gameplay nem substitui D-031.

### 3.3 Proteção persistente / até 8 s de relógio de combate

- Esfera translúcida escalada ao envelope de cada personagem, com *Fresnel rim* mais visível nas bordas e faixas de reflexão em deslocamento lento.
- Ondulações sutis e partículas esparsas percorrem a superfície sem ocultar as cores dos modelos.
- À medida que a resistência cai, a membrana torna-se visualmente mais fraca, porém **a fraqueza visual está ligada à resistência, não ao tempo decorrido**.
- Nos últimos instantes do prazo, a transparência oscila levemente indicando expiração iminente. Esta indicação é puramente visual.

### 3.4 Impacto / dano absorvido

- O ponto de contato é localizado na face da bolha voltada à câmera (demonstração; no jogo real seria o ponto do evento de contato).
- O shader aplica uma **depressão localizada** normal à superfície e emite uma onda circular de deslocamento que se propaga pela membrana.
- A intensidade do recuo cresce com o dano de teste e a membrana recupera sua forma; a translucidez pós-impacto acompanha o saldo restante.
- Os botões `IMPACTO −15` e `IMPACTO −35` descontam a resistência **da reserva isolada selecionada**, sem decidir mitigação, tipagem ou dano excedente contra HP.

### 3.5 Ruptura por esgotamento

- Assim que a resistência da reserva simulada chega a zero, a proteção mecânica de **demonstração** deixa de estar ativa.
- O shader contrai e esmaece a membrana; fragmentos de gotas aquáticas são emitidos com movimento balístico e dissipam-se.
- Fragmentos são exclusivamente resíduos visuais e não oferecem proteção adicional.
- Duração demonstrativa da dissipação: aproximadamente 0,20 s de contração + partículas residuais por cerca de 1–1,5 s.

### 3.6 Expiração ao fim da duração

- Dissolução suave, diferente do estilhaçamento: a superfície expande um pouco, perde brilho e desaparece lentamente, enquanto pequenas gotas se dispersam.
- Duração visual demonstrativa da dissolução: aproximadamente 0,43 s.
- Quando o último segundo do relógio do escudo termina, seu estado ativo acaba imediatamente; a memória visual não estende a proteção.

## 4. Navegação e controles do arquivo HTML

| Controle | O que executa no laboratório |
|---|---|
| `CONJURAR SHIELD` | Inicia o wind-up de 0,7 s; aplica 25 + MAG a todos os aliados da equipe do lançador, incluindo-o; a demonstração da mesma conjuração pode ser repetida |
| `IMPACTO −15 / −35` | Dano de teste já pronto, subtraído da reserva selecionada; sem cálculo de HP/mitigação |
| `BURN / −7` | Exemplo visual discreto de dano periódico consumindo reserva; **não** cria estado Burn |
| `RUPTURA` | Força a animação de rompimento da bolha selecionada, sem resolver Brick Break real |
| `EXPIRAÇÃO` | Força a dissipação suave da bolha selecionada |
| `MAG` | Valor ilustrativo selecionável para testar a fórmula 25 + MAG; valor inicial 30 é **apenas exemplo** |
| `LANÇADOR` | Alterna entre os seis personagens demonstrativos; ALL ALLIES é sempre relativo à equipe real do lançador |
| `ALVO DO TESTE` | Seleciona qual reserva recebe impacto, ruptura ou expiração |
| `ESPELHAR CÂMERA` | Rotaciona a câmera 180°; permite conferir o VFX a partir do outro lado |
| `REINICIAR` | Limpa efeitos e estados do protótipo |
| Arrastar / rolar mouse | Gira e aproxima/afasta a câmera 3D |
| Clicar no modelo | Seleciona o alvo demonstrativo; selecionar personagem do outro time troca o lado para testes de simetria |

O BattleLog no canto superior direito e as peças inclinadas brancas/vermelhas/ciano são uma **apresentação de laboratório inspirada nas referências D-268/D-322**, não uma alteração na HUD aprovada nem um clone exato dos arquivos originais.

## 5. Relógios e separação lógica/visual

O código HTML mantém um tempo de apresentação (`visualT`) e uma contagem de duração (`battleT`) separados. A duração dos escudos é decrementada **apenas quando o modo de demonstração está em estado normal**, preservando a ideia de D-031 de congelar o motor durante o Move de status. Na demonstração, o wind-up dura 0,70 s; após o release, há uma janela visual de estase de **0,98 s aproximando o `STATUS_VFX_TAIL` de 1,0 s encontrado na `main`**. O efeito de membrana continua animado enquanto o relógio está parado. Essa simulação não constitui integração com o `Battle` do Godot.

A animação de dano, ruptura e expiração apenas acompanha o saldo e o prazo demonstrativos. No jogo real, `Battle` e `Combatant` deverão conservar a autoridade sobre a ordem dos eventos, consumos e morte. A integração visual ficaria subordinada aos eventos oficiais, sem decidir conflitos de status, reações de alvo, RNG, interrupção nem dano.

## 6. Estrutura técnica do protótipo

- **Um arquivo HTML autônomo**, com CSS, JavaScript e shaders GLSL ES 3.00 embutidos.
- **WebGL2 nativo**: geometria parametrizada de esferas, cones, linhas de anéis e superfície; matrizes próprias; projeção perspectiva, câmera orbital, profundidade, transparência e shader de água.
- **Seis personagens demonstrativos** compostos de primitivas 3D, em duas equipes de três, com escalas de corpo distintas. Não são modelos oficiais do jogo.
- O Move é disparado por **qualquer** personagem escolhido; cada bolha usa centro e raio derivados do respectivo corpo; independência do lado reforçada por seleção do time inimigo e rotação da câmera.
- Não usa servidor, bibliotecas CDN, modelos externos, imagens externas, Three.js, Godot ou acesso à rede.
- A direção artística é **proposta**, não aceite implícito da aprovação do protótipo visual.

## 7. Limites e decisões pendentes preservadas

| Tema | Estado/limite |
|---|---|
| Tipagem defensiva do Bubble Shield | **Não definida**. O laboratório não testa se é Water-typed, físico, mágico ou sem tipo |
| Absorção entre escudos tipados e sem tipo | A ordem D-324 é conhecida; o laboratório demonstra somente Bubble Shield, sem arbitrar múltiplas reservas |
| Elegibilidade de danos por tipo | Pendente; testes de `−15`, `−35` e `Burn −7` são **forçados para fins de inspeção visual** |
| Reaplicação / reset | Simulada como nova reserva com valor e prazo iniciais; **não homologada** como definição operacional de “reseta” |
| MAG do personagem no jogo | Não integrado; slider apenas ilustrativo |
| MP | Não definido para Bubble Shield; não há cobrança de ATB/MP neste laboratório |
| Interrupção e efeitos de status | Não implementados; absorção visual não representa invulnerabilidade |
| Brick Break | Controle de ruptura não determina alcance, quantidade de escudos ou ordem da resolução do Move |
| Dano excedente para HP | Não simulado; o log informa excedente, evitando escolher regra em aberto |
| Animação final | Proposta até avaliação visual e aprovação do criador |
| Performance no Godot GL Compatibility | Não aferida; a versão HTML WebGL2 não equivale a shader/teste no Godot |

## 8. Validação executada

- **Checagem sintática real:** `node --check` no JavaScript incorporado ao HTML — **PASSOU**.
- **Teste de fluxo JavaScript com interface e WebGL simulados:** inicialização, avanço temporal, wind-up e estase, fórmula 25 + 30 = 55 em cada aliado, impacto de 15 reduzindo a reserva para 40, ruptura e nova conjuração por membro do time inimigo — **PASSOU**.
- **Teste gráfico real em Chromium deste ambiente:** a tentativa de inicialização WebGL/ANGLE **falhou no ambiente headless** (sem contexto gráfico funcional); **não existe validação de aparência por screenshot nem garantia de funcionamento em todas as GPUs**. A entrega precisa ser inspecionada em navegador com suporte WebGL2.
- **Testes no jogo Godot:** não realizados; nenhum código da `main` foi alterado.

## 9. Critérios visuais para aprovação posterior

Avaliar a legibilidade das bolhas em personagens de diferentes tamanhos, a proporção de partículas, a transparência e o brilho da membrana, a clareza da depressão no impacto e a distinção inequívoca entre estilhaçamento e expiração. Conferir lado do lançador e lado espelhado. Aprovação do protótipo não deve ser interpretada como autorização automática para implementar as regras ainda em aberto nem para substituir a HUD existente.

---

**Conclusão de escopo:** HTML 3D funcional em lógica simulada e documentação de design entregues **fora do projeto Godot**. Nenhuma tipagem defensiva foi escolhida; nenhum custo de MP foi inventado; nenhuma decisão foi atribuída ao criador sem aprovação.
