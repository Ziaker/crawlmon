extends MoveBehavior
## Fixture da Etapa 6 (D-1079): prova que `MoveData.behavior_script` é
## instanciado pelo registry sem uma entrada fixa em
## `MoveBehaviorRegistry.BEHAVIORS`. Não tem class_name para não poluir o cache
## global de classes do projeto.

var used_by_contract := true
