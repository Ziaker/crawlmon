# Mabufula — direção visual da primeira proposta D-1191

Direção aprovada pelo criador; implementação delegada ao DeepSeek em 2026-11-12. Este documento orienta a aparência e a revisão, sem modificar regras de combate.

## Checklist literal

| Frase do criador | O que a implementação deve apresentar | Prova necessária |
| --- | --- | --- |
| “No jogo Godot” | Efeito ligado ao `move_id=mabufula` na batalha real | Trace e vídeo da sala de combate |
| “Cristal translúcido, veios internos e brilho nas arestas” | Faces de gelo translúcidas, veios em camadas e luz concentrada nas quinas | Shader, parâmetros e vídeo para julgamento do criador |
| “dust de gelo com baixa opacidade” | Poeira suave de gelo que deixa os personagens legíveis | Limites de alfa, envelopes e teste de sobreposição |
| “Nos dois: névoa baixa e pequenas nuvens nas geleiras” | Camada rente ao chão e nuvens localizadas no nascimento/ruptura das geleiras | Contagens/âncoras de cada camada e vídeo |
| “deixe a parte do codigo pro deepseek e a parte do visual pra vc” | DeepSeek produz o código; agente principal dirige e revisa a aparência | Diff e relatório do executor |

## Composição

O gelo é o foco. Faces largas em azul frio ficam transparentes; veios claros sugerem profundidade e fraturas internas. As arestas recebem o brilho mais forte, estreito, sem transformar o conjunto numa massa branca. A névoa permanece secundária, baixa e aberta; as nuvens são pequenas e ligadas às bases das geleiras.

Calibração inicial, ainda sujeita à aprovação visual: alfa máximo por sprite de névoa 0,12 e de nuvem 0,16. Isso não prova a transparência do conjunto: a sobreposição também precisa ser medida. Os shaders usam mistura por alfa e o relógio fornecido pelo combate.

## Fases e continuidade

1. **Wind-up:** o frio se concentra junto ao lançador, com gelo no chão e neve. Crescimento gradual pelo progresso real do wind-up.
2. **Release:** a carga permanece visível e passa a alimentar a nevasca. Nada desaparece entre a preparação e a saída.
3. **Trajeto:** neve conduz o movimento até a área dos alvos. Cinco grupos de cinco geleiras crescem em sequência, com subida elástica e vibração antes da ruptura, conforme D-337.
4. **Impacto:** o contato real dispara a ruptura simultânea, 240 estilhaços e pequenas nuvens. Cacos quicam e todas as camadas se dissipam; o visual não calcula dano nem altera o momento do acerto.

A referência HTML também tem 120 flocos e 42 cacos de nascimento por grupo. Posições fixas, nomes de personagem, dano e temporizadores do HTML não são transportados para o jogo. Eixos, chão e escala vêm dos participantes reais; D-1033 prevalece sobre a escala fixa histórica.

## Verificação e limites

- Normal e espelhado, outro atacante e alvos de tamanhos diferentes (D-235).
- Compilação e desenho com GL Compatibility; ausência de projétil/impacto genérico duplicado.
- Pausa, interrupção, limpeza e envelopes; `--stdout-trace`, `--summary-json`, `--strict-asserts` e ferramentas de `docs/DEBUG_COMBATE.md`.
- Baseline já aponta `SCALE_POP` antes do Move e quatro nós no auditor. Esses resultados não são aprovação nem motivo para mudar regras/testes nesta tarefa.
- Um vídeo com as duas vistas. Conforme o protocolo atual, o agente principal não abre quadros em tamanho real nem o vídeo. Dados podem provar contagens, alfa e duração; beleza, transparência percebida e legibilidade fina dependem da avaliação do criador.

Estado: aguardando implementação completa e evidências do executor. Nenhum resultado visual final aprovado.
