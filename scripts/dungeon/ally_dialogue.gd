class_name AllyDialogue
extends RefCounted
## D-1089: reações curtas de aliados por Nature (flavor, sem efeito de gameplay).
## Cada Nature tem 2 falas; o lab escolhe uma pelo índice do NPC.
## O Orc usa o tom "orc" por não ter uma Nature canônica.

const REACTIONS: Dictionary = {
	"hardy": [
		"Se o caminho é perigoso, melhor ir preparado.",
		"Não vou recuar por causa de monstros.",
	],
	"docile": [
		"Vamos com calma... mas eu vou junto.",
		"Prefiro evitar briga, mas não vou te deixar sozinho.",
	],
	"brave": [
		"Então que venham. Se atacarem, devolvemos em dobro!",
		"Tesouro raro? Eu abro caminho.",
	],
	"timid": [
		"Isso não me deixa nem um pouco tranquilo...",
		"Talvez a gente devesse voltar... só um pouco.",
	],
	"modest": [
		"Tesouros raros justificam o risco? Espero que sim.",
		"Vou ficar atrás de você, se não se importar.",
	],
	"calm": [
		"Ouvi dizer que pressa é o primeiro passo para a ruína.",
		"Vamos observar antes de entrar.",
	],
	"jolly": [
		"Masmorras, monstros e tesouros? Isso vai ser divertido!",
		"Se aparecer algo, eu dou um jeito!",
	],
	"adamant": [
		"Chega de conversa. Vamos entrar e resolver.",
		"Nenhum monstro vai me impedir.",
	],
	"orc": [
		"Eu esmago qualquer coisa que aparecer na frente.",
		"Se querem lutar, eu dou a eles o que pediram.",
	],
}


static func get_line(nature: String, index: int) -> String:
	var lines: Array = REACTIONS.get(nature.to_lower(), REACTIONS["hardy"])
	return str(lines[index % lines.size()])
