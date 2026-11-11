# Crawlmon — Especificação do Motion Composer V1

> **Escopo (D-383, 2026-11-06):** esta especificação é do Motion Composer para **VFX de Move/combate**. Clima/exploração (névoa, calor, chuva/neve, distorção temporal) não usa o Composer.

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

**Etapa 2b — Impacto e envelopes** (acrescentada por [D-232](../decisoes/D-232-motion-composer-etapa-2b-m16-m18.md))

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
## 20. Etapa 1 implementada — 2026-11-04 (D-230)

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

## 21. Etapa 2 implementada — 2026-11-04 (D-231)

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

## 22. Etapa 2b implementada — 2026-11-04 (D-232)

Escopo: **M16, M17 e M18**, que a §16 não atribuía a nenhuma etapa; por escolha do criador ("Etapa 2b agora", [D-232](../decisoes/D-232-motion-composer-etapa-2b-m16-m18.md)) formam a **Etapa 2b**, entre as Etapas 2 e 3. Contratos das Etapas 1 e 2 inalterados (adição de três comportamentos e de dois auxiliares em `motion_profile.gd`). Código em `scripts/motion_composer/behaviors/` (`m16_…`, `m17_…`, `m18_…`); testes em `tests/motion_composer/test_etapa2b_impacto_envelopes.gd`.

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

## 23. Etapa 3 implementada — 2026-11-04 (D-233)

Escopo ([D-233](../decisoes/D-233-motion-composer-etapa-3-composicao-espacial.md)): **M14 Bifurcação** e **M15 Recombinação**, mais a validação, com comportamentos reais, de ordem de camadas, máscaras e defasagens (que existem desde a Etapa 1), e a receita da §6 **sem M19** (Etapa 4). Código em `scripts/motion_composer/behaviors/m14_bifurcation.gd` e `m15_recombination.gd`; testes em `tests/motion_composer/test_etapa3_composicao_espacial.gd`.

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
| 1 | **IDs de decisão colidiam** com D-171 a D-174 já existentes na `main` do GitHub (outros assuntos). | Renumerados para **D-230 a D-233** (maior ID remoto: D-229). |
| 2 | Comportamento que alterasse a entrada corrompia o fluxo no espaço LOCAL (introduzido por otimização). | Corrigido na Etapa 1 (cópias sempre) com 2 testes. |
| 3 | Testes de catálogo das Etapas 2 e 2b ainda esperavam M14 e M15 ausentes. | Atualizados (faltam apenas M19 e M20). |
| 4 | Verificações vazias ou frouxas nos testes (`or true`, variável sem uso, condição que não distinguia M11, M16, M17, M15). | Removidas ou reforçadas; 4 + 1 mutantes sobreviventes passaram a falhar. |
| 5 | Três testes errados da Etapa 3 (Δz numérico, ids comparados entre camadas de nomes distintos, limite de ramos acima do domínio). | Corrigidos; o código estava certo. |
| 6 | Texto da especificação desatualizado (§16 sem Etapa 2b; §18 afirmava que nada fora executado). | Atualizado. |
| 7 | Regressão do combate nunca havia sido rodada. | `test_d040_1atb`, `test_battle_load` e `test_attack_motion` rodam sem falha (árvore local com alterações de terceiros; nenhum arquivo de combate foi alterado por estas etapas). |

**Continua pendente (não esquecido, não autorizado):** M19 e M20 e o histórico (Etapa 4); laboratório visual, presets e representações (Etapa 5); validação completa, GL Compatibility, orçamento de desempenho e aprovação artística (Etapa 6). 18 dos 20 comportamentos existem.

## 25. V1.1 — geometria de tubo, esfera de fogo, flipbooks e anel (D-322, 2026-11-05)

Motivo: o fogo anterior era feito de quads planos (`fire_flame`) e fitas finas, o "HTML genérico" que o criador reprovou (D-308). O Motion Composer não tinha uma representação com **volume**. Acrescentado, sem mudar nenhum contrato das Etapas 1–3 nem nenhum comportamento M01–M18:

| Peça | Arquivo | O que faz |
|---|---|---|
| `MotionMesh.tube` | `scripts/motion_composer/representations/motion_mesh.gd` | Pontos de um fluxo → **tubo fechado** (quadro de transporte paralelo, sem torção; tampa arredondada na cabeça). UV.y em **metros**, cor de vértice = posição, intensidade, progresso de dissolução. Dado puro, sem Node. |
| `MotionPainter.tube / bulb / flipbook` | `motion_painter.gd` | Pincéis em pool: malha de tubo reenviada a cada quadro, esfera/fuso com o shader de chama, sprite de flipbook do jogo. |
| Representações `tube`, `bulb`, `flipbook`, `ring` | `motion_rep.gd` | `tube` agrupa por **ramo** (M14 vira vários tubos), `flip` inverte base/ponta (línguas que nascem num ponto de contato). |
| Shader `mc_flame_body` | `shaders/mc_flame_body.gdshader` | Chama em cel-shading (bandas duras) **volumétrica**: silhueta empurrada por ruído que escorre e sobe, centro quente/borda vermelha, cauda corroída por ruído. Opaco (alpha-test), sem ordenação, serve ao GL Compatibility. Tempo explícito. |
| `MotionEffect`: itens com `branch`; opção `z_offset` | `motion_effect.gd` | Centraliza uma hélice sobre a bola; as representações sabem a qual ramo cada amostra pertence. |

Teste: `tests/motion_composer/test_v11_tubos_e_receitas.gd` (geometria, casos degenerados, espelhamento, camadas do fogo).

```bash
godot --headless --path . --script res://tests/motion_composer/test_v11_tubos_e_receitas.gd
```

Não verificado nesta versão: desempenho em hardware-alvo e a aprovação artística (humana).

## 26. V1.2 — formas, materiais estilizados, campos, partículas e laboratório de avaliação (D-323, 2026-11-05)

Pedido do criador (D-323): melhorar o Composer **antes de qualquer efeito**, para fogo, água, terra e ar saírem direito, **estilizados** (cel-shading em bandas duras, o estilo do jogo, D-038; "semi-realista" foi descartado). Nenhum efeito, Move ou regra existente foi tocado. M01–M20 intactos; o conjunto fechado V1 (`V1_IDS`) não mudou.

| Área | O que entrou | Onde |
|---|---|---|
| **Campos de movimento** (V1.2, fora do `V1_IDS`) | **M21** fluxo direcional (centro limpo, borda turbulenta), **M22** arrasto (`v0(1-e^{-kt})/k`), **M23** gravidade visual (`½gt²`), **M24** turbulência coerente (rotacional de potencial analítico: sem divergência), **M25** repulsão. Todos OFFSET analíticos, sem estado, determinísticos. Registro: `MotionBehaviors.register_v12`. | `scripts/motion_composer/behaviors/m21..m25_*.gd` |
| **Geradores de forma** | `MotionShapes`: **fita**, **lâmina** (fita de folha), **arco**, **casca** (cone/cúpula) e **conjunto de fragmentos** (blocos de faces planas, com giro vindo do compositor); o **tubo curvo** segue em `MotionMesh`. Mesmo layout de vértice para todos. | `representations/motion_shapes.gd` |
| **Materiais estilizados** | `mc_surface`: rampa de 5 cores com **bandas duras**, **volume** (lado sombreado em degraus, borda clara/espuma), **gradiente por idade**, **erosão** da silhueta com beira, **deformação de vértices** (lambida, ondulação, pulsação), detalhe de textura que escorre. Opaco (alpha-test), GL Compatibility. Função comum em `mc_common.gdshaderinc`. | `shaders/mc_surface.gdshader` |
| **Partículas e resíduos** (representações novas, com shaders próprios) | `spark` (fagulha/gota brilhante esticada), `puff` (fumaça/vapor/poeira/névoa em 3 degraus), `drops` (gotas/bolhas/pedrinhas), `halo`, `mark` (queimado/poça/rachadura/arrasto no chão, sem Decal), `surface` (qualquer forma acima). | `representations/motion_rep.gd`, `motion_painter.gd`, `shaders/mc_spark/puff/halo/mark` |
| **Acabamento por elemento** | `MotionLooks`: fogo, água, terra e ar, só dados (uniforms). O **mesmo movimento** troca de linguagem visual só mudando `element`. | `representations/motion_looks.gd` |
| **Ferramentas de avaliação** | `MotionGallery` (8 amostras neutras, não são Moves) + `tests/vfx/mc_lab.gd`: fundo escuro e claro, vista normal e **espelhada**, instantes exatos, **A/B com a mesma semente**, tempo de avaliação, nós e triângulos, sobras aos 4 s. `MotionPainter.stats()`. | `lab/motion_gallery.gd`, `tests/vfx/mc_lab.gd` |

Rodar o laboratório (janela, não headless): `godot --path . --script res://tests/vfx/mc_lab.gd --resolution 1280x720 -- --out=<pasta>`. Imagens de referência em `docs/vfx/galeria/`.

Testes novos: `test_v12_campos` (34), `test_v12_formas` (34), `test_v12_looks` (uniformes de cada look existem no shader; olhares distintos; galeria sem erro), `test_v11_tubos_e_receitas`. Mais as 4 suítes anteriores (133, 124, 57, 71 verificações), todas sem falhas.

**Medido (RTX 2050, GL Compatibility, GDScript):** a galeria inteira (8 células, até 77 nós e ~17,9 mil triângulos) custa 13–40 ms por quadro só de avaliação e montagem; o tubo é a célula mais cara (~8 ms). Repetibilidade com a mesma semente: diferença de imagem 0,000000; semente diferente: 0,015–0,024. Aos 4 s: 0 nós desenhados nos quatro elementos.

**Não feito (não escolhido pelo criador nesta rodada):** cache de histórico, invalidação por dependência e amostragem adaptativa (D-274 item 7); interface de edição (grupos de camadas, solo, visibilidade); o custo acima é a razão provável para o item 7 ser o próximo. **Não verificado:** aprovação artística (humana), desempenho em outro hardware, uso dentro de um Move na batalha real.

## 27. V1.3 — fogo estilizado por shader + flipbook (D-332, 2026-11-05)

Pedido do criador: o fogo deixa de ser modelo 3D e passa a ser **shader + flipbook + Composer**, com **Persona, Genshin Impact e Pokémon** como referência. Nenhum efeito existente foi alterado.

| Peça | Arquivo | O que faz |
|---|---|---|
| Shader `mc_fire_cel` | `shaders/mc_fire_cel.gdshader` | Chama de **contorno nítido**: 5 línguas em gota (base redonda, ponta fina que se curva) desenhadas por funções de distância, **3 camadas de cor chapada** (casca, miolo, núcleo) e contorno escuro. Balanço **periódico** em `phase` (0..1 = um ciclo): serve ao vivo e ao flipbook. `fade` encolhe pelas pontas. Sem textura, sem ruído; tempo explícito. |
| Flipbook `fire_cel` | `assets/vfx/flipbook_fire_cel.png` | 16 quadros (4x4, 256 px) **assados do mesmo shader** por `tests/vfx/bake_fire_cel.gd`, em ciclo (o último volta ao primeiro). |
| Shader `mc_sprite` | `shaders/mc_sprite.gdshader` | Sprite de flipbook com **mistura alfa** (o aditivo antigo lava cores chapadas em fundo claro). |
| Representações `cel_flame`, `sprite` | `motion_rep.gd`, `motion_painter.gd` (`cel_flame`, `sprite`) | `cel_flame`: uma chama por amostra do compositor, ponta para cima (`follow` vira a ponta para o movimento), fase de balanço por amostra. `sprite`: o flipbook por amostra. |
| Demonstrações | `tests/vfx/cel_fire_lab.gd`, `tests/vfx/cel_fire_mc.gd` | Chamas soltas (sementes, tamanhos, fades, rotações) e um **rastro conduzido pelo Composer** (M03 + M24, nasce M17, apaga M18) com brasas (M16 + M22 + M23) e o flipbook. Fundo escuro e claro. |

**Verificado:** renderização em GL Compatibility, fundo escuro e claro; as 4 suítes V1.1/V1.2 seguem sem falhas. **Não verificado:** semelhança com Persona/Genshin/Pokémon (as imagens de referência não foram fornecidas; é uma interpretação), desempenho, uso dentro do Flame Stream na batalha real, a aprovação artística.

## 28. V1.4 — fogo como efeito: campo de calor, faíscas com rastro, fuligem (D-332, 2026-11-05)

O criador reprovou as chamas "todas iguais" (seção 27) e pediu um fogo que **não seja modelo**, "fogo real, com faísca, com rastro, com alta disparidade de opacidade, visual flat decente, mistura de laranja, vermelho, amarelo, cores queimadas e preto".

| Peça | Arquivo | O que faz |
|---|---|---|
| Shader `mc_fire_flow` | `shaders/mc_fire_flow.gdshader` | Campo de calor **turbulento que sobe** (ruído fractal levado para cima), cortado em **degraus chapados**: amarelo, laranja, vermelho, vermelho queimado e **preto de fuligem**. A borda se rompe em lambidas soltas; a **opacidade varia muito** (núcleo sólido, periferia translúcida). Cada instância tem semente, velocidade e largura próprias. Base arredondada. Tempo explícito. |
| Rastro de movimento | `MotionEffect` (opção `trail_dt`) + representação `spark` (`trail`, `trail_gain`) | Cada amostra recebe `prev` = onde estava `trail_dt` s antes (reavaliação determinística do compositor, sem estado): a faísca vira um **risco** do ponto anterior ao atual. |
| Representação `fire_flow` | `motion_rep.gd`, `motion_painter.gd` (`fire_flow`) | Uma língua de fogo por amostra, com variação de largura, tamanho e velocidade. |
| Demonstração | `tests/vfx/fire_real.gd` (`--video` grava 3 s) | Corpo (6 línguas, M03 + M24), fuligem (M16 + M24, `puff` escuro), faíscas com rastro (M16 + M22 + M24), halo. Fundo escuro e claro. |

**Verificado:** renderização em GL Compatibility, fundo escuro e claro, três instantes e um vídeo de 3 s. **Não verificado:** faíscas em fundo claro (mistura aditiva: ficam brancas), desempenho, ligação ao Flame Stream na batalha real, e a aprovação artística.

## 29. V1.5 — cada chama diferente: ciclo de vida por chama (D-332, 2026-11-05)

O criador reprovou as chamas "todas iguais" e mandou **pesquisar tutoriais**. O que se aprendeu e onde entrou:

| Lição (fonte) | Onde entrou |
|---|---|
| Fogo sobe; base grossa e pontas finas; comece pela **curva em S** (rumo do vento) e varie a força das rajadas ([vfxapprentice](https://www.vfxapprentice.com/blog/how-to-draw-stylized-fire-flames)) | `mc_flame_one`: linha central com S + gancho na ponta, largura que afina; balanço por chama |
| **Cortes em C** no contorno e ganchos nas pontas evitam a chama virar "pasta de dente"; misture tamanhos (vfxapprentice) | 1 a 3 mordidas em C por chama, de tamanho, lado e altura sorteados |
| **Tempo quantizado** imita flipbook desenhado à mão ([Mirza Beig, 80.lv](https://80.lv/articles/check-out-this-fully-procedural-stylized-fire-vfx-made-with-shaders/)) | cada chama anima a 7–13 quadros/s (valor próprio) |
| Partículas procedurais com **ciclo 0–1 por partícula**, semente nova a cada ciclo, cor misturada pela **idade** e brilho que cai com ela ([godotshaders: tocha/vela](https://godotshaders.com/?p=13210)) | `flame_life`: idade e semente saem do relógio e do id, sem estado; a cor depende da idade (amarelo → laranja → vermelho → queimado → preto) |
| Rasgar o fogo em línguas: erosão de opacidade, distorção, flowmaps e muito timing manual ([realtimevfx, FFXVI](https://realtimevfx.com/t/final-fantasy-xvi-how-to-get-fire-to-tear-apart/27700)) | erosão pela idade e pelas mordidas em C |
| Faixas por `step` entre ruído e gradiente ([godotshaders, fogo 2D](https://godotshaders.com/shader/best-2d-fire/)) | degraus chapados de cor no calor |

| Peça | Arquivo |
|---|---|
| Shader de UMA chama com vida | `shaders/mc_flame_one.gdshader` (forma, balanço, FPS, mordidas, ganchos e velocidade sorteados pela semente) |
| Pincel e representação `flame_life` | `motion_painter.gd` (`flame_one`), `motion_rep.gd` |
| Demonstração e vídeo | `tests/vfx/fire_real.gd` (`--video`), `test_captures/fogo_efeito_v2.mp4` |

**Não verificado:** o fogo ainda tem uma lacuna entre o corpo de baixo e as línguas de cima; faíscas em fundo claro; desempenho; uso no Flame Stream; aprovação artística.

## 30. V1.6 — fogo do Flame Stream: cada chama é uma composição do Composer, no preset e na batalha real (D-332, 2026-11-05)

O criador reclamou que as chamas seguiam iguais e que eu **não usava o Composer** (a forma e o movimento estavam sorteados dentro de um shader meu; o efeito vivia em scripts de teste, não no preset). Correção:

| Peça | Onde | O que faz |
|---|---|---|
| **Ciclo de vida por camada** | `MotionEffect` (opções `factory`, `loop`, `cycle_phase`, `once`, `offset_fn`, `rot_fn`, `dir`, `length: "keep"`) | Uma camada pode repetir um ciclo construindo **uma composição nova a cada ciclo** (semente, altura, vida, posição e inclinação próprias). |
| **Uma chama = uma composição** | `MotionPresets.flame_comp` | M03 (curva em S), M09 (inclinação), M24 (fluxo orgânico), M12 (inchaço que viaja, "respirar"), M17 (nasce), M18 (morre pela ponta), todos com parâmetros sorteados. |
| **Fogo do Flame Stream** | `MotionPresets.fire_effect` (usado por `ElementMoveVfx`) | Carga: 9 chamas + faíscas com rastro. Voo: 8 chamas na cabeça e 10 de rastro apontando para trás, 3 vórtices (D-308: 0,2 s + 0,5 s), faíscas, fumaça. Impacto: cone de 9 chamas, 4 chamas subindo, faíscas, fuligem, marca no chão. |
| **Material** | `shaders/mc_fire_ribbon.gdshader` + `MotionRep` (`shape: "flame"`, `shader`) | Só pinta a fita que o Composer desenha: degraus chapados, preto de fuligem, opacidade variável, mordidas em C e FPS próprio por chama. |

**Verificado:** batalha real (`vfx_room`), vista normal e espelhada, quadros 1280x720 nos instantes de carga, voo e impacto; vídeo `test_captures/flame_stream_v3.mp4`; sem erro de script. **Não verificado:** desempenho, outros atacantes/alvos, o checklist da D-308 item a item (cone no impacto nos dois lados, vórtices), a aprovação artística. **Fraco:** com tamanho fixo em metros, o impacto na vista normal (alvo a ~37 m) quase não aparece; na espelhada o corpo do alvo tapa parte do cone.

## 31. V1.7 — Splitter Flames do atelier.html no Godot (D-335, 2026-11-05)

Portado do `prototypes/vfx_atelier` (Splitter Flames) mantendo o visual e melhorando com shaders do Godot (fbm no lugar de simplex, cel-shading opcional, tempo explícito). Tudo sobre o Composer: `MotionPresets.splitter_effect`, escolhido por `MotionPresets.effect_for(move_id)`.

| Peça | Arquivo |
|---|---|
| Bola de fogo (esfera com seno no vértice, cor por fresnel) | `shaders/mc_fireball.gdshader`, representação `fireball` |
| Vórtice do release (espiral achatada, parada na mão, 0,30 s) | `shaders/mc_vortex_disc.gdshader`, representação `vortex_disc` |
| Pilar de fogo do impacto (cilindro aberto, vira cinza) | `shaders/mc_pillar.gdshader`, representação `pillar` |
| Dois punhos, arco para cada lado, chão | `MotionEffect`: `local_offset`, `side_start` / `arc_rel` / `arc_up`, `ground`; itens com `lt` |
| Laboratório de um Move de elemento | `tests/vfx/effect_lab.gd` (4 fases, 2 câmeras, fora da batalha) |

**Verificado:** batalha real, vista normal e espelhada (`test_captures/splitter_flames_v1.mp4`). **Não verificado:** dois alvos e redirecionamento, desempenho, aprovação artística.

## 32. V1.9 — flipbook dirigido pela idade do M26 e preset do Heal Gain (D-343, 2026-11-06)

Pedido do criador: aplicar no jogo a **opção 2 (Persona Kinetic Cross)** do protótipo de Heal Gain, com **cruzes verdes subindo brilhando junto**, usando o flipbook do Godot e o Motion Composer.

| Peça | Arquivo | O que faz |
|---|---|---|
| `MotionRep.progress_source` | `scripts/motion_composer/representations/motion_rep.gd` | O flipbook pode escolher o quadro por `intensity` (a idade normalizada que o M26 grava em cada amostra) em vez de `1 - opacity` ou `u`. Assim a cruz anima do nascimento à morte mesmo com a curva de alfa do emissor. Vazio = comportamento antigo, sem alterar os efeitos existentes. |
| Flipbook `heal_cross` | `assets/vfx/flipbook_heal_cross.png` | 16 quadros (4×4, 256 px) de uma cruz verde (`#78F0A4` no corpo, `#B7FFC9` no núcleo), halo `#53E28B` e faíscas brancas; reproduzível por `tests/vfx/bake_heal_cross.gd`. |
| Preset `heal_gain_effect` | `scripts/motion_composer/runtime/motion_presets.gd` | Uma camada M26 (anel de 12 amostras, subida, órbita, arrasto e atraso) pintada pela representação `flipbook` com `progress_source: "intensity"`. A origem é o âncora real do número de cura, passado a cada quadro; a escala vem da distância da câmera (referência 4 m, limites 0,5–2,2) para o anel e as cruzes lerem igual nas duas vistas; nenhum personagem/time/lado (D-235). |
| Reprodução | `scripts/vfx/combat/heal_gain_fx.gd` | Entrega ao `MotionEffect` o relógio explícito, o âncora atual (que sobe com o número) e a escala de câmera; não desenha nada por conta própria. |
| Número `+HP` | `scripts/vfx/combat/heal_gain_mark.gd` | A opção 2 é desenhada num `SubViewport` e exibida numa `CanvasLayer` 2D abaixo do HUD, projetando o alvo real. As cores do HTML ficam exatas (sem o tonemap Filmic do quad 3D) e o número continua com tamanho fixo na tela. |
| Verificação isolada | `tests/vfx/heal_gain_lab.gd`, `tests/vfx/probe_heal_gain.gd` | Laboratório de aparência e sonda determinística das amostras do M26. |

**D-347 (2026-11-06):** o **número** passou a aparecer acima do `UnitCard`/`EnemyTag` (fora da ficha, perto do HP), com rotação de ±6° e deslocamento diagonal para cima na direção do lado (inimigo à direita, aliado à esquerda), em 1,4 s. As **cruzes continuam no personagem** como VFX 3D do M26. O odômetro de HP foi arquivado e o HP/barra são imediatos.

**Verificado:** batalha real (`vfx_room`) nas duas vistas, 1280×720: o número com as cores exatas acima das fichas e as cruzes verdes no personagem, o lado direito do HUD fica limpo e tudo some ao fim. Vídeo: `test_captures/HealGain_option2_normal_espelhado.mp4` e teste do inimigo em `test_captures/HealGain_enemy_tag.mp4`. **Não verificado:** desempenho em hardware fraco, aprovação artística do criador.

## V1.12 (D-1026, 2026-11-09): `floor_ring` e cores do anel

O Armored Bulk precisa de um anel de choque **prateado e contínuo** no chão que **abre e some**. O `ring` já existente usa o shader `fire_ring` (tracejado laranja/vermelho) e, com `expand`, apaga ao contrário (visível só no fim); ele continua **intocado** para os presets que já o usam.

| Mudança | Onde | Efeito |
|---|---|---|
| rep `floor_ring` | `motion_rep.gd` | anel no chão sob a origem; `k` de 0 a 1 abre o raio (de 12% a 100% de `size`) e **apaga** (fade = `k`); as cores e a espessura vêm de `look` |
| `MotionPainter.ring(..., params)` | `motion_painter.gd` | parâmetro opcional de `look` (`orange`, `red`, `solid`, `dashes`, `thick`); vazio = visual antigo |
| uniform `solid` | `shaders/fire_ring.gdshader` | 1 = linha contínua; 0 (padrão) = tracejado antigo |

Uso: `MotionRep.make("floor_ring", {"size": 3.0, "strength": 1.1, "look": {"orange": prata, "red": aço, "solid": 1.0, "thick": 0.05}})`. Tudo em metros do mundo; o nó que desenha escala pelo corpo real (D-235). Preset: `MotionPresets.armored_bulk_effect` e `armor_break_effect`.


## V1.13 (D-1026, 2026-11-09): rep `plate`

Placas triangulares cromadas que giram e se dissolvem (a perda da ARMOR). Cada amostra do compositor vira uma placa de borda reta em um quad (`shaders/mc_plate.gdshader`), sombreada pelo mesmo reflexo de estúdio do filme da ARMOR, girando em eixo e ritmo próprios (`spin`).

| Mudança | Onde | Efeito |
|---|---|---|
| rep `plate` | `motion_rep.gd` | `size` (m) x largura da amostra; gira com `spin` (rad/s); dissolve com a opacidade da composição |
| `MotionPainter.plate(pos, size, rot, fade, seed)` | `motion_painter.gd` | um nó por placa (pincel `plate`) |
| shader `mc_plate` | `shaders/mc_plate.gdshader` | triângulo por descarte, reflexo cromado, borda clara |

Uso: `MotionRep.make("plate", {"size": 0.7, "spin": 6.0})`. Preset: `MotionPresets.armor_break_effect`.
