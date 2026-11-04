# Crawlmon — Especificação do Motion Composer V1

Escopo aprovado: 20 comportamentos procedurais, combináveis entre si, com laboratório visual independente e preservação integral dos VFX atuais.

A primeira versão será especificada como uma biblioteca de movimentos para criar efeitos visuais, não como uma coleção de 20 efeitos prontos.

O projeto terá três capacidades centrais: criar movimentos individualmente, combiná-los em animações complexas e reaproveitar a mesma animação com diferentes representações visuais.

A especificação também preservará os oito estudos helicoidais como referências para a evolução da biblioteca, sem transformá-los em oito implementações adicionais nesta primeira versão.

Decisões aplicáveis: D-002, D-003, D-019, D-020, D-022 e as decisões locais do Motion Composer D-042, D-043, D-044 e D-045, além das decisões de combate que governarão uma eventual integração posterior. O desenvolvimento desta especificação não autoriza alterar o código ou substituir efeitos existentes.

# Especificação técnica — Crawlmon Motion Composer V1

**Tipo:** Especificação de design e arquitetura, sem implementação\
**Projeto:** Crawlmon — Godot 4.7 / GL Compatibility\
**Base local conferida:** commit `3397689c4f64d04681623fcc984159a5579d7a27`; árvore de trabalho compartilhada com alterações locais. A análise estática original está registrada nesta conversa; não equivale à validação em execução.\
**Situação:** Catálogo de 20 movimentos aprovado; detalhes técnicos e artísticos propostos para avaliação.

---

## 1. Objetivo

Desenvolver uma biblioteca independente de comportamentos procedurais para facilitar a criação, edição, combinação, visualização e reutilização de movimentos em efeitos visuais 3D.

O sistema deverá permitir que agentes de IA e operadores humanos criem movimentos complexos combinando comportamentos simples, evitando a necessidade de reprogramar trajetórias e deformações a cada Move.

**Princípio central:** movimento, representação visual e temporização são responsabilidades distintas.

Um mesmo comportamento poderá controlar pontos, fragmentos, fitas, partículas ou outras representações compatíveis.

### 1.1 Escopo aprovado

- Implementação futura de 20 comportamentos específicos, definidos na seção 3.
- Laboratório visual independente.
- Composição de múltiplos comportamentos.
- Independência entre lógica de movimento e aparência visual.
- Preservação dos VFX existentes.
- Preservação integral das regras de combate.
- Possibilidade de futura integração mediante autorização separada.

### 1.2 Fora do escopo desta primeira versão

- Substituir efeitos visuais dos Moves existentes.
- Modificar dano, colisões, trajetórias lógicas, ATB ou qualquer mecânica de combate.
- Alterar câmera ou animações dos personagens.
- Implementar os 64 comportamentos do catálogo conceitual.
- Criar oito implementações helicoidais adicionais.
- Introduzir simulação física complexa, fluidos ou um novo motor de partículas.
- Refatorar sistemas atuais sem necessidade autorizada.

Os oito exemplos da imagem original permanecem como referências geométricas e artísticas.

---

## 2. Princípios de arquitetura

### 2.1 Movimento independente da geometria

O movimento deverá ser calculado independentemente do recurso utilizado para desenhá-lo.

Um avaliador receberá parâmetros, coordenadas de amostragem e tempo e produzirá informações geométricas e visuais.

Os renderizadores consumirão os resultados sem modificar a lógica do movimento.

### 2.2 Um único tempo por instância

Cada instância deverá consumir um tempo fornecido por seu controlador.

- **No laboratório:** relógio local controlado pela interface.
- **No combate futuro:** relógio ou progresso da ação fornecido pelo motor.
- **Em pausa:** o tempo correspondente permanece constante.
- **Em câmera lenta:** o tempo progride conforme a escala autoritativa.
- **Em pausas seletivas:** ações distintas podem receber tempos distintos.

Nenhum comportamento poderá decidir autonomamente o instante lógico de dano, colisão, interrupção ou finalização do ataque.

### 2.3 Composição explícita

A ordem dos movimentos será parte da definição de cada composição.

Aplicar curvatura e depois torção não é necessariamente equivalente a torcer primeiro e depois curvar.

Também deverão ser representados explicitamente o sistema de coordenadas, a intensidade, a máscara espacial e os deslocamentos temporais.

### 2.4 Determinismo

Uma composição deverá produzir o mesmo resultado quando avaliada com parâmetros, tempo, contexto e semente idênticos.

Isso é necessário para reprodução quadro a quadro, comparação A/B, testes e reconstrução de rastros.

### 2.5 Preservação

O Motion Composer não deverá substituir `VfxLib`, `BattleFx` ou os módulos atuais de combate nesta etapa.

A reutilização de funções existentes deverá ser avaliada caso a caso. Funções que dependem de temporizadores ou tweens próprios não deverão ser consideradas automaticamente compatíveis com o novo contrato temporal.

---

## 3. Catálogo aprovado — 20 comportamentos

Os comportamentos abaixo são os únicos aprovados como integrantes da V1.

Os parâmetros indicados representam as capacidades a especificar. Valores iniciais, limites e curvas padrão permanecem pendentes.

### Grupo A — Trajetórias

| ID  | Comportamento      | Definição funcional e parâmetros principais                                                                                                  |
| --- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| M01 | Espiral helicoidal | Deslocar amostras em torno de um eixo com avanço axial. Parâmetros: raio, passo, voltas, fase, sentido e evolução do raio                    |
| M02 | Zigue-zague        | Alternar deslocamentos laterais durante a progressão. Parâmetros: amplitude, frequência espacial, suavização dos vértices e fase             |
| M03 | Serpentina         | Criar deslocamento lateral contínuo e ondulatório ao longo de uma direção. Parâmetros: amplitude, comprimento de onda, fase e curvatura      |
| M04 | Bézier dinâmica    | Avaliar uma trajetória com pontos de controle modificáveis ao longo do tempo. Parâmetros: pontos de controle, progressão e variação temporal |

**Critério:** as quatro trajetórias devem produzir movimentos espacialmente distinguíveis, inclusive com representação neutra.

### Grupo B — Campos de movimento

| ID  | Comportamento | Definição funcional e parâmetros principais                                                                                          |
| --- | ------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| M05 | Vórtice       | Induzir circulação ao redor de um eixo ou núcleo. Parâmetros: centro, intensidade angular, raio de influência e decaimento           |
| M06 | Convergência  | Aproximar elementos de uma posição de destino. Parâmetros: ponto-alvo, intensidade de atração, curva de aproximação e alcance        |
| M07 | Turbulência   | Introduzir perturbações espaciais contínuas e não uniformes. Parâmetros: escala espacial, intensidade, frequência temporal e semente |

A V1 deverá distinguir **campo de movimento** de **simulação de partículas**.

Os três campos poderão inicialmente operar por avaliação procedural determinística. Integração numérica e comportamento físico acumulativo não estão automaticamente aprovados.

### Grupo C — Deformações

| ID  | Comportamento      | Definição funcional e parâmetros principais                                         |
| --- | ------------------ | ----------------------------------------------------------------------------------- |
| M08 | Torção progressiva | Aplicar rotação variável ao longo do comprimento, com propagação temporal da torção |
| M09 | Curvatura          | Deformar progressivamente o eixo ou a estrutura espacial de um efeito               |
| M10 | Alongamento        | Aumentar a extensão de regiões determinadas, com distribuição espacial configurável |
| M11 | Compressão         | Reduzir a extensão ou concentração espacial das regiões selecionadas                |

Parâmetros comuns: intensidade, posição de influência, extensão afetada, curva espacial, início temporal e duração da transformação.

Os comportamentos deverão atuar sobre diferentes regiões da representação, e não apenas modificar a escala ou rotação global de um `Node3D`.

### Grupo D — Propagação

| ID  | Comportamento  | Definição funcional e parâmetros principais                                                         |
| --- | -------------- | --------------------------------------------------------------------------------------------------- |
| M12 | Pulso viajante | Deslocar uma concentração de intensidade ou deformação ao longo de um percurso                      |
| M13 | Onda radial    | Propagar uma frente de influência a partir de um centro sobre um plano ou domínio espacial definido |

Parâmetros: velocidade de propagação visual, extensão da frente, amplitude, frequência quando aplicável, alcance e perfil de dissipação.

Esses parâmetros são puramente visuais no laboratório e não definem velocidade lógica de projéteis ou áreas de dano.

### Grupo E — Composição espacial

| ID  | Comportamento | Definição funcional e parâmetros principais                                                                 |
| --- | ------------- | ----------------------------------------------------------------------------------------------------------- |
| M14 | Bifurcação    | Separar um fluxo de origem em múltiplos percursos identificáveis                                            |
| M15 | Recombinação  | Conduzir fluxos distintos a uma região comum, produzindo convergência espacial e eventual unificação visual |

Parâmetros: quantidade de ramificações, ponto de separação, ângulo de abertura, distância, intensidade, ponto de reunião e duração.

Os fluxos deverão manter identificadores estáveis para possibilitar animação determinística e associação correta dos rastros.

### Grupo F — Impacto

**M16 — Explosão direcional**

Expansão rápida e orientada de elementos a partir de uma região de origem.

Parâmetros: direção, abertura angular, distância, distribuição, intensidade, perfil temporal e dissipação.

O comportamento não cria impactos adicionais nem modifica o resultado lógico de um ataque.

### Grupo G — Nascimento e dissipação

**M17 — Crescimento progressivo**

Permite revelar gradualmente um movimento, aumentando o trecho visível ou a região ativa ao longo do tempo.

**M18 — Dissolução progressiva**

Permite remover gradualmente regiões do efeito, com progressão espacial e temporal.

Parâmetros comuns: direção de propagação, duração, curva de intensidade, máscara e largura da transição.

A dissolução deverá poder atuar sobre visibilidade, espessura ou intensidade, conforme a representação utilizada, sem exigir um único método de renderização.

### Grupo H — Persistência

**M19 — Rastro temporal**

Representa posições anteriores de um movimento, com idade e propriedades visuais controláveis.

Deverá preservar a história do emissor quando este mudar de posição ou direção.

**M20 — Pós-imagem**

Representa estados visuais anteriores em instantes discretos, com defasagem temporal e desaparecimento progressivo.

Parâmetros comuns: duração da persistência, intervalo entre amostras, intensidade, tamanho, transparência e referência espacial.

**Diferença obrigatória:** rastro temporal apresenta continuidade histórica; pós-imagem utiliza estados discretos. Os dois não deverão produzir resultados indistinguíveis.

---

## 4. Modelo de dados proposto

Esta seção descreve um contrato lógico, não nomes obrigatórios de classes ou arquivos.

### 4.1 Definição de comportamento

Cada comportamento deverá possuir:

- Identificador estável e versão.
- Nome e descrição.
- Categoria funcional.
- Parâmetros editáveis, unidades e domínios válidos.
- Tipos de entrada e saída.
- Política de composição.
- Requisitos de amostragem.
- Indicação de funcionamento por avaliação direta ou histórico.
- Regras de compatibilidade com máscaras e espaços de coordenadas.

### 4.2 Contexto de avaliação

O avaliador deverá receber, conceitualmente:

| Entrada                     | Finalidade                                                        |
| --------------------------- | ----------------------------------------------------------------- |
| Tempo da instância          | Determinar o estado temporal                                      |
| Coordenada de amostragem    | Identificar a região avaliada                                     |
| Transformação de referência | Posicionar o efeito no espaço                                     |
| Parâmetros                  | Configurar o comportamento                                        |
| Semente                     | Garantir aleatoriedade reproduzível                               |
| Identificador da instância  | Separar efeitos simultâneos                                       |
| Contexto de origem/destino  | Referenciar pontos e orientações quando aplicável                 |
| Estado histórico            | Disponibilizar dados de rastros ou simulações, quando necessários |

O tempo em segundos e o progresso normalizado deverão ser conceitos diferentes. A conversão depende de uma duração conhecida, não presumida.

### 4.3 Resultado da avaliação

Um resultado poderá conter:

- Posição 3D.
- Orientação ou base local.
- Direção tangente.
- Escala e espessura.
- Intensidade e opacidade.
- Estado de visibilidade.
- Identificador de ramo ou elemento.
- Informações para construção das representações visuais.

Nem todo comportamento precisa alterar todos esses campos.

Um resultado não deverá incluir comandos para alterar dano, colisão lógica, câmera ou estado de combate.

### 4.4 Tipos de operações

Proponho distinguir:

1. **Geradores:** produzem trajetórias ou conjuntos iniciais de amostras.
2. **Modificadores:** transformam posições ou atributos existentes.
3. **Campos:** aplicam deslocamentos ou influências espaciais.
4. **Operadores de topologia:** ramificam ou reúnem fluxos.
5. **Envelopes:** controlam ativação, crescimento, intensidade e dissipação.
6. **Operadores históricos:** constroem rastros e pós-imagens.

Essa divisão permite compartilhamento de algoritmos sem transformar comportamentos visualmente distintos em uma única entrada de catálogo.

---

## 5. Sistema de composição

### 5.1 Modelo conceitual

Uma composição é uma sequência ordenada de operações, com possibilidade de ramificação.

Cada operação terá:

- Comportamento selecionado.
- Parâmetros.
- Intensidade de aplicação.
- Máscara de influência.
- Espaço de coordenadas.
- Defasagem temporal.
- Condição de ativação.
- Entrada e saída explícitas.

Uma composição poderá conter várias instâncias do mesmo comportamento com parâmetros distintos.

### 5.2 Operações de combinação propostas

| Operação             | Semântica                                            |
| -------------------- | ---------------------------------------------------- |
| Substituir           | Usa a saída de um comportamento como novo valor-base |
| Deslocar             | Soma um deslocamento ao resultado anterior           |
| Deformar             | Transforma espacialmente a saída anterior            |
| Multiplicar atributo | Modula intensidade, largura ou opacidade             |
| Mascarar             | Restringe uma influência a uma região                |
| Ramificar            | Produz múltiplas saídas identificadas                |
| Reunir               | Combina fluxos que compartilham um destino ou região |
| Persistir            | Usa informações de estados temporais anteriores      |

Operações incompatíveis deverão produzir uma mensagem de validação, não uma conversão silenciosa.

### 5.3 Espaços de coordenadas

A especificação de composição deverá diferenciar, no mínimo:

- Espaço local do efeito.
- Espaço global do laboratório ou cena.
- Espaço associado a uma trajetória.
- Espaço relativo ao emissor.

A troca de espaço deverá ser explícita e verificável.

Uma trajetória que segue o emissor e um rastro que permanece no mundo não devem ser obrigados a usar a mesma transformação.

### 5.4 Máscaras

As máscaras deverão permitir controlar a influência por posição, tempo, ramo ou identificador de elemento.

Exemplos:

- Aplicar torção somente à metade final da trajetória.
- Comprimir o núcleo, preservando as extremidades.
- Dissolver a cauda antes da frente.
- Aplicar turbulência somente após uma bifurcação.

### 5.5 Curvas temporais

Cada comportamento deverá permitir evolução temporal parametrizada.

O sistema deverá suportar curvas para intensidades e outros parâmetros compatíveis.

Os intervalos e perfis padrão das curvas ainda precisam de aprovação.

---

## 6. Exemplo obrigatório de composição

### Rajada complexa de energia

Sequência visual pretendida:

**Compressão → Zigue-zague com torção → Bifurcação em três fluxos → Recombinação → Ondas radiais → Dissipação**

| Etapa           | Comportamentos | Resultado esperado                                                  |
| --------------- | -------------- | ------------------------------------------------------------------- |
| Preparação      | M11 + M17      | Uma emissão nasce estreita e comprimida                             |
| Avanço          | M02 + M08      | O fluxo progride em zigue-zague enquanto suas regiões sofrem torção |
| Divisão         | M14            | O fluxo se divide visualmente em três percursos                     |
| Desenvolvimento | M03 + M07      | Cada percurso adquire ondulação e turbulência                       |
| Reunião         | M15            | Os três fluxos convergem em uma região comum                        |
| Liberação       | M13 + M16      | Uma frente radial e uma expansão direcional se propagam visualmente |
| Encerramento    | M18 + M19      | O fluxo desaparece, deixando rastros temporários                    |

A sequência acima é uma **receita de teste do compositor**, não um Move aprovado do Crawlmon.

A duração, a aparência, o número de partículas e os valores concretos dos parâmetros não estão definidos.

O teste deve comprovar que a composição é construída reutilizando comportamentos da biblioteca, sem implementar manualmente uma trajetória exclusiva.

---

## 7. Referências helicoidais

As oito superfícies da imagem serão tratadas como estudos de referência.

A V1 deverá preservar a possibilidade de construir seus movimentos utilizando os comportamentos existentes.

Exemplos de relações:

| Referência                             | Recursos da V1 potencialmente aplicáveis |
| -------------------------------------- | ---------------------------------------- |
| Cylindrical helical strip              | Espiral helicoidal, crescimento e rastro |
| Right helicoid                         | Espiral, torção e propagação             |
| Oblique helicoid                       | Espiral, curvatura e orientação variável |
| Pseudo-developable helicoid            | Torção, curvatura e compressão           |
| Evolvent helicoid                      | Espiral, crescimento e curvatura         |
| Convolute helicoid                     | Espiral, torção e pulso viajante         |
| Degenerated convolute helicoid         | Torção, alongamento e compressão         |
| Helical surface generated by normals | Espiral, orientação local e deformações  |

Essas associações são hipóteses de composição para experimentação.

Não representam equivalência matemática demonstrada entre os comportamentos e as superfícies originais.

Se algum estudo exigir uma operação não disponível entre os 20, a lacuna deverá ser documentada. Não será criada automaticamente uma vigésima primeira operação.

---

## 8. Representações visuais

O compositor deverá produzir dados de movimento independentes da aparência.

### 8.1 Representações propostas

| Representação        | Aplicação                                      |
| -------------------- | ---------------------------------------------- |
| Pontos e marcadores  | Depuração geométrica e estudo de trajetórias   |
| Instâncias de malha  | Fragmentos, faíscas e elementos repetitivos    |
| Fitas procedurais    | Fluxos de energia, cortes e rastros contínuos  |
| Billboards           | Fumaça, brilho e elementos orientados à câmera |
| Geometria procedural | Superfícies e deformações mais complexas       |

D-044 aprova a disponibilidade de pontos, fragmentos, fitas e fumaça/billboards. A representação inicial de cada estudo continua sendo proposta técnica. Geometria procedural é um recurso de construção, sem ampliar as quatro representações aprovadas.

### 8.2 Compatibilidade

A implementação futura deverá respeitar o renderizador **GL Compatibility** efetivamente configurado no projeto.

Recursos candidatos incluem malhas procedurais, `ArrayMesh`, `MultiMeshInstance3D`, `CPUParticles3D` e shaders espaciais compatíveis.

Não deverá existir dependência obrigatória de funcionalidades exclusivas de outro renderizador.

### 8.3 Qualidade visual independente

Um movimento deverá poder ser apresentado com material neutro, sem brilho, partículas auxiliares ou cores distintas.

Esse modo permitirá avaliar se a matemática do movimento é perceptível por si mesma.

### 8.4 Relação com os sistemas atuais

O `vfx_lib.gd` existente oferece texturas, materiais, gradientes e outros recursos reutilizáveis.

O `fx_projectiles.gd` contém exemplos de apresentação de trajetórias controladas pelo progresso do ataque.

Esses componentes serão referências para a integração futura, não dependências obrigatórias do laboratório isolado.

---

## 9. Contrato temporal

### 9.1 Relógio do laboratório

O laboratório possuirá um relógio de pré-visualização controlado localmente.

Operações previstas:

- Reproduzir.
- Pausar.
- Reiniciar.
- Avançar quadro a quadro.
- Retroceder ou procurar um instante anterior.
- Alterar a velocidade de visualização.
- Repetir o trecho selecionado.

A taxa e os limites permanecem propostas técnicas. O comportamento das edições será selecionável pelo toggle da D-042 do Motion Composer.

### 9.2 Avaliação direta

Movimentos analíticos deverão permitir calcular um resultado diretamente a partir de tempo e parâmetros.

A avaliação em um instante não poderá exigir que todos os quadros anteriores tenham sido renderizados.

### 9.3 Histórico e rastros

M19 e M20 exigem atenção específica.

Os resultados históricos deverão representar posições e estados correspondentes aos instantes anteriores, não simplesmente reconstruir um rastro utilizando apenas a posição atual.

Em reprodução aleatória, retrocesso ou reinício, o laboratório deverá conseguir reconstruir o histórico de forma determinística.

Para eventos dependentes de simulação, poderão ser necessárias amostras históricas, snapshots ou reconstrução por passos determinísticos.

### 9.4 Alteração de parâmetros

A avaliação matemática deverá ser reproduzível para uma versão definida de parâmetros.

Conforme D-042 do Motion Composer, um toggle seleciona entre atualizar no instante atual reconstruindo os rastros com os novos parâmetros e reiniciar a animação desde o nascimento.

O sistema não deverá misturar silenciosamente estados históricos calculados com configurações diferentes.

### 9.5 Integração com o combate

Quando autorizada, a integração deverá respeitar D-019.

A sequência será:

**Estado autoritativo do motor → tempo da ação → avaliação visual → desenho**

Pausa de status, hit-stop e câmera lenta deverão ser representados conforme as decisões atuais de combate.

Não introduzir um relógio visual independente para determinar a conclusão lógica de ataques.

---

## 10. Laboratório independente

### 10.1 Objetivo

Permitir criar, inspecionar e comparar movimentos sem depender de personagens, mecânicas ou execução de batalhas.

### 10.2 Áreas funcionais propostas

**Catálogo:** seleção e busca dos 20 comportamentos.

**Visualização:** cena 3D com câmera ajustável, eixo de referência e modo neutro.

**Composição:** camadas ordenadas, conforme D-043. Bifurcação e recombinação operam sobre ramos identificados dentro dessa sequência.

**Parâmetros:** edição dos valores do comportamento selecionado.

**Linha do tempo:** controle de reprodução, pausa, avanço e inspeção temporal.

**Inspeção:** apresentação de posições, trajetórias, amostras, identificadores de ramos e dados de desempenho.

**Presets:** armazenamento e carregamento de configurações e composições.

A disposição visual dessas áreas ainda não está definida.

### 10.3 Inspeção individual

Cada comportamento deverá possuir uma demonstração isolada que permita reconhecer suas propriedades específicas.

O usuário deverá poder desativar outros comportamentos e observar apenas o selecionado.

### 10.4 Inspeção de composição

O laboratório deverá permitir comparar:

- Movimento isolado.
- Movimento combinado.
- Resultado sem acabamento visual.
- Resultado com representação visual.
- Estado anterior e posterior à alteração de um parâmetro.

### 10.5 Presets

Um preset deverá preservar:

- Identificação e versão.
- Comportamentos utilizados.
- Ordem de composição.
- Parâmetros e curvas.
- Referências de coordenadas.
- Máscaras e defasagens.
- Semente.
- Configuração visual, quando aplicável.
- Informações necessárias para migração de versão.

D-045 define uma pasta fixa do laboratório. O caminho concreto e o formato de serialização são propostas técnicas no adendo consolidado.

---

## 11. Integração futura com Crawlmon

**Esta seção não autoriza implementação.**

Pontos existentes identificados:

| Componente          | Possível responsabilidade futura         |
| ------------------- | ---------------------------------------- |
| `battle_fx.gd`      | Coordenação da apresentação dos eventos  |
| `fx_telegraph.gd`   | Apresentação durante o preparo           |
| `fx_projectiles.gd` | Apresentação visual durante o voo        |
| `fx_motion.gd`      | Apresentação associada à execução física |
| `fx_impacts.gd`     | Apresentação visual do impacto           |
| `vfx_lib.gd`        | Recursos e auxiliares visuais            |

A futura integração deverá possuir associações explícitas por Move, sem alterar efeitos existentes por omissão.

### 11.1 Invariantes obrigatórios

- O VFX não decide dano.
- O VFX não cria novos impactos.
- O VFX não decide esquiva.
- O VFX não determina o resultado do combate.
- A trajetória decorativa não altera a trajetória lógica.
- O VFX não modifica a posição autoritativa dos personagens.
- Pausas e escalas de tempo respeitam o motor.
- O cancelamento visual segue o evento lógico correspondente.
- Presets não sobrescrevem escolhas visuais existentes sem aprovação.

### 11.2 Divergência arquitetural existente

A documentação D-025 registra uma reversão da Fase 2, enquanto a árvore consultada contém `AttackPlanner`, `AttackMotion` e `BattleSpace`.

O laboratório independente não precisa resolver essa divergência.

Ela deverá ser reavaliada antes de qualquer integração efetiva ao combate.

---

## 12. Desempenho

O projeto deverá permitir avaliar consumo de CPU, GPU e memória.

### 12.1 Métricas

- Tempo de avaliação procedural.
- Tempo de atualização das representações.
- Quantidade de amostras ativas.
- Quantidade de elementos visuais.
- Quantidade de vértices gerados.
- Quantidade de instâncias.
- Memória ocupada por históricos.
- Desempenho com múltiplas composições simultâneas.

### 12.2 Requisitos

Os comportamentos deverão ser avaliados com a resolução necessária para a representação escolhida.

Deverão ser evitadas reconstruções completas de geometria quando não forem necessárias.

Rastros históricos deverão possuir limites configuráveis de amostragem e persistência.

O sistema deverá disponibilizar medições para comparar uma composição simples e uma composição complexa.

### 12.3 Limites pendentes

Ainda não foram aprovados:

- Hardware-alvo.
- Orçamento de CPU/GPU.
- Quantidade máxima de elementos por composição.
- Quantidade máxima de camadas.
- Número máximo de amostras de rastro.
- Resolução dos estudos visuais.
- Meta de desempenho por cenário.

Nenhum valor numérico será considerado requisito definitivo sem confirmação.

---

## 13. Testes e validação

### 13.1 Testes dos 20 comportamentos

Cada comportamento deverá possuir testes que comprovem:

1. Avaliação com parâmetros válidos.
2. Comportamento previsível nos limites declarados.
3. Ausência de valores numéricos inválidos.
4. Repetibilidade com a mesma semente.
5. Resposta a mudanças de intensidade.
6. Pausa temporal correta.
7. Funcionamento independente da representação visual.
8. Identidade de movimento distinguível dos demais.

### 13.2 Testes de composição

- Combinação em ordem diferente.
- Composição com comportamento desativado.
- Máscara temporal.
- Máscara espacial.
- Defasagem temporal.
- Transformações entre sistemas de coordenadas.
- Bifurcação e recombinação.
- Repetição de um mesmo comportamento.
- Presets carregados e salvos.
- Reprodução após alteração de parâmetros.

### 13.3 Testes temporais

- O mesmo instante produz o mesmo resultado com os mesmos parâmetros.
- Pausar preserva o estado.
- Avançar por intervalos diferentes não altera o resultado de comportamentos analíticos.
- Reiniciar reproduz o mesmo movimento.
- Buscar um instante anterior reconstrói corretamente os rastros.
- A velocidade de reprodução não altera a definição espacial da animação.

### 13.4 Testes visuais

Registrar comparações de estados significativos:

- Nascimento.
- Desenvolvimento inicial.
- Transformação principal.
- Desenvolvimento final.
- Dissipação.

Para movimentos contínuos, observar também a evolução entre os estados, não apenas capturas isoladas.

### 13.5 Testes de regressão

Na implementação futura, verificar que o laboratório pode ser executado sem alterar as cenas de combate.

Os testes atuais de VFX e combate deverão continuar sendo utilizados como referência de regressão, sem reescrevê-los para acomodar alterações não aprovadas.

---

## 14. Critérios de aprovação da V1

A biblioteca poderá ser considerada funcionalmente completa somente quando:

- Os 20 comportamentos aprovados estiverem disponíveis e individualmente inspecionáveis.
- Cada comportamento possuir parâmetros funcionais.
- A composição ordenada estiver operacional.
- Máscaras e defasagens funcionarem conforme seus contratos aprovados.
- Os movimentos puderem ser exibidos independentemente do material visual.
- A receita complexa da seção 6 puder ser construída exclusivamente combinando comportamentos da biblioteca.
- A pausa, reprodução, reinício e inspeção temporal funcionarem corretamente.
- Os rastros e pós-imagens preservarem a evolução temporal.
- Os resultados forem reproduzíveis.
- Os testes pertinentes forem executados e seus resultados registrados.
- O laboratório permanecer independente do combate.
- Os efeitos existentes forem preservados.
- Os limites de desempenho aprovados posteriormente forem atendidos.

A aprovação visual também exige avaliação humana dos movimentos renderizados. Passar em testes automatizados não equivale, sozinho, à aprovação artística.

---

## 15. Organização proposta para implementação posterior

Esta é uma divisão de responsabilidades, não uma estrutura de diretórios aprovada.

| Componente lógico | Responsabilidade                                   |
| ----------------- | -------------------------------------------------- |
| Catálogo          | Registrar os 20 comportamentos e seus metadados    |
| Avaliador         | Calcular trajetórias e deformações                 |
| Compositor        | Aplicar operações em ordem e resolver ramificações |
| Sistema temporal  | Fornecer e distribuir o tempo de avaliação         |
| Histórico         | Gerenciar rastros, pós-imagens e reconstrução      |
| Renderizadores    | Converter resultados em apresentações visuais      |
| Presets           | Persistir e validar composições                    |
| Laboratório       | Oferecer interface de edição e visualização        |
| Diagnósticos      | Medir custos e executar verificações               |

Não devem ser criados arquivos ou diretórios com base apenas nesta tabela.

---

## 16. Desenvolvimento futuro — sequência proposta

**Etapa 1 — Contratos e avaliação**

Definir formalmente entradas, saídas, tipos de operação, espaços de coordenadas e determinismo.

**Etapa 2 — Comportamentos básicos**

Implementar e validar trajetórias, campos, deformações e propagação.

**Etapa 2b — Impacto e envelopes** (acrescentada por [D-302](../decisoes/D-302-motion-composer-etapa-2b-m16-m18.md))

M16 explosão direcional, M17 crescimento progressivo e M18 dissolução progressiva, que esta seção não atribuía a nenhuma etapa.

**Etapa 3 — Composição espacial**

Adicionar bifurcação, recombinação, ordem de composição, máscaras e defasagens.

**Etapa 4 — Persistência temporal**

Adicionar rastros, pós-imagens e reconstrução de histórico.

**Etapa 5 — Laboratório visual**

Construir a interface e as ferramentas de inspeção para os 20 movimentos e composições.

**Etapa 6 — Validação completa**

Executar testes, inspecionar visualmente os movimentos, medir desempenho e documentar limitações.

Essa ordem é apenas um sequenciamento técnico proposto; não representa autorização de implementação nem escolha de organização do repositório.

---

## 17. Decisões pendentes

Situação consolidada das pendências originais; escolhas expressas posteriores prevalecem sobre a versão anexada:

| ID   | Decisão necessária                                                               |
| ---- | -------------------------------------------------------------------------------- |
| P-01 | Duração inicial e curva temporal padrão dos comportamentos                       |
| P-02 | Limites, passos e unidades de interface dos parâmetros editáveis                 |
| P-03 | Resolvido por D-042 do Motion Composer: toggle entre atualização e reinício |
| P-04 | Resolvido por D-043: camadas ordenadas |
| P-05 | D-044: pontos, fragmentos, fitas e fumaça/billboards disponíveis; aparência inicial proposta |
| P-06 | D-045: pasta fixa; caminho e formato propostos no adendo |
| P-07 | Orçamento de desempenho e hardware-alvo                                          |
| P-08 | Aparência e disposição da interface                                              |
| P-09 | Quantidade e estilo das composições demonstrativas adicionais                    |
| P-10 | D-042: reconstruir no instante atual ou reiniciar, conforme toggle; detalhes no adendo |

As escolhas confirmadas e propostas técnicas do adendo permitem concluir esta especificação. Antes de uma implementação futura, distinguir requisitos aprovados de valores experimentais; não tratar as propostas como aprovação do criador.

---

## 18. Estado da especificação

**Aprovado pelo criador:** desenvolvimento da especificação do Motion Composer com exatamente 20 comportamentos selecionados, laboratório independente, composição reutilizável e preservação dos VFX existentes.

**Definido nesta proposta:** contratos conceituais, responsabilidades, operações, requisitos temporais, organização lógica, testes e critérios de aprovação.

**Ainda proposto:** detalhes técnicos e artísticos não resolvidos pelas decisões D-042–D-045, incluindo os valores sugeridos no adendo.

(Situação da consolidação de 2026-11-03; atualizada nas seções 20 a 24.) **Não executado nessa data:** implementação, criação de cenas, criação de shaders, atualização dos VFX existentes, publicação no GitHub, commits, push e testes em execução. A documentação foi consolidada localmente nesta entrega.

Esta especificação deverá ser revista contra a versão atual do repositório antes de qualquer implementação autorizada.

## 19. Consolidação local — 2026-11-03

Este documento incorpora o anexo do criador e as respostas posteriores. Seu escopo atual é especificação, sem implementação. As propostas abaixo são escolhas técnicas sugeridas pelo agente, não falas nem aprovações do criador. Não exigem novas rodadas de perguntas para que a especificação seja concluída.

### 19.1 Decisões confirmadas

- Exatamente M01–M20; os oito estudos helicoidais são referências, não oito operadores adicionais.
- Laboratório independente; preservação integral do combate e dos VFX atuais.
- Toggle entre atualização no instante atual com reconstrução dos rastros e reinício desde o nascimento: [D-042 do Motion Composer](../decisoes/D-042-motion-composer-toggle-edicao.md).
- Camadas ordenadas: [D-043](../decisoes/D-043-motion-composer-camadas-ordenadas.md).
- Pontos, fragmentos, fitas e fumaça/billboards: [D-044](../decisoes/D-044-motion-composer-representacoes-v1.md).
- Pasta fixa para presets: [D-045](../decisoes/D-045-motion-composer-pasta-fixa-presets.md).

Há dois documentos locais com ID D-042, sobre assuntos diferentes. Os links deste documento identificam o arquivo do Motion Composer. Nenhum foi renumerado. D-061/D-077 e a afirmação de leitura de 116 decisões do anexo não foram confirmados nesta cópia; não são usados como fundamento.

### 19.2 Contrato de avaliação proposto

Uma composição recebe tempo em segundos, duração explícita, semente, revisão dos parâmetros e uma função de contexto temporal. Essa função fornece origem, destino e transformação do emissor no instante solicitado, inclusive para tempos históricos.

Cada amostra tem coordenada longitudinal normalizada, coordenadas transversais de repouso, identidade estável de elemento e caminho de ramo. Saídas contêm posição, base de orientação, largura, intensidade, opacidade e visibilidade. A intensidade neutra de um modificador deve preservar a entrada.

Proposta de domínio: eixo longitudinal local +Z; eixos transversais X/Y; comprimentos em unidades Godot; tempo em segundos; ângulos apresentados em graus e convertidos na avaliação. Uma duração deve ser finita e positiva. Intervalos degenerados, valores não finitos, parâmetros desconhecidos e seleções de ramos inexistentes devem gerar diagnóstico explícito.

A V1 propõe campos analíticos, sem acumular velocidades ou resolver física. A turbulência é função determinística da posição de referência, tempo e semente. Nenhuma chamada aleatória dependente da ordem de execução entra no avaliador.

### 19.3 Semântica das camadas proposta

Cada camada guarda ID, comportamento, habilitação, operação, seleção de ramos, espaço de coordenadas, parâmetros, curvas, máscara e intervalo temporal. Reordenar altera a sequência de avaliação, preservando IDs.

Geradores substituem a trajetória de referência; modificadores deformam a saída anterior; envelopes modulam atributos. O catálogo informa quais operações cada comportamento aceita. Combinações inválidas são diagnosticadas, sem conversão silenciosa.

Bifurcação cria caminhos estáveis derivados do ID da camada e do índice do ramo. Camadas posteriores selecionam todos os ramos ou ramos específicos. Recombinação aproxima os ramos selecionados de um destino comum; propõe-se manter suas identidades até o fim, evitando fusão destrutiva do histórico. A unificação visual ocorre pela coincidência e redução de largura/intensidade controladas.

Máscaras são pesos de 0 a 1 combinando posição longitudinal, tempo e seleção de ramo/elemento. A identidade de um ramo não depende da quantidade de quadros renderizados.

### 19.4 Tempo, edição e história propostos

O laboratório avança apenas seu relógio local. Todos os shaders novos recebem tempo explícito; o avaliador não consulta TIME nem altera Engine.time_scale.

Proposta inicial: ciclo de prévia de 3 segundos, avanço de inspeção de 1/60 segundo e velocidades 0,1x, 0,25x, 0,5x, 1x e 2x. Estes valores são ajustáveis e exclusivos do laboratório. Curvas padrão suaves para nascimento/dissipação; picos e variações próprios de cada comportamento permanecem editáveis.

No modo atualizar, uma edição cria nova revisão, invalida resultados anteriores e reavalia o instante atual e sua janela histórica. No modo reiniciar, limpa o histórico e retorna ao tempo zero. Não combinar amostras de revisões diferentes. Propõe-se atualizar no instante atual como seleção inicial, sem persistir a preferência na primeira abertura.

M19 constrói continuidade com amostras em intervalos temporais fixos; M20 cria cópias discretas. Ambos consultam o contexto de cada instante histórico. Retrocesso e seek reconstroem a janela a partir da mesma função temporal, sem depender dos quadros exibidos. Se houver movimento manual do emissor, sua trajetória precisa ser gravada; história anterior indisponível deve ser sinalizada, não inventada usando a transformação atual.

Na repetição de um trecho, propõe-se reconstruir sua janela histórica dentro do ciclo correspondente, sem conectar a cauda ao ciclo anterior. Largura e intensidade são avaliadas na idade da amostra. Orientação de fitas deve usar uma base estável, com tratamento de tangentes quase nulas e mudanças abruptas de direção.

### 19.5 Representações e interface propostas

Pontos e fragmentos usam instâncias de malha; fitas usam ArrayMesh; fumaça usa billboards com transparência. Texturas existentes podem ser reutilizadas sem chamar construtores que iniciem timers próprios. CPUParticles3D não é requisito do compositor: posições por amostra e reconstrução temporal serão controladas pelo avaliador.

A troca de representação conserva a composição. Um modo neutro permite reconhecer o movimento sem emissão luminosa. Fumaça deve permitir mistura alfa, evitando depender de adição luminosa para sua leitura. Ajustar limites de visibilidade das malhas à deformação; medir sobreposição transparente e ordenação das fitas na validação gráfica.

Proposta de interface: catálogo pesquisável à esquerda, viewport central, lista de camadas e parâmetros à direita, reprodução e linha do tempo embaixo. Cada camada oferece ativação, reordenação e seleção de ramos. A/B mantém duas revisões imutáveis com o mesmo tempo e semente. Valores numéricos têm unidade visível e validação; limites técnicos não são regras artísticas do projeto.

### 19.6 Presets propostos

Pasta fixa sugerida: user://motion_composer/presets/. Formato sugerido: JSON UTF-8 versionado. Esta escolha permite escrita na execução sem depender de alterar recursos empacotados do jogo.

Guardar versão do esquema, IDs/versionamento dos comportamentos, ordem e IDs das camadas, parâmetros, pontos das curvas, máscaras, seleções de ramos, semente, duração e configuração visual. Vetores e cores usam componentes numéricos explícitos.

Validar todo o arquivo antes de substituir a composição aberta. Versões desconhecidas ou comportamentos ausentes geram mensagem, preservando a composição atual. Salvamento proposto por arquivo temporário seguido de substituição após sucesso; nomes devem permanecer dentro da pasta fixa. Nenhum carregamento executa código de presets.

### 19.7 Receita e cobertura propostas

A receita obrigatória usa somente os operadores do catálogo: M11/M17, M02/M08, M14 com três ramos, M03/M07, M15, M13/M16 e M18/M19. Proposta: progresso normalizado com preparação 0–0,15; avanço 0,15–0,35; separação 0,35–0,5; desenvolvimento 0,5–0,65; reunião 0,65–0,75; liberação 0,75–0,85; dissipação 0,85–1. Intervalos são dados editáveis da receita, nunca tempos de um Move.

Cada M01–M20 recebe estudo individual com nascimento, desenvolvimento, transformação e dissipação. Envelopes auxiliares são identificados como apresentação do estudo e podem ser desativados para inspecionar apenas o comportamento. Os oito estudos helicoidais continuam como hipóteses de composição; não afirmar equivalência matemática com superfícies da imagem.

Proposta de primeira entrega visual: os 20 estudos e a receita obrigatória, sem composições adicionais obrigatórias. A identidade é julgada também em movimento contínuo, não apenas em screenshots.

### 19.8 Desempenho e validação propostos

Medir na máquina disponível e registrar CPU, GPU, driver, versão exata do Godot e resolução utilizada. Não prometer desempenho em hardware não ensaiado. Proposta de cenários: estudo isolado, receita complexa e oito cópias simultâneas. Registrar tempos de avaliação/atualização, quadro completo, número de vértices/instâncias e memória de histórico.

Pontos de partida experimentais: 128 amostras longitudinais por fluxo e histórico de até 1 segundo a 60 amostras por segundo. Não são limites de aceitação nem garantias de desempenho. Crescimento combinatório dos ramos deve ser contabilizado e diagnosticado antes de alocar; definir limites finais após medição.

Os testes devem verificar contratos, não copiar fórmulas: invariância ao particionamento temporal; equivalência após seek/reinício; transformação histórica de emissor móvel; ordem de camadas; máscaras; IDs de ramos; invalidação de revisão; round-trip de presets; inputs inválidos e liberdade de representação. Capturas em GL Compatibility e observação contínua completam os testes numéricos. Aprovação artística permanece humana.

### 19.9 Estado verificável desta entrega

- Especificação consolidada a partir do anexo e das decisões posteriores.
- Documentação local; sem implementação, cenas, shaders, commits ou push nesta entrega.
- D-002: decisões expressas vinculadas e catálogo registrado separadamente.
- D-003: propostas técnicas identificadas; nenhuma mudança de comportamento do jogo.
- D-019: tempo externo por instância, sem autoridade lógica do VFX.
- D-020: sistemas existentes preservados.
- D-022: nenhuma publicação ou commit.
- D-042 do Motion Composer: ambos os modos de edição preservados.
- D-043: interface por camadas ordenadas.
- D-044: quatro representações aprovadas contempladas.
- D-045: política de pasta fixa preservada; caminho concreto apenas proposto.
- Não verificado: funcionamento em Godot, aparência, desempenho, interoperabilidade de presets ou regressões em execução.
## 20. Etapa 1 implementada — 2026-11-04 (D-300)

Escopo: **somente** a Etapa 1 (contratos e avaliação). Os 20 comportamentos (Etapa 2), bifurcação/recombinação reais, histórico, laboratório visual, presets e renderizadores **não** existem. Nada do combate, de `VfxLib` ou dos VFX atuais foi tocado.

Código em `scripts/motion_composer/` (nomes de pasta e de classe são escolha técnica, não do criador); testes em `tests/motion_composer/test_etapa1_contratos.gd`:

```bash
godot --headless --path . --script res://tests/motion_composer/test_etapa1_contratos.gd
```

| Contrato | Classe | Resumo |
|---|---|---|
| Enums | `MotionTypes` | `Kind` (§4.4), `Op` (§5.2), `Space` (§5.3), `Severity` |
| Amostra | `MotionSample` | dado puro: u, rest, `element_id`, `branch`, posição, base, largura, intensidade, opacidade, visibilidade; `branch_path` e `derive_id` determinísticos |
| Contexto | `MotionContext` | tempo (s) ≠ progresso (`progress()` saturado), duração finita > 0, semente, revisão, referência, `emitter_at(t)` válido em instantes passados |
| Parâmetro | `MotionParam` | tipo, unidade, domínio; recusa NaN/infinito/tipo errado |
| Comportamento | `MotionBehavior` | id, versão, tipo, operações aceitas, parâmetros, `needs_history`, `output_count` (conferido antes de alocar), `apply` pura |
| Catálogo | `MotionCatalog` | registro; conjunto fechado `V1_IDS` (M01–M20) e `missing_v1()` |
| Camada | `MotionLayer` | id estável, operação, seleção de ramos, espaço, parâmetros, máscara, intensidade 0–1, defasagem, janela de atividade |
| Máscara | `MotionMask` | peso 0–1 por posição, tempo, elemento; degradê para fora da faixa; inversão |
| Composição | `MotionComposition` | camadas ordenadas, revisão por edição, `validate`, `evaluate` sem estado |
| Saída | `MotionResult`, `MotionDiagnostic` | amostras + diagnósticos + revisão; erro ⇒ nenhuma amostra, sem correção silenciosa |
| Espaços | `MotionSpace` | LOCAL, GLOBAL, EMITTER, TRAJECTORY (referencial por amostra; proibido para topologia/persistência) |
| Determinismo | `MotionHash` | hash de 32 bits no lugar de qualquer aleatoriedade |

Semântica adotada (proposta do agente, não aprovada pelo criador): REPLACE interpola todos os campos; OFFSET soma um deslocamento; DEFORM só geometria; MULTIPLY_ATTRIBUTE multiplica atributos; MASK só visibilidade (limiar 0,5); BRANCH/MERGE exigem TOPOLOGY e substituem as amostras selecionadas; PERSIST exige HISTORICAL e acrescenta amostras. Intensidade 0 é neutra. O comportamento sempre recebe cópias das amostras: se alterar a entrada, o fluxo anterior permanece íntegro. Camada que produziria saída não finita, ids duplicados, contagem divergente ou mais amostras que `max_samples` é ignorada com diagnóstico. Ramo inexistente na seleção gera diagnóstico e a camada é ignorada.

Valores experimentais (ajustáveis, sem valor de aceitação): `sample_count` 128, `base_length` 1,0, `max_samples` 100000, `duration` 3,0 s.

**Verificado (Godot 4.7.2, headless):** 133 verificações, 0 falhas; 4 mutações no código (peso do OFFSET, limiar do MASK, inversão de espaço, checagem de ramo inexistente) derrubaram os testes correspondentes; log sem erro/aviso. **Medido:** 9 camadas, 128→384 amostras, ≈14 ms por avaliação em GDScript puro (≈0,8 ms por camada só de compositor, mesmo com comportamento vazio), sem renderização; sem orçamento aprovado, não é requisito nem garantia. **Não verificado:** renderer GL Compatibility, qualquer aparência, desempenho em outro hardware, os comportamentos reais (dublês de teste foram usados), regressão da suíte de combate (nenhum arquivo do combate foi alterado por esta etapa).

## 21. Etapa 2 implementada — 2026-11-04 (D-301)

Escopo: **M01–M13** (trajetórias, campos, deformações, propagação). M14–M15 (Etapa 3), M19–M20 (Etapa 4) e **M16–M18 (sem etapa definida na §16; aguardam o criador)** não foram implementados. Contratos da Etapa 1 inalterados. Código em `scripts/motion_composer/behaviors/` (um arquivo por comportamento), auxiliares em `motion_profile.gd`, registro em `MotionBehaviors.register_all(catalog)`. Testes: `tests/motion_composer/test_etapa2_comportamentos.gd`.

```bash
godot --headless --path . --script res://tests/motion_composer/test_etapa2_comportamentos.gd
```

Todas as fórmulas, nomes, unidades, padrões e limites abaixo são **propostas do agente** (não aprovadas pelo criador). `u` = coordenada longitudinal de repouso (0..1); ângulos em graus; "região" = [centro ± extensão/2] em `u` com borda suave `softness`.

| ID | Comportamento | Operação | Fórmula resumida (parâmetros principais) |
|---|---|---|---|
| M01 | Espiral helicoidal | REPLACE | `(r·cosθ, r·sinθ, u·passo·voltas)`, `r = raio + evolução·u`, `θ = ±2π·voltas·u + fase + giro·t` |
| M02 | Zigue-zague | OFFSET | `amplitude · mistura(triangular, seno)(frequência·z + fase − velocidade·t)` na direção lateral `axis_deg` |
| M03 | Serpentina | OFFSET | `amplitude·sen(2π(z − v·t)/λ + fase) + ½·curvatura·z²` |
| M04 | Bézier dinâmica | REPLACE | cúbica `p0..p3`; `p1` e `p2` derivam `drift·sen(2π·Hz·t)`; `progress` limita o trecho |
| M05 | Vórtice | OFFSET | gira o componente perpendicular ao eixo por `ângulo·(1 − d/R)^decaimento` |
| M06 | Convergência | OFFSET | `(alvo − p)·atração·(1 − d/alcance)^curva·rampa_temporal` |
| M07 | Turbulência | OFFSET | ruído de valor 3D+tempo por hash inteiro; cada componente em ±intensidade |
| M08 | Torção progressiva | DEFORM/REPLACE | gira (x,y) por `ângulo·janela(u)·rampa_temporal·frente(u,t)` |
| M09 | Curvatura | DEFORM/REPLACE | gira o ponto em torno de eixo no plano XY por `ângulo·rampa(u)` |
| M10 | Alongamento | DEFORM/REPLACE | `z += (f−1)·extensão·L·rampa(u)`; monotônico (fator ≥ 1) |
| M11 | Compressão | DEFORM/REPLACE | `z = zc + (z − zc)(1 − k·janela)`; `radial` estreita x,y; monotônico (k ≤ 0,95) |
| M12 | Pulso viajante | OFFSET / MULTIPLY_ATTRIBUTE | gaussiana assimétrica (frente curta, cauda `tail`×) em `c(t) = início + v·t`; laço opcional |
| M13 | Onda radial | OFFSET / MULTIPLY_ATTRIBUTE | `exp(−((d − v·t)/largura)²)·(1 − R/alcance)^dissipação` no plano da normal |

Convenções do contrato aplicadas: OFFSET devolve deslocamento em `position`; MULTIPLY_ATTRIBUTE devolve multiplicadores (M12/M13 fixam opacidade em 1); geradores ignoram a posição anterior e preservam atributos; nada decide dano, colisão ou câmera; nenhum usa `TIME`, relógio próprio ou aleatoriedade externa.

**Verificado (Godot 4.7.2, headless):** 124 verificações, 0 falhas no teste da Etapa 2 e 133 no da Etapa 1. Cada comportamento: parâmetros padrão, todo o domínio no mínimo e no máximo (em dois instantes) sem valores não finitos, repetibilidade, intensidade 0,5 = ponto médio, pausa, ids independentes do tempo, assinaturas espaciais distintas nos 78 pares e nenhum nó criado. Fórmulas conferidas por valores analíticos. 13 mutações no código (uma por comportamento); uma sobreviveu (M11, borda suave), o teste foi reforçado e a mutação passou a falhar. **Medido:** de 1,9 a 4,1 ms por avaliação de 1 camada com 128 amostras, exceto M07 (≈8 ms), em GDScript puro e máquina ocupada; sem orçamento aprovado, não é requisito. **Não verificado:** aparência (nenhuma representação visual existe), GL Compatibility, hardware-alvo, qualidade artística das curvas e dos padrões, e a equivalência com os oito estudos helicoidais.

## 22. Etapa 2b implementada — 2026-11-04 (D-302)

Escopo: **M16, M17 e M18**, que a §16 não atribuía a nenhuma etapa; por escolha do criador ("Etapa 2b agora", [D-302](../decisoes/D-302-motion-composer-etapa-2b-m16-m18.md)) formam a **Etapa 2b**, entre as Etapas 2 e 3. Contratos das Etapas 1 e 2 inalterados (adição de três comportamentos e de dois auxiliares em `motion_profile.gd`). Código em `scripts/motion_composer/behaviors/` (`m16_…`, `m17_…`, `m18_…`); testes em `tests/motion_composer/test_etapa2b_impacto_envelopes.gd`.

```bash
godot --headless --path . --script res://tests/motion_composer/test_etapa2b_impacto_envelopes.gd
```

Todas as fórmulas, nomes, unidades, padrões e limites abaixo são **propostas do agente** (não aprovadas pelo criador).

| ID | Comportamento | Operações | Fórmula resumida (parâmetros principais) |
|---|---|---|---|
| M16 | Explosão direcional | OFFSET / MULTIPLY_ATTRIBUTE | por elemento (hash do id + semente): direção dentro de um cone (`cone_deg`, `distribution`), alcance de 50% a 100% de `distance`; `radial` mistura afastamento de `origin`; progresso `1 − (1 − p)^curva`; opacidade cai a `1 − dissipate` |
| M17 | Crescimento progressivo | MASK / MULTIPLY_ATTRIBUTE | cobertura 0..1 por varredura em `u` (`direction` 0 início→fim, 1 fim→início, 2 centro→bordas), frente em `progresso^curva × (1 + largura)`, `jitter` determinístico; canais `affect_visibility/width/intensity/opacity` |
| M18 | Dissolução progressiva | MASK / MULTIPLY_ATTRIBUTE | complemento exato de M17 com os mesmos parâmetros (crescimento + dissolução = 1) |

Garantias do contrato: no instante inicial M17 não mostra nada e M18 mostra tudo; no final, o inverso, mesmo com transição larga; a região de M17 nunca encolhe com o tempo; M16 depende só do id do elemento (o elemento 5 recebe o mesmo deslocamento com 33 ou 65 amostras); M16 não cria impactos nem altera resultado lógico; nenhum dos três usa `TIME` ou relógio próprio.

**Verificado (Godot 4.7.2, headless):** 57 verificações, 0 falhas no teste da Etapa 2b; 124 na Etapa 2 e 133 na Etapa 1, todas sem falhas (o teste da Etapa 2 foi atualizado só para refletir que agora faltam apenas M14, M15, M19 e M20). 14 mutações no código; 4 sobreviveram (alcance variável, componente radial, semente no azimute e largura da transição), os testes foram reforçados e as 4 passaram a falhar. **Não verificado:** aparência (nenhuma representação visual existe), GL Compatibility, desempenho em hardware-alvo, qualidade artística dos perfis e a escolha de canal que cada representação usará.

**Estado do catálogo:** implementados M01–M13 e M16–M18 (16 de 20). Faltam M14, M15 (Etapa 3) e M19, M20 (Etapa 4).

## 23. Etapa 3 implementada — 2026-11-04 (D-303)

Escopo ([D-303](../decisoes/D-303-motion-composer-etapa-3-composicao-espacial.md)): **M14 Bifurcação** e **M15 Recombinação**, mais a validação, com comportamentos reais, de ordem de camadas, máscaras e defasagens (que existem desde a Etapa 1), e a receita da §6 **sem M19** (Etapa 4). Código em `scripts/motion_composer/behaviors/m14_bifurcation.gd` e `m15_recombination.gd`; testes em `tests/motion_composer/test_etapa3_composicao_espacial.gd`.

```bash
godot --headless --path . --script res://tests/motion_composer/test_etapa3_composicao_espacial.gd
```

Fórmulas, nomes, unidades, padrões e limites são **propostas do agente** (não aprovadas pelo criador), seguindo a semântica proposta na §19.3.

| ID | Comportamento | Operação | Fórmula resumida |
|---|---|---|---|
| M14 | Bifurcação | BRANCH | N ramos (1–16) com caminho `pai/camada.índice` e id derivado; afastamento lateral `distância·tanh(tan(ângulo)·Δz/distância)·intensidade·rampa_temporal` a partir de `split_u`, distribuído a 360°/N desde `phase_deg` |
| M15 | Recombinação | MERGE | amostras com o mesmo `(u, rest)` formam um grupo; posição = `lerp(ramo, centroide, smoothstep(merge_start, merge_end, u)·força·rampa_temporal)`; intensidade/largura divididas entre os ramos do grupo (soma preservada com redução 1); ids, caminhos e ordem preservados |

**Refinamento do compositor (aditivo):** operação de topologia que devolve a mesma quantidade de amostras (M15; M14 com um ramo) substitui as selecionadas no lugar, preservando a ordem; quantidades diferentes seguem agrupadas na posição da primeira amostra selecionada. Operações de topologia ignoram a máscara por amostra; a intensidade da camada vale só como liga/desliga (0 = ignorada).

**Receita de teste (§6, sem M19)**, janelas por defasagem de camada com `duration` 3 s (derivadas dos intervalos propostos na §19.7): compressão (M11) e crescimento (M17) de 0 a 0,45 s; zigue-zague e torção (M02, M08) desde 0,45 s; bifurcação em 3 (M14) desde 1,05 s; serpentina e turbulência (M03, M07) desde 1,5 s; recombinação (M15) desde 1,95 s por 0,3 s; onda radial e explosão (M13, M16) desde 2,25 s; dissolução (M18) desde 2,55 s por 0,45 s. É receita de teste do compositor, não um Move do Crawlmon.

**Verificado (Godot 4.7.2, headless):** 71 verificações no teste da Etapa 3, todas sem falhas: 65 amostras até 1,05 s e 195 depois; 61 instantes sem valores inválidos; fluxos coincidentes após a reunião e afastados antes; tudo dissolvido em 3 s; receita reproduzível e independente de buscas anteriores. 10 mutações no código (M14, M15 e o refinamento do compositor) derrubam os testes. **Medido:** ≈8–9 ms por avaliação da receita completa (11 camadas, 65→195 amostras), GDScript puro, sem renderização, sem orçamento aprovado. **Não verificado:** aparência (nenhuma representação visual existe), GL Compatibility, hardware-alvo.

## 24. Auditoria das etapas 1 a 3 — 2026-11-04

Revisão feita a pedido do criador. Achados e correções:

| # | Achado | Correção |
|---|---|---|
| 1 | **IDs de decisão colidiam** com D-171 a D-174 já existentes na `main` do GitHub (outros assuntos). | Renumerados para **D-300 a D-303**. Foram D-171–D-174 e depois D-230–D-233, mas a `main` passou a usar esses números em rodadas novas (maior ID remoto visto: D-234); a faixa D-300+ é reservada ao Motion Composer para evitar novas colisões (escolha técnica do agente). |
| 2 | Comportamento que alterasse a entrada corrompia o fluxo no espaço LOCAL (introduzido por otimização). | Corrigido na Etapa 1 (cópias sempre) com 2 testes. |
| 3 | Testes de catálogo das Etapas 2 e 2b ainda esperavam M14 e M15 ausentes. | Atualizados (faltam apenas M19 e M20). |
| 4 | Verificações vazias ou frouxas nos testes (`or true`, variável sem uso, condição que não distinguia M11, M16, M17, M15). | Removidas ou reforçadas; 4 + 1 mutantes sobreviventes passaram a falhar. |
| 5 | Três testes errados da Etapa 3 (Δz numérico, ids comparados entre camadas de nomes distintos, limite de ramos acima do domínio). | Corrigidos; o código estava certo. |
| 6 | Texto da especificação desatualizado (§16 sem Etapa 2b; §18 afirmava que nada fora executado). | Atualizado. |
| 7 | Regressão do combate nunca havia sido rodada. | `test_d040_1atb`, `test_battle_load` e `test_attack_motion` rodam sem falha (árvore local com alterações de terceiros; nenhum arquivo de combate foi alterado por estas etapas). |

**Continua pendente (não esquecido, não autorizado):** M19 e M20 e o histórico (feitos depois, na Etapa 4: §25); laboratório visual, presets e representações (Etapa 5); validação completa, GL Compatibility, orçamento de desempenho e aprovação artística (Etapa 6). 18 dos 20 comportamentos existiam nesta auditoria; com a Etapa 4 (§25) são 20 de 20.

## 25. Etapa 4 implementada — 2026-11-04 (D-304)

Escopo ([D-304](../decisoes/D-304-motion-composer-etapa-4-persistencia-temporal.md)): **M19 Rastro temporal**, **M20 Pós-imagem** e a **reconstrução determinística do histórico**. Com isso os 20 comportamentos M01–M20 existem (`MotionCatalog.missing_v1()` vazio). Código em `scripts/motion_composer/behaviors/m19_temporal_trail.gd`, `m20_afterimage.gd` e `motion_history.gd`; testes em `tests/motion_composer/test_etapa4_persistencia.gd`.

```bash
godot --headless --path . --script res://tests/motion_composer/test_etapa4_persistencia.gd
```

**Como o histórico é reconstruído (§9.3, §19.4):** o compositor entrega às camadas PERSIST uma função `MotionContext.history_fn(t)` que reavalia, do zero, as camadas **anteriores** no instante `t` (com as suas janelas, defasagens e parâmetros daquele instante). Não há estado entre avaliações, nem dependência de quadros exibidos: seek, retrocesso e reinício produzem o mesmo resultado, e mudar um parâmetro reconstrói tudo com a nova revisão. O histórico do emissor vem de `emitter_at(t)` em instantes passados. Adições aditivas aos contratos: `MotionContext.history_fn` e `MotionSample.age`.

Fórmulas, nomes, unidades, padrões e limites são **propostas do agente** (não aprovadas pelo criador).

| ID | Comportamento | Operação | Resumo |
|---|---|---|---|
| M19 | Rastro temporal | PERSIST | por elemento, `N = round(duration / sample_interval)` (1–256) amostras do **próprio estado** em `t − j·dt`, formando **um ramo contínuo** ordenável por `age`; largura `lerp(width_start, width_end, idade/duração)`, opacidade `(1 − idade/duração)^fade_curve` |
| M20 | Pós-imagem | PERSIST | `count` (1–16) cópias do estado em `t − k·interval`, **cada uma um ramo** (`pai/camada.k−1`); opacidade em degraus `1 − fade·k/(count+1)`; largura × `scale^k` |

`world_space` (ambos): desligado, o efeito acompanha o emissor (coordenadas locais do instante passado); ligado, a história fica no mundo, `E(t)⁻¹·E(t − idade)·p`, preservando posição e direção do emissor. Amostras anteriores ao instante 0 (ou sem histórico) são mantidas **invisíveis**, para que contagem e ids não mudem. A **diferença obrigatória** do grupo H vale: rastro = fluxo contínuo que afina e some; pós-imagem = estados discretos em ramos separados que preservam os atributos do estado.

**Verificado (Godot 4.7.2, headless):** 72 verificações no teste da Etapa 4 (60 originais + 12 da auditoria abaixo) e todas as anteriores (133 + 124 + 57 + 71), todas sem falhas: 457 no total. Cada amostra histórica confere com o fluxo avaliado de forma independente em `t − idade`; seek/retrocesso/reinício idênticos; emissor em linha e em giro conferidos pela fórmula; histórico de histórico (M20 sobre M19); janelas de atividade das camadas anteriores respeitadas em cada instante passado; domínio no mínimo e no máximo sem valores inválidos. 14 mutações no código (M19, M20, histórico e compositor) derrubam os testes, mais 7 nas correções da auditoria. **Medido:** M19 padrão com 128 amostras de entrada (1408 de saída, 11 reavaliações do fluxo) ≈ 40 ms por avaliação em GDScript puro e máquina ocupada; o custo cresce com a quantidade de amostras históricas e com o custo das camadas anteriores, e não há orçamento aprovado (§12.3). **Não verificado:** aparência (nenhuma representação visual existe), GL Compatibility, hardware-alvo, orçamento de desempenho, qualidade artística, e o comportamento ao repetir um trecho em laço (depende do laboratório, Etapa 5).

**Auditoria da Etapa 4 (2026-11-04, a pedido do criador) — o que havia sido esquecido e foi corrigido:**

| # | Lacuna contra a especificação | Correção |
|---|---|---|
| 1 | §3 grupo H pede *intensidade* como propriedade controlável; M19 e M20 só variavam largura/tamanho e opacidade. | M19 `intensity_end`; M20 `intensity_fade` (padrões neutros). |
| 2 | §19.4: ao repetir um trecho, a janela histórica não pode conectar a cauda ao ciclo anterior; só existia o corte em t = 0. | `MotionContext.history_start` (e `MotionComposition.history_start`, repassado ao contexto). |
| 3 | §12.2: limites de amostragem e persistência "configuráveis"; o teto de 256 era constante. | M19 `max_samples` (1–1024, padrão 256). |
| 4 | §19.4: história do emissor indisponível "deve ser sinalizada, não inventada". | Aviso `layer_emitter_history_missing` (não é erro) quando `world_space` é pedido sem `emitter_fn`. |
| 5 | §12.1: métricas de inspeção (quantidade de amostras, tempo de avaliação) não existiam. | `MotionResult.stats`: `samples`, `history_samples`, `layers_active`, `eval_usec`. |
| 6 | Custo: o emissor era consultado por amostra e por idade. | Transformação relativa calculada uma vez por idade. |

**Ainda não coberto (não é esquecimento, depende de etapas não autorizadas):** orientação estável de fitas e tratamento de tangentes quase nulas (§19.4) são do renderizador de fitas (Etapa 5); a repetição de trecho em laço só pode ser exercitada com o relógio do laboratório (Etapa 5); orçamento e medições em hardware-alvo (Etapa 6).

**Pendente (não autorizado):** laboratório visual, presets e representações (Etapa 5); validação completa, desempenho, GL Compatibility e aprovação artística (Etapa 6).

## 26. Etapa 5, fatia 1 — laboratório e representação Pontos — 2026-11-04 (D-305)

Escopo ([D-305](../decisoes/D-305-motion-composer-etapa-5-laboratorio-visual.md)): a Etapa 5 é entregue **em fatias, uma mudança visual por vez, com aprovação do criador entre elas**. Esta fatia traz a base testável e **uma** representação. Tudo usa objetos e shaders do Godot (nenhum HTML): `MultiMeshInstance3D`, `SphereMesh`, `ShaderMaterial` com `shaders/motion_lab/motion_point.gdshader` (spatial, `unshaded`, GL Compatibility), `ImmediateMesh` para eixos e grade, `Camera3D`, controles de UI do Godot.

```bash
godot --path . res://scenes/motion_lab/motion_lab.tscn
godot --path . res://scenes/motion_lab/motion_lab.tscn -- --capture=C:/pasta/saida.png --t=1.2 --frames=8
```

| Parte | Arquivo | Resumo |
|---|---|---|
| Relógio | `lab/motion_clock.gd` | reproduzir, pausar, reiniciar, ±1 quadro (1/60 s), seek, velocidades 0,1x–2x, laço e trecho repetido; `history_start` = início do trecho (§19.4) |
| Sessão | `lab/motion_lab_session.gd` | composição, catálogo, relógio, **toggle D-042** (atualizar no instante atual ↔ reiniciar), isolamento de camada, emissor de demonstração (parado, linha, órbita) |
| Presets | `lab/motion_presets.gd` | JSON UTF-8 versionado em `user://motion_composer/presets/` (D-045): vetores como x/y/z, validação completa antes de substituir, versão desconhecida recusada, gravação atômica, nomes restritos; nunca executa código |
| Pontos | `lab/motion_points_view.gd` + shader | um ponto por amostra visível, cor por ramo, alfa = opacidade, brilho = intensidade; neutro (§8.3) |
| Laboratório | `lab/motion_lab.gd` + `scenes/motion_lab/motion_lab.tscn` | viewport 3D (botão direito gira, meio move, roda aproxima), catálogo M01–M20 com busca, camadas ordenadas (adicionar, subir/descer, ligar/desligar, isolar, remover), parâmetros gerados dos descritores (com unidades), linha do tempo, presets, estatísticas e diagnósticos |

**Propostas do agente (não aprovadas):** disposição em dois painéis (P-08), pasta e formato dos presets, modo inicial "atualizar no instante atual" sem persistir a preferência, cores por ramo, ciclo de 3 s, 64 amostras na demonstração.

**Verificado:** 79 verificações do relógio, da sessão e dos presets (ida e volta idêntica em 4 instantes; 17 formas de preset inválido recusadas; nenhum arquivo temporário sobra) e 17 do laboratório instanciado (adicionar, reordenar, ligar, isolar, remover, editar nos dois modos, salvar e carregar presets pela interface; o material é `ShaderMaterial` com `.gdshader`); execução em janela com GL Compatibility (NVIDIA GeForce RTX 2050) sem erros, com a captura mostrada ao criador. As sete suítes somam 553 verificações, todas sem falhas. **Medido:** avaliação ≈ 28–36 ms por quadro na demonstração (832 amostras, rastro de 12 idades), o que limita a prévia a cerca de 30 quadros/s; sem orçamento aprovado.

**Não feito nesta fatia (aguarda aprovação visual):** Fitas, Fragmentos e Fumaça/billboards (D-044); comparação A/B; estudos individuais dos 20 comportamentos e a receita da §6 como demonstração; seleção de ramos e máscaras na interface; reprodução do trecho em laço pela interface. **Não verificado:** aparência aprovada pelo criador, desempenho em outro hardware, comportamento da interface em resoluções pequenas.

## 27. Etapa 5, fatia 2 — representação Fitas — 2026-11-04 (D-305)

Aprovação da fatia anterior pelo criador, literal: "estao otimos" (aparência dos Pontos, vídeos da §26). Esta fatia acrescenta **uma** representação: **Fitas**. Objetos e shader do Godot: `ArrayMesh` reconstruído por quadro num `MeshInstance3D`, `ShaderMaterial` com `shaders/motion_lab/motion_ribbon.gdshader` (spatial, `unshaded`, `cull_disabled`, GL Compatibility); nada de HTML.

| Parte | Arquivo | Resumo |
|---|---|---|
| Geometria (dado puro) | `lab/motion_ribbon_builder.gd` | agrupa as amostras em fitas e gera vértices, cores, UVs, índices e AABB |
| Vista | `lab/motion_ribbons_view.gd` | uma superfície de `ArrayMesh` por quadro, `custom_aabb` própria |
| Shader | `shaders/motion_lab/motion_ribbon.gdshader` | cor e alfa dos vértices; borda suavizada por `UV.y` |
| Laboratório | `lab/motion_lab.gd` | seletor Pontos / Fitas / Pontos + fitas; largura da fita; `--rep=pontos|fitas|ambos` |

**Agrupamento (genérico, sem saber qual comportamento gerou as amostras):** por ramo. Se todas as amostras do ramo têm a mesma idade, é uma fita de *estado* ordenada por `u` (fluxo atual, cada ramo de bifurcação, cada pós-imagem). Se as idades variam (rastro M19), cada elemento é uma fita de *história* ordenada por idade, começando na amostra atual do mesmo elemento (sem vão).

**Orientação (§19.4):** base de rotação mínima (transporte paralelo) a partir da base da primeira amostra; tangente nula reaproveita a anterior; inversão de 180° não gira a fita. Segmentos só são omitidos quando as **duas** pontas estão ocultas, para o rastro sumir por alfa e não ser cortado. Largura = largura-base × largura da amostra; alfa do vértice = opacidade (0 se invisível); brilho = intensidade; matiz por ramo (ângulo áureo por índice, nome da camada embaralhado). Trocar a representação não altera a composição, a revisão nem o relógio (testado).

**Verificado:** 43 verificações da geometria (agrupamento de fluxo, rastro, bifurcação e pós-imagem; ordem mesmo com entrada invertida; cabeça do rastro; base estável em reta, inversão de 180°, pontos coincidentes e hélice; atributos por ponto; AABB; determinismo) e 22 do laboratório (incluindo a troca de representação); as oito suítes somam 601 verificações, todas sem falhas. 10 mutações no construtor derrubam os testes (uma, a de tangente nula, é equivalente: o resultado geométrico não muda). Execução em janela com GL Compatibility sem erros; vídeos mostrados ao criador. **Medido:** construção das fitas ≈ 5 ms por quadro com 704 amostras (GDScript, headless).

**Não verificado:** aparência aprovada pelo criador; a ordenação de fitas translúcidas sobrepostas (o shader não escreve profundidade, §19.5 pede medição); fitas viradas de lado (fitas planas somem quando vistas de perfil, sem versão voltada para a câmera); desempenho em outro hardware. **Faltam:** Fragmentos e Fumaça/billboards (D-044), comparação A/B, estudos individuais dos 20, seleção de ramos e máscaras na interface.

## 28. Etapa 5, fatia 3 — representação Fragmentos — 2026-11-04 (D-305)

Aprovação da fatia anterior, literal: "ok, oque deve prosseguir agora, aprovo ambos" (vídeos de Fitas). Esta fatia acrescenta **uma** representação: **Fragmentos** (instâncias de malha, D-044, §8.1). Objetos e shader do Godot: `MultiMeshInstance3D` com malha procedural `ArrayMesh` de estilhaço (bipirâmide achatada, 6 faces com normais planas) e `ShaderMaterial` com `shaders/motion_lab/motion_fragment.gdshader` (spatial, `unshaded`, "luz de cabeça" fixa na câmera para ler as facetas, GL Compatibility); nada de HTML.

| Parte | Arquivo | Resumo |
|---|---|---|
| Vista | `lab/motion_fragments_view.gd` | um fragmento por amostra visível; `fragment_basis` orienta pela base da amostra (eixo longo = tangente) com giro (0–360°) e inclinação (±54°) fixos por elemento e tamanho de 60 % a 140 % do base, tudo derivado do id do elemento (estável no tempo) |
| Shader | `shaders/motion_lab/motion_fragment.gdshader` | cor e alfa da instância (matiz por ramo, opacidade, intensidade), facetas marcadas |
| Laboratório | `lab/motion_lab.gd` | quarto item do seletor de representação; controle de tamanho do fragmento; `--rep=fragmentos`; `--demo=estilhacos` |

**Demonstração `estilhacos` (não é um Move):** hélice M01 que nasce (M17), explode para fora (M16 OFFSET com componente radial) e se dissipa (M16 MULTIPLY com curva 0,5, mais lenta que o deslocamento), ciclo de 2,4 s.

**Verificado:** 22 verificações dos fragmentos (determinismo e variação por elemento; bases ortogonais sem espelhamento e escala uniforme; faixa de tamanho; giro cobre toda a volta; inclinação até 54°; malha de 18 vértices com normais planas, unitárias, para fora e coerentes com o enrolamento horário; forma de estilhaço; MultiMesh com cor por instância; invisíveis, transparentes e de tamanho 0 descartados) e 25 do laboratório (troca para Fragmentos conserva composição, revisão e relógio). As nove suítes somam 648 verificações, todas sem falhas. 10 mutações no código derrubam os testes (3 sobreviventes iniciais, de giro, inclinação e semente por id, foram cobertos por testes de direção independentes do tamanho). Execução em janela com GL Compatibility sem erros; vídeos mostrados ao criador. Duas correções feitas ao olhar os quadros e os testes: a dissipação da demonstração ficava rápida demais (agora uma curva própria) e a inclinação máxima real é 54°, não 27°. **Medido:** preencher 256 fragmentos ≈ 1,5 ms por quadro (GDScript, headless).

**Não verificado:** aparência aprovada pelo criador; fragmentos com giro no tempo (hoje a orientação é fixa por elemento; girar exigiria um tempo explícito no shader); a orientação segundo a direção real do movimento (hoje segue a base da amostra); desempenho em outro hardware. **Faltam:** Fumaça/billboards (D-044), comparação A/B, estudos individuais dos 20, seleção de ramos e máscaras na interface.

## 29. Etapa 5, fatia 4 — representação Fumaça/billboards (poeira) — 2026-11-04 (D-305)

Aprovação da fatia anterior, literal: "prossiga" (vídeos de Fragmentos). Esta fatia acrescenta a última representação da D-044: **Fumaça/billboards** (§8.1).

**Histórico de rejeições do criador (literal) e correções:**
1. "Não gostei n parece fumaça nem dust": a primeira versão (folha `flipbook_smoke.png`, baforadas de 20 cm esverdeadas, enfileiradas) parecia uma lagarta. Descartada.
2. "Não estou satisfeito ainda": a segunda (baforadas macias, tamanho 35 cm, vida longa) continuava borrada e sem a cara da poeira do jogo. Perguntei o que incomodava; o criador marcou **borrada/mole demais, formato de nuvem/algodão, cor ou luz e movimento**, com referência **a poeira do jogo (D-041)**.
3. Refeita medindo a referência: renderizei a poeira real do jogo (`fx_motion._dust_trail` + `fx_impacts._smoke`, via `VfxLib`, mesma cena e câmera) e copiei suas regras. Dois erros meus apareceram na comparação lado a lado: eu tinha **suavizado a textura** (a do jogo é manchada) e a baforada esmaecia **duas vezes** (pela rampa de vida e pelo esmaecimento do rastro), por isso ficava fraca.

4. "Tá melhor, mas poeira mexe muito com opacidade, não estou vendo tanta": a quarta versão acrescenta o **jogo da opacidade**: cada baforada tem densidade própria (de 0,35 a 1; umas são véus, outras densas), a opacidade **oscila** com a idade (3 a 7 Hz, fase própria) e a queda depois do pico tem **curva ajustável** (expoente 1,5; 1 = reta do jogo); a vida padrão subiu de 0,38 s para 0,55 s para dar tempo de ver. Os quatro controles têm slider; com densidade 0, oscilação 0 e expoente 1 a opacidade volta a ser exatamente a rampa do jogo.

**Regras copiadas da poeira do jogo:** baforadas de 0,55 a 1,15 m com ruído manchado (simplex suave, frequência 0,07, 3 oitavas, alfa = (1 − r)^1,2 × clamp(ruído × 1,6)); cor bege (0,82; 0,78; 0,72); vida de 0,38 s; opacidade 0 → 0,75 aos 20 % da vida → 0; crescimento até 1,8×; saída de uma esfera de 0,4 m, em qualquer direção, de 0,5 a 3 m/s, com atrito 1,5 e subida 0,25 m/s²; mistura alfa, sem adição luminosa (§19.5).

Objetos e shader do Godot: `MultiMeshInstance3D` de `QuadMesh` com cor e dados por instância, `ShaderMaterial` com `shaders/motion_lab/motion_smoke.gdshader` (spatial, `unshaded`, quad voltado para a câmera, GL Compatibility); nada de HTML. A textura é um **atlas 2 × 2 gerado em código** (`MotionSmokeView.make_puff_atlas`, o mesmo cálculo do `VfxLib.smoke_tex`, 4 sementes), sem depender do código de combate e sem temporizadores.

| Parte | Arquivo | Resumo |
|---|---|---|
| Vista | `lab/motion_smoke_view.gd` | `puff_params` (giro, variação do atlas e tamanho 65–135 % por elemento; crescimento pela idade), `puff_alpha` (rampa de vida), `puff_offset` (esfera de origem, velocidade com atrito, subida; função pura do id e da idade, decoração da vista, zerável), `back_to_front` (ordenação por câmera) |
| Shader | `shaders/motion_lab/motion_smoke.gdshader` | giro e variação por instância (`INSTANCE_CUSTOM`); cor e alfa da instância; sem tempo próprio |
| Laboratório | `lab/motion_lab.gd` | quinto item do seletor; sete controles da poeira; caixa "chão que oculta o que passa de y = 0" (como o chão do jogo oculta a metade que desce); emissor "Corrida (8 m/s)"; `--rep=fumaca`; `--demo=fumaca` (dois "pés" a 0,44 m deixando poeira de corrida atrás do emissor, rastro M19 preso ao mundo) e `--demo=estilhacos` com a poeira |

**Verificado:** 64 verificações da fumaça (as 48 anteriores e 16 do jogo da opacidade: densidade entre 0,35 e 1 espalhada pela faixa, oscilação entre 1 − quantidade e 1 com fase própria, curva, opacidade final variando entre baforadas da mesma idade): determinismo; giro, tamanho (0,55–1,15 m) e variação do atlas por elemento sem piscar com a idade; crescimento 1,8× e teto; rampa de opacidade (0,375 aos 10 %, 0,75 aos 20 %, 0 no fim); atrito, subida (½·g·t²) e esfera de origem; direções cobrindo a esfera; atlas de 128 px com 4 variações diferentes, cantos transparentes e miolo denso; ordenação do mais distante ao mais próximo e permutação completa; a vista desenha nessa ordem; descarte de invisíveis, transparentes e mais velhas que a vida; `blend_mix` sem `blend_add`. 11 mutações no código derrubam os testes (uma sobrevivia, a esfera de origem, e foi coberta). As dez suítes somam 739 verificações, todas sem falhas. Execução em janela com GL Compatibility sem erros. **Medido:** preencher e ordenar 1088 baforadas ≈ 7 ms por quadro (GDScript, headless).

**Não verificado:** a aprovação visual do criador da versão atual; o cascalho brilhante (partículas pequenas e claras) que a poeira do jogo também tem; fumaça com profundidade suave nas interseções; a ordenação entre representações mostradas juntas; desempenho em outro hardware. **Faltam:** comparação A/B, estudos individuais dos 20 comportamentos, seleção de ramos e máscaras na interface.
