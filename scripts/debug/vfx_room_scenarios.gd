class_name VfxRoomScenarios
extends RefCounted
## Cenários prontos da sala de VFX (D-1042). Extraído de vfx_room.gd na Etapa 4;
## a sala continua lendo a mesma lista, sem mudar nenhum cenário.

## Cenários prontos. Papéis, nunca nomes (D-235): A1/A2 = aliados, E1/E2/E3 = inimigos, "#n" = unidade n da lista.
## "atk": [atacante, Move, alvo, segundos até disparar]; os dois primeiros aparecem nos campos da aba Cenário.
## "acts": [segundos, ação, quem, ...]: evade, evade_once, guard, step(±1), buff(stat, ±n), status(burn|stun|blind), kill, attack(Move, alvo).
## "enemies": 3 = acrescenta os 2 inimigos extras. "hp": % da vida de todos. "pos": {papel: ["between", a, b, fração]}.
const SCENARIOS := [
	# --- Choque (D-279) ---
	{"id": "choque", "g": "Choque", "label": "Frente a frente (Tackle × Tackle)", "atk": [["A1", "Tackle", "E1", 0.0], ["E1", "Tackle", "A1", 0.0]]},
	{"id": "choque_atraso", "g": "Choque", "label": "Defasado em 0,5 s", "atk": [["A1", "Tackle", "E1", 0.0], ["E1", "Tackle", "A1", 0.5]]},
	{"id": "choque_mach", "g": "Choque", "label": "Mach Punch (rápido) × Tackle (lento)", "atk": [["E1", "Tackle", "A1", 0.0], ["A1", "Mach Punch", "E1", 1.5]]},
	{"id": "choque_brick", "g": "Choque", "label": "Brick Break × Tackle", "atk": [["A1", "Brick Break", "E1", 0.0], ["E1", "Tackle", "A1", 0.0]]},
	{"id": "cruzamento", "g": "Choque", "label": "Cruzamento (alvos distintos): cancelam", "atk": [["A1", "Tackle", "E1", 0.0], ["E1", "Tackle", "A2", 0.0]]},
	{"id": "choque_2x2", "g": "Choque", "label": "Dois contra dois (4 corredores)", "enemies": 3, "atk": [["A1", "Tackle", "E1", 0.0], ["A2", "Tackle", "E2", 0.0], ["E1", "Tackle", "A1", 0.0], ["E2", "Tackle", "A2", 0.0]]},
	{"id": "choque_3", "g": "Choque", "label": "Três corredores no mesmo ponto", "enemies": 3, "atk": [["A1", "Tackle", "E1", 0.0], ["E1", "Tackle", "A1", 0.0], ["E2", "Tackle", "A1", 0.3]]},
	{"id": "aliados_mesmo_alvo", "g": "Choque", "label": "Aliados no mesmo alvo (não se chocam)", "atk": [["A1", "Tackle", "E1", 0.0], ["A2", "Tackle", "E1", 0.0]]},
	{"id": "choque_letal", "g": "Choque", "label": "Choque com vida 1% (quem morre?)", "hp": 1, "atk": [["A1", "Tackle", "E1", 0.0], ["E1", "Tackle", "A1", 0.0]]},
	# --- Perseguição e prisão (D-044, D-054, D-282) ---
	{"id": "persegue", "g": "Perseguição e prisão", "label": "Alvo correndo em outro", "atk": [["E1", "Tackle", "A2", 0.0], ["A1", "Tackle", "E1", 0.7]]},
	{"id": "preso_evade", "g": "Perseguição e prisão", "label": "Preso desvia (Evade)", "atk": [["E1", "Tackle", "A2", 0.0], ["A1", "Tackle", "E1", 0.7]], "acts": [[0.0, "evade", "E1"]]},
	{"id": "preso_guard", "g": "Perseguição e prisão", "label": "Preso abre Guard", "atk": [["E1", "Tackle", "A2", 0.0], ["A1", "Tackle", "E1", 0.7]], "acts": [[3.4, "guard", "E1"]]},
	{"id": "alvo_ja_voltou", "g": "Perseguição e prisão", "label": "Alvo já voltou para casa (corrida longa)", "atk": [["E1", "Tackle", "A2", 0.0], ["A1", "Tackle", "E1", 2.4]]},
	# --- Interrupção ---
	{"id": "mach_interrompe_windup", "g": "Interrupção", "label": "Mach Punch interrompe o wind-up", "atk": [["E1", "Tackle", "A1", 0.0], ["A1", "Mach Punch", "E1", 0.3]]},
	{"id": "tiro_interrompe_corrida", "g": "Interrupção", "label": "Tiro interrompe a corrida", "atk": [["E1", "Tackle", "A1", 0.0], ["A2", "Fire Bullet", "E1", 1.0]]},
	{"id": "tiro_interrompe_golpe", "g": "Interrupção", "label": "Tiro interrompe o golpe", "atk": [["E1", "Tackle", "A1", 0.0], ["A2", "Fire Bullet", "E1", 2.0]]},
	{"id": "alvo_empurrado", "g": "Perseguição e prisão", "label": "Alvo empurrado por um tiro durante o golpe (D-286)", "atk": [["A1", "Tackle", "E1", 0.0], ["A2", "Fire Bullet", "E1", 1.9]]},
	{"id": "alvo_empurrado_tarde", "g": "Perseguição e prisão", "label": "Alvo empurrado logo antes do impacto", "atk": [["A1", "Tackle", "E1", 0.0], ["A2", "Fire Bullet", "E1", 2.4]]},
	# --- Evade e contra-ataque (D-283, D-284) ---
	{"id": "evade_janela", "g": "Evade", "label": "Evade na janela final (0,25 s)", "atk": [["A1", "Tackle", "E1", 0.0]], "acts": [[0.0, "evade", "E1"]]},
	{"id": "evade_cedo", "g": "Evade", "label": "Evade cedo demais: sem efeito", "atk": [["A1", "Tackle", "E1", 0.0]], "acts": [[2.7, "evade_once", "E1"]]},
	{"id": "evade_contra", "g": "Evade", "label": "Evade + contra-ataque (wind-up 0,3 s)", "atk": [["A1", "Tackle", "E1", 0.0]], "acts": [[0.0, "evade", "E1"], [3.55, "attack", "E1", "Tackle", "A1"]]},
	{"id": "evade_projetil", "g": "Evade", "label": "Evade de projétil", "atk": [["A1", "Fire Bullet", "E1", 0.0]], "acts": [[0.0, "evade", "E1"]]},
	{"id": "evade_na_corrida", "g": "Evade", "label": "Evade durante a própria corrida", "atk": [["E1", "Tackle", "A2", 0.0], ["A1", "Fire Bullet", "E1", 1.1]], "acts": [[0.0, "evade", "E1"]]},
	# --- Guard (D-272) ---
	{"id": "guard_alvo", "g": "Guard", "label": "Alvo em Guard contra Tackle", "atk": [["A1", "Tackle", "E1", 0.0]], "acts": [[1.6, "guard", "E1"]]},
	{"id": "brick_quebra_guard", "g": "Guard", "label": "Brick Break quebra o Guard", "atk": [["A1", "Brick Break", "E1", 0.0]], "acts": [[1.7, "guard", "E1"]]},
	{"id": "guard_projetil", "g": "Guard", "label": "Alvo em Guard contra projétil", "atk": [["A1", "Fire Bullet", "E1", 0.0]], "acts": [[0.5, "guard", "E1"]]},
	# --- Armor (D-1026) ---
	{"id": "armor_perde", "g": "Armor", "label": "ARMOR perdida no primeiro golpe", "atk": [["E1", "Armored Bulk", "E1", 0.0], ["A1", "Tackle", "E1", 2.2]]},
	# --- Projéteis ---
	{"id": "fire_bullet", "g": "Projéteis", "label": "Fire Bullet simples", "atk": [["A1", "Fire Bullet", "E1", 0.0]]},
	{"id": "projeteis_cruzam", "g": "Projéteis", "label": "Dois projéteis se cruzam", "atk": [["A1", "Fire Bullet", "E1", 0.0], ["E1", "Fire Bullet", "A1", 0.0]]},
	{"id": "projetil_alvo_morre", "g": "Projéteis", "label": "Alvo morre com o projétil no ar", "enemies": 3, "atk": [["A1", "Fire Bullet", "E1", 0.0]], "acts": [[0.9, "kill", "E1"]]},
	{"id": "lancador_morre", "g": "Projéteis", "label": "Lançador morre com o projétil no ar", "enemies": 3, "atk": [["E1", "Fire Bullet", "A1", 0.0]], "acts": [[0.8, "kill", "E1"]]},
	{"id": "intercepta", "g": "Projéteis", "label": "Outro inimigo intercepta o projétil", "enemies": 3, "atk": [["A1", "Fire Bullet", "E1", 0.0]], "pos": {"E2": ["between", "A1", "E1", 0.5]}},
	{"id": "dragon_rage", "g": "Projéteis", "label": "Dragon Rage", "atk": [["A1", "Dragon Rage", "E1", 0.0]]},
	{"id": "sand_attack", "g": "Projéteis", "label": "Sand Attack (cegueira)", "atk": [["A1", "Sand Attack", "E1", 0.0]]},
	# --- Área ---
	{"id": "megido", "g": "Área", "label": "Megido (onda nos 3 inimigos)", "enemies": 3, "atk": [["A1", "Megido", "E1", 0.0]]},
	{"id": "mabufula", "g": "Área", "label": "Mabufula (onda)", "enemies": 3, "atk": [["A1", "Mabufula", "E1", 0.0]]},
	{"id": "hassou_tobi", "g": "Área", "label": "Hassou Tobi (corpo a corpo em área)", "enemies": 3, "atk": [["A1", "Hassou Tobi", "E1", 0.0]]},
	{"id": "titanomachia", "g": "Área", "label": "Titanomachia (corpo a corpo em área)", "enemies": 3, "atk": [["A1", "Titanomachia", "E1", 0.0]]},
	{"id": "aoe_evade", "g": "Área", "label": "Megido com um alvo desviando", "enemies": 3, "atk": [["A1", "Megido", "E1", 0.0]], "acts": [[0.0, "evade", "E2"]]},
	# --- Status e buffs ---
	# D-1019: Drain Spear stealing ATK +1 and DEF +1 (shows the Badge Steal reverse pulse).
	{"id": "ds_steal", "g": "Status", "label": "Drain Spear rouba ATK+1/DEF+1", "atk": [["A1", "Drain Spear", "E1", 0.3]], "acts": [[0.0, "buff", "E1", "atk", 1], [0.0, "buff", "E1", "def", 1]]},
	{"id": "ds_steal_m", "g": "Status", "label": "Drain Spear (inimigo) rouba ATK+1/DEF+1", "atk": [["E1", "Drain Spear", "A1", 0.3]], "acts": [[0.0, "buff", "A1", "atk", 1], [0.0, "buff", "A1", "def", 1]]},
	# D-980: status effects on one or more characters (STUN, Burn, Blind, buffs/debuffs).
	{"id": "st_stun_inimigo", "g": "Status", "label": "STUN 4 s no inimigo (e um Tackle nele)", "atk": [["A1", "Tackle", "E1", 1.0]], "acts": [[0.0, "status", "E1", "stun4"]]},
	{"id": "st_stun_aliado", "g": "Status", "label": "STUN 4 s no aliado (inimigo ataca)", "atk": [["E1", "Tackle", "A1", 1.0]], "acts": [[0.0, "status", "A1", "stun4"]]},
	{"id": "st_stun_todos", "g": "Status", "label": "STUN 4 s em todos", "enemies": 2, "atk": [["A1", "Tackle", "E1", 4.5]], "acts": [[0.0, "status", "A1", "stun4"], [0.0, "status", "A2", "stun4"], [0.0, "status", "E1", "stun4"], [0.0, "status", "E2", "stun4"]]},
	{"id": "st_burn", "g": "Status", "label": "Burn no inimigo e no aliado", "atk": [["A1", "Tackle", "E1", 1.0]], "acts": [[0.0, "status", "E1", "burn"], [0.0, "status", "A2", "burn"]]},
	{"id": "st_blind", "g": "Status", "label": "Blind no aliado que ataca", "atk": [["A1", "Tackle", "E1", 0.5]], "acts": [[0.0, "status", "A1", "blind"]]},
	{"id": "st_stun_burn", "g": "Status", "label": "STUN + Burn juntos no inimigo", "atk": [["A1", "Tackle", "E1", 1.0]], "acts": [[0.0, "status", "E1", "stun4"], [0.0, "status", "E1", "burn"]]},
	{"id": "st_buffs", "g": "Status", "label": "Buffs/debuffs em vários (ATK+1, DEF−1, SPD−1)", "atk": [["A1", "Tackle", "E1", 1.0]], "acts": [[0.0, "buff", "A1", "atk", 1], [0.0, "buff", "E1", "def", -1], [0.0, "buff", "A2", "speed", -1]]},
	{"id": "tarukaja", "g": "Status e buffs", "label": "Tarukaja (buff de ataque em si)", "atk": [["A1", "Tarukaja", "A1", 0.0]]},
	{"id": "rakunda", "g": "Status e buffs", "label": "Rakunda no inimigo", "atk": [["A1", "Rakunda", "E1", 0.0]]},
	{"id": "sukunda", "g": "Status e buffs", "label": "Sukunda no inimigo", "atk": [["A1", "Sukunda", "E1", 0.0]]},
	{"id": "media", "g": "Status e buffs", "label": "Media (grupo)", "hp": 55, "atk": [["A1", "Media", "A1", 0.0]]},
	{"id": "taunt", "g": "Status e buffs", "label": "Taunt redireciona o ataque", "enemies": 3, "atk": [["A1", "Taunt", "E1", 0.0], ["E1", "Tackle", "A2", 3.2]]},
	{"id": "status_pausa", "g": "Status e buffs", "label": "Status pausa um ataque em curso", "atk": [["E1", "Tackle", "A1", 0.0], ["A1", "Tarukaja", "A1", 0.5]]},
	{"id": "buff_atk", "g": "Status e buffs", "label": "ATK +3 e depois Tackle", "atk": [["A1", "Tackle", "E1", 1.0]], "acts": [[0.0, "buff", "A1", "atk", 3]]},
	{"id": "debuff_def", "g": "Status e buffs", "label": "DEF −3 no alvo e depois Tackle", "atk": [["A1", "Tackle", "E1", 1.0]], "acts": [[0.0, "buff", "E1", "def", -3]]},
	# --- Morte e fim de combate ---
	{"id": "vitoria", "g": "Morte e fim", "label": "Último inimigo morre: vitória", "hp": 1, "atk": [["A1", "Tackle", "E1", 0.0]]},
	{"id": "ko_lancamento", "g": "Morte e fim", "label": "KO com inimigos restantes (lançamento)", "hp": 1, "enemies": 3, "atk": [["A1", "Tackle", "E1", 0.0]]},
	{"id": "derrota", "g": "Morte e fim", "label": "Aliados morrem: derrota", "hp": 1, "enemies": 3, "atk": [["E1", "Tackle", "A1", 0.0], ["E2", "Tackle", "A2", 0.0]]},
	{"id": "morre_windup", "g": "Morte e fim", "label": "Alvo morre no wind-up (D-108)", "enemies": 3, "atk": [["A1", "Tackle", "E1", 0.0]], "acts": [[0.5, "kill", "E1"]]},
	{"id": "morre_corrida", "g": "Morte e fim", "label": "Alvo morre na corrida (D-113)", "enemies": 3, "atk": [["A1", "Tackle", "E1", 0.0]], "acts": [[1.9, "kill", "E1"]]},
	{"id": "morre_strike", "g": "Morte e fim", "label": "Alvo morre no golpe", "enemies": 3, "atk": [["A1", "Tackle", "E1", 0.0]], "acts": [[2.8, "kill", "E1"]]},
	{"id": "atacante_morre", "g": "Morte e fim", "label": "Atacante morre na corrida", "enemies": 3, "atk": [["A1", "Tackle", "E1", 0.0]], "acts": [[1.9, "kill", "A1"]]},
	{"id": "burn_mata", "g": "Morte e fim", "label": "Burn mata o alvo", "hp": 4, "enemies": 3, "atk": [["A1", "Fire Bullet", "E1", 0.0]]},
	# --- Posição e distância ---
	{"id": "passo_frente", "g": "Posição", "label": "Dois passos à frente e depois Tackle", "atk": [["A1", "Tackle", "E1", 1.6]], "acts": [[0.0, "step", "A1", 1], [0.6, "step", "A1", 1]]},
	{"id": "passo_atras_alvo", "g": "Posição", "label": "Alvo dá um passo atrás", "atk": [["A1", "Tackle", "E1", 1.2]], "acts": [[0.0, "step", "E1", -1]]},
	{"id": "distancia_curta", "g": "Posição", "label": "Distância curta (14)", "dist": 14.0, "atk": [["A1", "Tackle", "E1", 0.0]]},
	{"id": "distancia_longa", "g": "Posição", "label": "Distância longa (40)", "dist": 40.0, "atk": [["A1", "Tackle", "E1", 0.0]]},
	# --- Especiais ---
	{"id": "teleport", "g": "Especiais", "label": "Teleport", "atk": [["A1", "Teleport", "E1", 0.0]]},
	{"id": "dig", "g": "Especiais", "label": "Dig (invulnerável sob o chão)", "atk": [["A1", "Dig", "E1", 0.0], ["E1", "Fire Bullet", "A1", 0.3]]},
	{"id": "mach_punch", "g": "Especiais", "label": "Mach Punch (0,20 s)", "atk": [["A1", "Mach Punch", "E1", 0.0]]},
	{"id": "karate_chop", "g": "Especiais", "label": "Karate Chop", "atk": [["A1", "Karate Chop", "E1", 0.0]]},
	{"id": "bite", "g": "Especiais", "label": "Bite", "atk": [["A1", "Bite", "E1", 0.0]]},
	# --- Dano e Reação (D-1042) ---
	{"id": "dano_direto", "g": "Dano e Reação", "label": "Dano neutro direto (reação de hit e texto)", "atk": [["A1", "Tackle", "E1", 0.0]], "force": 1},
	{"id": "dano_critico", "g": "Dano e Reação", "label": "Dano crítico (CRIT! + tremor)", "atk": [["A1", "Tackle", "E1", 0.0]], "force": 3},
	{"id": "dano_weak", "g": "Dano e Reação", "label": "Dano de fraqueza elementar (WEAK!)", "atk": [["A1", "Fire Bullet", "E1", 0.0]], "force": 4},
	{"id": "dano_armor", "g": "Dano e Reação", "label": "Dano absorvido por ARMOR (D-1026)", "atk": [["E1", "Armored Bulk", "E1", 0.0], ["A1", "Tackle", "E1", 2.2]]},
	{"id": "dano_stun", "g": "Dano e Reação", "label": "Dano sob STUN (D-980: estrelas na cabeça)", "atk": [["A1", "Tackle", "E1", 1.0]], "acts": [[0.0, "status", "E1", "stun4"]]},
	{"id": "dano_guard", "g": "Dano e Reação", "label": "Dano defendido por Guard (D-272)", "atk": [["A1", "Tackle", "E1", 0.0]], "acts": [[1.6, "guard", "E1"]]},
	{"id": "dano_ko", "g": "Dano e Reação", "label": "Dano fatal com lançamento de K.O. (D-049/D-160)", "hp": 1, "enemies": 3, "atk": [["A1", "Tackle", "E1", 0.0]]},
	# --- Fases de Move (D-1042 / D-308) ---
	{"id": "fase_windup", "g": "Fases de Move", "label": "Fase 1: Wind-up (preparo / carga contínua)", "atk": [["A1", "Tackle", "E1", 0.0]], "pause": "windup", "windup": 2.5},
	{"id": "fase_release", "g": "Fases de Move", "label": "Fase 2: Release (disparo / partida)", "atk": [["A1", "Fire Bullet", "E1", 0.0]], "pause": "release"},
	{"id": "fase_trajeto", "g": "Fases de Move", "label": "Fase 3: Trajeto (voo / corrida)", "atk": [["A1", "Fire Bullet", "E1", 0.0]], "pause": "travel"},
	{"id": "fase_golpe", "g": "Fases de Move", "label": "Fase 3.5: Golpe / Strike (arco e aviso Dread)", "atk": [["A1", "Tackle", "E1", 0.0]], "pause": "strike"},
	{"id": "fase_impacto", "g": "Fases de Move", "label": "Fase 4: Impacto (ponto zero no alvo)", "atk": [["A1", "Tackle", "E1", 0.0]], "pause": "impact"},
	{"id": "fase_retorno", "g": "Fases de Move", "label": "Fase 5: Retorno (recuo à base)", "atk": [["A1", "Tackle", "E1", 0.0]], "pause": "return"},
]
