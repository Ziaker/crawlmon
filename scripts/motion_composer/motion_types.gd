class_name MotionTypes
extends RefCounted
## Motion Composer V1 — enums compartilhados (spec §4.4, §5.2, §5.3). Sem dependências.

## Tipos de comportamento (§4.4).
enum Kind { GENERATOR, MODIFIER, FIELD, TOPOLOGY, ENVELOPE, HISTORICAL }

## Operações de combinação (§5.2). O que cada uma pode alterar:
## - REPLACE: todos os campos da amostra, interpolados pelo peso.
## - OFFSET: a posição de saída do comportamento é um DESLOCAMENTO somado à posição anterior.
## - DEFORM: só geometria (posição e base); atributos são preservados.
## - MULTIPLY_ATTRIBUTE: a saída (largura/intensidade/opacidade) é um multiplicador dos atributos.
## - MASK: só a visibilidade.
## - BRANCH / MERGE: topologia; substituem as amostras selecionadas (exigem Kind.TOPOLOGY).
## - PERSIST: acrescenta amostras históricas ao fluxo (exige Kind.HISTORICAL).
enum Op { REPLACE, OFFSET, DEFORM, MULTIPLY_ATTRIBUTE, MASK, BRANCH, MERGE, PERSIST }

## Espaços de coordenadas (§5.3). Troca de espaço é sempre explícita, por camada.
enum Space { LOCAL, GLOBAL, EMITTER, TRAJECTORY }

enum Severity { INFO, WARNING, ERROR }
