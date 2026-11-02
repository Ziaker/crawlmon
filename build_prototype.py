import io, base64
from PIL import Image

art = {}
for name in ['pancham', 'abra', 'gible']:
    im = Image.open(f'sugimori/por_nome/{name}.png')
    im.thumbnail((750, 750), Image.Resampling.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, format='WEBP', quality=82, method=6)
    art[name] = 'data:image/webp;base64,' + base64.b64encode(buf.getvalue()).decode('ascii')
    
    im_p = Image.open(f'personagens/portraits/{name}.png')
    buf_p = io.BytesIO()
    im_p.save(buf_p, format='PNG')
    art[name + '_face'] = 'data:image/png;base64,' + base64.b64encode(buf_p.getvalue()).decode('ascii')

html_template = '''<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>CRAWL/MON — Status / Protótipo Visual</title>
<style>
:root{
  --lime:#d6fa66;
  --coral:#ff746c;
  --paper:#f4eee1;
  --dark:#071624;
  --ink:#10263a;
  --blue:#63d9ec;
  --violet:#bd9afd;
  --gold:#f0c57e;
  --glass-bg:linear-gradient(140deg,rgba(8,26,44,0.92),rgba(11,40,54,0.88));
  --glass-border:1px solid rgba(102,138,148,0.45);
}
*{box-sizing:border-box}
html,body{width:100%;height:100%;margin:0;overflow:hidden;background:#06111d;color:var(--paper);font-family:'Roboto Condensed','Arial Narrow','Liberation Sans Narrow',Arial,sans-serif}
button{border:0;cursor:pointer;font:inherit}
button:focus-visible{outline:3px solid var(--lime);outline-offset:2px}
#viewport{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;overflow:hidden;background:#050d17}
#stage{position:absolute;width:1600px;height:900px;transform-origin:center center;overflow:hidden;background:radial-gradient(ellipse at 48% 55%,#26535f 0,#143343 35%,#092133 66%,#051322 100%)}

/* setting & atmosphere */
.ambient{position:absolute;inset:0;pointer-events:none;overflow:hidden}
.ambient:before{content:'';position:absolute;inset:0;background:repeating-linear-gradient(0deg,transparent 0 3px,rgba(255,255,255,0.025) 4px),radial-gradient(ellipse at 51% 100%,rgba(106,185,184,0.12),transparent 60%);opacity:.6}
.ambient:after{content:'';position:absolute;inset:0;background:linear-gradient(90deg,rgba(4,16,27,0.65),transparent 25%,transparent 75%,rgba(4,16,27,0.55));pointer-events:none}
.ruins{position:absolute;inset:0;opacity:.38}
.spire{position:absolute;bottom:78px;width:34px;background:linear-gradient(90deg,#0b2535,#2b5964 38%,#102b3c);height:var(--h);left:var(--x);box-shadow:-14px -10px 28px rgba(5,14,23,0.4)}
.spire:before{content:'';position:absolute;top:-22px;left:-9px;width:50px;height:12px;background:#1c4558;transform:skew(-13deg)}
.spire:after{content:'';position:absolute;top:-49px;left:6px;width:24px;height:28px;background:#0f2837;clip-path:polygon(50% 0,100% 100%,0 100%)}
.lamp{position:absolute;bottom:calc(78px + var(--h) + 29px);left:calc(var(--x) + 13px);width:12px;height:12px;border-radius:50%;background:#f6d78e;box-shadow:0 0 16px rgba(255,228,164,0.55)}
.top-line{position:absolute;top:0;left:0;right:0;height:4px;background:linear-gradient(90deg,var(--lime) 0 25%,var(--coral) 25% 42%,transparent 43%)}

/* header */
.brand{position:absolute;top:22px;left:36px;z-index:5;display:flex;align-items:center;gap:14px}
.logo{font:italic 1000 50px/1 Impact,'Arial Black',sans-serif;letter-spacing:-2px;text-shadow:3px 5px 0 #05101a}
.logo .slash{color:var(--coral)}
.logo .mon{color:var(--lime)}
.page-tag{background:rgba(9,27,43,0.85);border-left:4px solid var(--lime);padding:6px 14px;transform:skew(-10deg);box-shadow:4px 4px 0 #040b13}
.page-tag strong{display:block;transform:skew(10deg);font:italic 900 17px/1 Impact,sans-serif;letter-spacing:2px;color:var(--paper)}
.page-tag span{display:block;transform:skew(10deg);font-size:10px;font-weight:900;letter-spacing:2px;color:var(--gold);margin-top:2px}

.view-picker{position:absolute;z-index:20;right:36px;top:22px;display:flex;gap:8px;align-items:stretch}
.view-picker button{background:rgba(11,31,48,0.92);color:#c1d0d8;border:1px solid #4a687a;padding:0 16px;height:44px;transform:skew(-8deg);font-size:12px;font-weight:900;letter-spacing:1px;transition:.15s}
.view-picker button b{display:inline;font:italic 1000 19px Impact,sans-serif;margin-right:6px}
.view-picker button.on{background:var(--lime);color:#0a1a24;border-color:var(--lime);box-shadow:4px 4px 0 #040e18}
.view-picker button:hover:not(.on){background:#1d394a;color:#fff}

.scene{position:absolute;inset:85px 0 35px;z-index:2}
.head{color:var(--lime);font-size:13px;font-weight:1000;font-style:italic;letter-spacing:2.5px;padding-bottom:6px;border-bottom:2px solid rgba(224,252,98,0.35);margin-bottom:10px;text-transform:uppercase}

/* party roster cards */
.team-col{position:absolute;left:36px;top:24px;width:345px}
.party-list{display:flex;flex-direction:column;gap:11px}
.party-card{position:relative;display:grid;grid-template-columns:56px 1fr;gap:12px;align-items:center;padding:8px 12px 8px 8px;height:82px;background:var(--paper);color:var(--ink);clip-path:polygon(3% 0,100% 0,97% 100%,0 100%);box-shadow:5px 6px 0 rgba(4,13,22,0.65);transition:all .15s ease}
.party-card.active{background:#fdfde8;border-left:8px solid var(--lime);transform:translateX(6px);box-shadow:6px 8px 0 #030a13;filter:drop-shadow(0 0 10px rgba(215,250,102,0.35))}
.party-card:hover:not(.active){filter:brightness(1.04)}

/* CORRIGIDO: Moldura de ícone 100% quadrada e proporcional, sem clip-path angular distorcido e sem zoom excessivo */
.party-card .face{height:56px;width:56px;background:#122535;border:2px solid #234057;border-radius:4px;overflow:hidden;display:flex;align-items:center;justify-content:center;box-shadow:inset 0 0 5px rgba(0,0,0,0.6)}
.party-card .face img{width:100%;height:100%;object-fit:contain;image-rendering:pixelated}

.party-card .summary{min-width:0;display:flex;flex-direction:column;justify-content:center}
.party-card .line{display:flex;justify-content:space-between;align-items:baseline;margin-bottom:2px}
.party-card .line strong{font:italic 1000 23px/1 Impact,'Arial Black',sans-serif;letter-spacing:.5px;color:#0a1a27}
.party-card .line b{font-size:12px;font-weight:900;color:#536f80}
.party-card .bars-wrap{display:flex;flex-direction:column;gap:4px;margin-top:4px}
.party-card .bar-row{display:flex;align-items:center;gap:6px;font-size:10px;font-weight:900}
.party-card .bar-row span{width:18px;color:#6b8290;letter-spacing:.5px}
.party-card .bar-track{flex:1;height:7px;background:#abbdc6;overflow:hidden;transform:skew(-8deg)}
.party-card .bar-track.hp i{display:block;height:100%;background:var(--coral)}
.party-card .bar-track.mp i{display:block;height:100%;background:#5f88f5}
.party-card .bar-row small{width:46px;text-align:right;color:#183040;font-size:10px;font-weight:900}

/* center illustration */
.red-strike{position:absolute;pointer-events:none;clip-path:polygon(32% 0,94% 0,68% 100%,0 100%);background:linear-gradient(140deg,rgba(251,102,95,0.85),rgba(155,52,61,0.92));transform:rotate(-11deg)}
.illustration{position:absolute;pointer-events:none;z-index:1}
.illustration img{width:100%;height:100%;object-fit:contain;filter:drop-shadow(0 16px 20px rgba(5,15,24,0.75))}

/* right char panel */
.charpanel{position:absolute;left:1060px;top:15px;width:504px;z-index:3}
.char-name-badge{margin-bottom:12px}
.char-name-badge small{display:inline-block;background:#071c2b;color:var(--lime);font-size:11px;font-weight:900;letter-spacing:2px;padding:3px 9px;transform:skew(-8deg);margin-bottom:6px;border-left:3px solid var(--coral)}
.char-name{font:italic 1000 58px/.95 Impact,'Arial Black',sans-serif;letter-spacing:.8px;text-shadow:4px 5px 0 #05111d}
.type-tags{display:flex;gap:8px;margin-top:8px}
.type-tag{display:inline-flex;align-items:center;padding:6px 14px;transform:skew(-8deg);font:italic 900 14px Arial,sans-serif;color:#102235;background:var(--gold);letter-spacing:.8px}
.nature-tag{display:inline-flex;align-items:center;padding:6px 12px;transform:skew(-8deg);font-size:12px;font-weight:900;color:var(--paper);background:#102a3d;border:1px solid #4a6c80}

.levelbox{margin-top:14px;background:#091e2cdc;border:1px solid #4f7387;padding:10px 16px;box-shadow:4px 5px 0 rgba(4,13,23,0.5)}
.levelrow{display:flex;align-items:center;justify-content:space-between;font-size:14px;font-weight:900;letter-spacing:1px}
.levelrow b{font:italic 1000 34px Impact,sans-serif;color:var(--lime);margin-left:6px}
.xpbar{height:11px;background:#355060;transform:skew(-10deg);margin:8px 0 0}
.xpbar i{display:block;height:100%;background:var(--lime)}

/* statbox condensado: combate tático sem poluição */
.statbox{margin-top:12px;display:grid;grid-template-columns:1.55fr 1fr;gap:9px}
.paper{background:var(--paper);color:#0a1a27;clip-path:polygon(2% 0,100% 0,98% 100%,0 100%);padding:12px 14px}
.statrow{display:flex;align-items:center;gap:8px;margin:7px 0}
.statrow>span{width:42px;font-size:14px;font-weight:1000}
.statrow small{font-size:12px;font-weight:1000;min-width:68px;text-align:right}
.stat-track{height:10px;flex:1;background:#8d9caa;transform:skew(-8deg);overflow:hidden}
.stat-track.hp i{background:var(--coral);height:100%;display:block}
.stat-track.mp i{background:#5f86f5;height:100%;display:block}
.atbtiles{display:inline-flex;gap:4px;flex:1}
.atbtiles i{height:12px;flex:1;transform:skew(-10deg);background:#138cb5}
.atbtiles i.dim{background:#8a9fa7}

.cstats-panel{background:var(--glass-bg);border:var(--glass-border);padding:10px 12px;display:flex;flex-direction:column;justify-content:space-around}
.cstat-item{display:flex;align-items:center;justify-content:space-between;border-bottom:1px solid rgba(135,166,177,0.22);padding:4px 0;font-size:12px;font-weight:800}
.cstat-item:last-child{border-bottom:none}
.cstat-item span{color:#8ea9b5}
.cstat-item b{color:#fff;font-size:13px}

/* ability condensada: 1 linha limpa */
.ability-btn{margin-top:12px;width:100%;text-align:left;padding:10px 14px;background:#081b2bdc;border-left:7px solid var(--violet);border-top:1px solid #4a6a7c;border-bottom:1px solid #4a6a7c;border-right:1px solid #4a6a7c;transition:.15s}
.ability-btn:hover{background:#122a3d}
.ability-head{display:flex;align-items:center;gap:10px}
.ability-tag{font-size:10px;font-weight:900;letter-spacing:1.5px;color:var(--violet);background:#142337;padding:2px 6px}
.ability-btn .name{font:italic 1000 22px Impact,sans-serif;color:var(--paper);letter-spacing:.5px}
.ability-btn p{font-size:12.5px;color:#c1d3d8;margin:4px 0 0;line-height:1.25}

/* moves band inferior: botões táticos limpos */
.movesband{position:absolute;left:36px;right:36px;bottom:14px;z-index:8}
.movesband .head{margin-bottom:8px;padding-bottom:5px;display:flex;justify-content:space-between}
.movesband .head span{color:#8ea7b0;font-style:normal;font-weight:700;letter-spacing:1px}
.move-grid{display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:9px}
.move-card{position:relative;background:linear-gradient(135deg,rgba(14,48,65,0.95),rgba(9,26,44,0.95));border:1px solid #4e7386;height:124px;text-align:left;padding:10px 12px;clip-path:polygon(3% 0,100% 0,97% 100%,0 100%);overflow:hidden;transition:.15s}
.move-card:hover,.move-card.active{background:#1d465c;border-color:var(--lime);box-shadow:inset 0 0 0 1px var(--lime),0 4px 12px rgba(0,0,0,0.5)}
.move-top{display:flex;align-items:center;gap:9px}
.move-icon{width:40px;height:38px;display:flex;align-items:center;justify-content:center;background:var(--coral);color:#0a1926;font-size:22px;transform:skew(-8deg);flex-shrink:0}
.move-card:nth-child(2) .move-icon{background:var(--violet)}
.move-card:nth-child(3) .move-icon{background:var(--blue)}
.move-card:nth-child(4) .move-icon{background:var(--lime)}
.move-card:nth-child(5) .move-icon{background:var(--paper)}
.move-meta{min-width:0}
.move-title{font:italic 1000 19px/1.05 Impact,'Arial Black',sans-serif;letter-spacing:.3px;color:#fff}
.move-badges{display:flex;gap:5px;margin-top:4px}
.badge-atb{font-size:10px;font-weight:900;background:rgba(215,250,102,0.18);color:var(--lime);border:1px solid rgba(215,250,102,0.4);padding:1px 5px;transform:skew(-6deg)}
.badge-type{font-size:10px;font-weight:900;background:#142738;color:#a6c5d1;padding:1px 5px;transform:skew(-6deg)}
.move-desc-short{font-size:12px;color:#cbdbe0;margin-top:8px;padding-top:6px;border-top:1px solid rgba(84,116,129,0.5);line-height:1.2;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}

/* vitrine positioning */
.vitrine .illustration{left:420px;top:0;width:610px;height:630px}
.vitrine .red-strike{left:480px;top:20px;width:440px;height:580px;opacity:.78}
.vitrine .hero-tag{position:absolute;left:440px;bottom:148px;background:rgba(7,28,44,0.92);padding:7px 18px;border-left:5px solid var(--coral);font:italic 1000 20px Impact,sans-serif;z-index:3;box-shadow:4px 5px 0 #040d17}

/* footer */
.footer{position:absolute;bottom:0;left:0;right:0;height:35px;z-index:12;display:flex;align-items:center;justify-content:space-between;background:#030c16f2;border-top:1px solid #365365;padding:0 36px;font-size:12px;letter-spacing:1.2px;color:#b2c5cb;font-weight:800}
.footer b{color:var(--lime)}

/* dialog modal */
#dialog{position:absolute;inset:0;z-index:40;background:rgba(4,16,27,0.85);display:none;align-items:center;justify-content:center;backdrop-filter:blur(4px)}
#dialog.open{display:flex}
#dialog .sheet{width:560px;max-height:620px;background:linear-gradient(135deg,#133345,#061726);border:2px solid var(--lime);box-shadow:14px 14px 0 #020810;padding:26px 28px;transform:skew(-3deg);overflow:auto}
#dialog .sheet h2{font:italic 1000 42px Impact,sans-serif;margin:4px 0 8px;letter-spacing:.5px}
#dialog .sheet .dt{color:var(--lime);font-size:12px;font-weight:900;letter-spacing:2.5px}
#dialog .sheet p{font-size:17px;line-height:1.45;color:#e1edf0;white-space:pre-line}
#dialog .sheet .close{background:var(--lime);color:#0a1a24;font:italic 1000 18px Impact,sans-serif;padding:9px 22px;margin-top:14px;transition:.15s}
#dialog .sheet .close:hover{background:#fff}
</style></head><body><div id="viewport"><div id="stage"><div class="ambient"><div class="ruins" id="ruins"></div></div><div class="top-line"></div>

<header class="brand">
  <div class="logo">CRAWL<span class="slash">/</span><span class="mon">MON</span></div>
  <div class="page-tag"><strong>STATUS // EQUIPE</strong><span>FORA DE COMBATE</span></div>
</header>

<nav class="view-picker" aria-label="Layout do protótipo">
  <button data-layout="0" class="on"><b>01</b>VITRINE (DEFINITIVO)</button>
</nav>

<main class="scene" id="view"></main>

<footer class="footer">
  <span><b>↑ / ↓</b> POKÉMON &nbsp; · &nbsp; <b>← / →</b> MOVES &nbsp; · &nbsp; <b>Z / ENTER</b> DETALHES &nbsp; · &nbsp; <b>X / ESC</b> FECHAR</span>
  <span style="color:var(--gold)">CRAWLMON // STATUS</span>
</footer>

<div id="dialog" role="dialog" aria-modal="true" aria-label="Detalhes">
  <div class="sheet">
    <div class="dt" id="dialog-kind"></div>
    <h2 id="dialog-title"></h2>
    <p id="dialog-body"></p>
    <button class="close" id="close-dialog">FECHAR ✕</button>
  </div>
</div>
</div></div>

<script>
(()=>{'use strict';
const ART = {
  pancham: '__PANCHAM_ART__',
  abra: '__ABRA_ART__',
  gible: '__GIBLE_ART__'
};
const FACE = {
  pancham: '__PANCHAM_FACE__',
  abra: '__ABRA_FACE__',
  gible: '__GIBLE_FACE__'
};
const P = [
 {
   id: 'pancham',
   name: 'PANCHAM',
   number: '674',
   level: 14,
   hp: 45,
   maxHp: 45,
   mp: 24,
   maxMp: 24,
   exp: 3420,
   nextExp: 4200,
   types: ['LUTADOR'],
   nature: 'VALENTE (+ATK)',
   atk: 10,
   def: 8,
   vel: 0.45,
   fraq: 'PSI / VENTO',
   ability: 'PUNHO DE FERRO',
   abilityShort: '+20% de dano em ataques baseados em punho.',
   abilityText: 'Aumenta em +20% a força de golpes de punho contundentes (Soco Rápido, etc.). Passiva que transforma ataques diretos em golpes com altíssima taxa de quebra de guarda.',
   role: 'LÍDER // COMBATENTE CORPO A CORPO',
   moves: [
     ['SOCO RÁPIDO', '✦', '1 ATB', 'FÍSICO', 'Interrupção rápida', 'Ataque de punho veloz com baixíssimo custo de ATB. Pode quebrar a iniciativa e interromper conjurações inimigas.'],
     ['GOLPE DE CARATÊ', '⬢', '2 ATB', 'FÍSICO', 'Alto acerto crítico', 'Golpe marcial de mão aberta concentrado em pontos de pressão vitais. Possui chance crítica elevada.'],
     ['QUEBRA DE TELHA', '◆', '3 ATB', 'FÍSICO', 'Destrói barreiras', 'Ataque pesado descendente. Estilhaça escudos protetores (Reflect/Light Screen) e atordoa o oponente.'],
     ['PROVOCAÇÃO', '✹', '1 ATB', 'SUPORTE', 'Atrai aggro / Bloqueia', 'Provoca o inimigo com atitude insolente, forçando-o a focar ataques no Pancham e travando moves de status.']
   ]
 },
 {
   id: 'abra',
   name: 'ABRA',
   number: '063',
   level: 13,
   hp: 32,
   maxHp: 32,
   mp: 36,
   maxMp: 36,
   exp: 2890,
   nextExp: 3850,
   types: ['PSÍQUICO'],
   nature: 'MODESTA (+SPA)',
   atk: 12,
   def: 5,
   vel: 0.50,
   fraq: 'TREVAS / SOM',
   ability: 'SINCRONIA',
   abilityShort: 'Compartilha paralisia, fogo ou veneno com o agressor.',
   abilityText: 'Se Abra for afligido por Paralisia, Queimadura ou Envenenamento por um inimigo, o agressor compartilha imediatamente a mesma aflição de status.',
   role: 'RETROGUARDA // ARTILHEIRO PSI',
   moves: [
     ['CONFUSÃO', '◉', '2 ATB', 'ESPECIAL', '20% chance confusão', 'Pulso telecinético que desorienta as sinapses do cérebro do alvo, com 20% de chance de causar Confusão.'],
     ['RAIO PSÍQUICO', '✦', '3 ATB', 'ESPECIAL', 'Disparo perfurante', 'Feixe retilíneo que atravessa corredores estreitos de masmorra atingindo múltiplos oponentes em fila.'],
     ['ONDA DE CHOQUE', 'ϟ', '2 ATB', 'ESPECIAL', 'Acerto garantido', 'Descarga elétrica súbita que se curva pelo ar e nunca erra o alvo dentro de salas de masmorra.'],
     ['TELEPORTE RÁPIDO', '➤', '1 ATB', 'SUPORTE', 'Fuga / Recuo seguro', 'Dobra o tecido do espaço e reposiciona Abra instantaneamente para um tile seguro da retaguarda com recarga rápida.']
   ]
 },
 {
   id: 'gible',
   name: 'GIBLE',
   number: '443',
   level: 13,
   hp: 38,
   maxHp: 38,
   mp: 28,
   maxMp: 28,
   exp: 3100,
   nextExp: 4120,
   types: ['DRAGÃO', 'TERRESTRE'],
   nature: 'FIRME (+ATK)',
   atk: 9,
   def: 9,
   vel: 0.42,
   fraq: 'GELO / DRAGÃO',
   ability: 'PELE ÁSPERA',
   abilityShort: 'Reflete 1/8 de dano físico contra quem fizer contato.',
   abilityText: 'Inimigos que atacam com contato físico direto sofrem 1/8 do seu HP máximo em dano por atrito com as escamas afiadas de Gible.',
   role: 'VANGUARDA // DRAGÃO DE EMBOSCADA',
   moves: [
     ['MORDIDA', '✹', '1 ATB', 'FÍSICO', 'Chance de hesitação', 'Abocanha o inimigo com mandíbulas afiadas. Possui 30% de chance de causar Hesitação (Flinch).'],
     ['TIRO DE AREIA', '⬡', '2 ATB', 'ESPECIAL', 'Reduz precisão', 'Expele uma cortina abrasiva de partículas de terra que reduz drasticamente a precisão visual do alvo.'],
     ['GARRA DO DRAGÃO', '⬢', '3 ATB', 'FÍSICO', 'Corte dracônico letal', 'Dilacera o oponente com garras imbuídas de fúria dracônica em alta potência.'],
     ['INVESTIDA ESCAVADORA', '➤', '2 ATB', 'FÍSICO', 'Ataque subterrâneo', 'Mergulha no solo e ressurge abaixo do oponente desferindo impacto sísmico surpresa.']
   ]
 }
];

let selectedIndex = 0;
let selMove = 0;
const view = document.getElementById('view');
const dialog = document.getElementById('dialog');

function roster(){
  return `<div class="party-list">${P.map((c,i)=>`
    <button class="party-card ${i===selectedIndex?'active':''}" data-member="${i}" aria-label="Selecionar ${c.name}">
      <div class="face"><img src="${FACE[c.id]}" alt="${c.name}"></div>
      <div class="summary">
        <div class="line"><strong>${c.name}</strong><b>NV. ${c.level}</b></div>
        <div class="bars-wrap">
          <div class="bar-row"><span>HP</span><div class="bar-track hp"><i style="width:${(c.hp/c.maxHp)*100}%"></i></div><small>${c.hp}/${c.maxHp}</small></div>
          <div class="bar-row"><span>MP</span><div class="bar-track mp"><i style="width:${(c.mp/c.maxMp)*100}%"></i></div><small>${c.mp}/${c.maxMp}</small></div>
        </div>
      </div>
    </button>
  `).join('')}</div>`;
}

function renderMoves(c){
  const allMoves = [...c.moves, ['INVESTIDA', '✦', '1 ATB', 'FÍSICO', 'Golpe neutro básico', 'Golpe corporal universal de contato com custo de 1 bloco de ATB. Disponível livremente sem ocupar os 4 slots principais.']];
  return allMoves.map((m,i)=>`
    <button class="move-card ${selMove===i?'active':''}" data-move="${i}">
      <div class="move-top">
        <div class="move-icon">${m[1]}</div>
        <div class="move-meta">
          <div class="move-title">${m[0]}</div>
          <div class="move-badges">
            <span class="badge-atb">${m[2]}</span>
            <span class="badge-type">${m[3]}</span>
          </div>
        </div>
      </div>
      <div class="move-desc-short">${m[4]}</div>
    </button>
  `).join('');
}

function render(){
  const c = P[selectedIndex];
  view.innerHTML = `
    <section class="vitrine">
      <div class="team-col">
        <div class="head">EQUIPE // 3 POKÉMON</div>
        ${roster()}
      </div>

      <div class="red-strike"></div>
      <div class="illustration"><img src="${ART[c.id]}" alt="${c.name}"></div>
      <div class="hero-tag">◆ ${c.role}</div>

      <div class="charpanel">
        <div class="char-name-badge">
          <small>#${c.number} // PROTAGONISTA</small>
          <div class="char-name">${c.name}</div>
        </div>

        <div class="type-tags">
          ${c.types.map(t=>`<div class="type-tag">✦ ${t}</div>`).join('')}
          <div class="nature-tag">${c.nature}</div>
        </div>

        <div class="levelbox">
          <div class="levelrow">
            <span>NÍVEL <b>${c.level}</b></span>
            <span style="font-size:12px;font-weight:900;color:#9ec0cc">EXP ${c.exp.toLocaleString('pt-BR')} / ${c.nextExp.toLocaleString('pt-BR')}</span>
          </div>
          <div class="xpbar"><i style="width:${(c.exp/c.nextExp*100).toFixed(1)}%"></i></div>
        </div>

        <div class="statbox">
          <div class="paper">
            <div style="font-size:12px;font-weight:1000;letter-spacing:1px;margin-bottom:6px;color:#0e2435">BARRAS DE COMBATE</div>
            <div class="statrow"><span>HP</span><div class="stat-track hp"><i style="width:${(c.hp/c.maxHp)*100}%"></i></div><small>${c.hp} / ${c.maxHp}</small></div>
            <div class="statrow"><span>MP</span><div class="stat-track mp"><i style="width:${(c.mp/c.maxMp)*100}%"></i></div><small>${c.mp} / ${c.maxMp}</small></div>
            <div class="statrow atbrow"><span>ATB</span><div class="atbtiles"><i></i><i></i><i></i><i></i><i></i></div><small>5 BLOCOS</small></div>
          </div>

          <div class="cstats-panel">
            <div class="cstat-item"><span>ATK</span><b>${c.atk}</b></div>
            <div class="cstat-item"><span>DEF</span><b>${c.def}</b></div>
            <div class="cstat-item"><span>VEL</span><b>${c.vel}</b></div>
            <div class="cstat-item"><span>FRAQUEZA</span><b style="color:var(--coral)">${c.fraq}</b></div>
          </div>
        </div>

        <button class="ability-btn" data-detail="ability">
          <div class="ability-head">
            <span class="ability-tag">PASSIVA</span>
            <strong class="name">${c.ability}</strong>
          </div>
          <p>${c.abilityShort}</p>
        </button>
      </div>

      <div class="movesband">
        <div class="head">
          <span>MOVES EQUIPADOS (4/4) + INVESTIDA BÁSICA</span>
          <span>CLIQUE OU [Z] PARA DETALHES</span>
        </div>
        <div class="move-grid">${renderMoves(c)}</div>
      </div>
    </section>
  `;
}

function showDialog(kind, title, body){
  document.getElementById('dialog-kind').textContent = kind;
  document.getElementById('dialog-title').textContent = title;
  document.getElementById('dialog-body').textContent = body;
  dialog.classList.add('open');
}

function detailMove(idx){
  selMove = idx;
  render();
  const c = P[selectedIndex];
  const allMoves = [...c.moves, ['INVESTIDA', '✦', '1 ATB', 'FÍSICO', 'Golpe neutro básico', 'Golpe corporal universal de contato com custo de 1 bloco de ATB. Disponível livremente sem ocupar os 4 slots principais.']];
  const m = allMoves[idx];
  showDialog('MOVE // DETALHES TÁTICOS', m[0], `${m[5]}\n\n• Custo de ATB: ${m[2]}\n• Categoria: ${m[3]}\n• Efeito: ${m[4]}`);
}

view.addEventListener('click', e => {
  const b = e.target.closest('button');
  if(!b) return;
  if(b.hasAttribute('data-member')){
    selectedIndex = Number(b.dataset.member);
    selMove = 0;
    render();
    return;
  }
  if(b.hasAttribute('data-move')){
    detailMove(Number(b.dataset.move));
    return;
  }
  if(b.dataset.detail === 'ability'){
    const c = P[selectedIndex];
    showDialog('HABILIDADE PASSIVA', c.ability, `${c.abilityText}\n\n• Ativação: Automática e contínua durante a exploração e combate.`);
    return;
  }
});

document.getElementById('close-dialog').addEventListener('click', ()=>dialog.classList.remove('open'));
dialog.addEventListener('click', e => { if(e.target === dialog) dialog.classList.remove('open'); });

window.addEventListener('keydown', e => {
  if(e.key === 'Escape' || e.key.toLowerCase() === 'x'){
    dialog.classList.remove('open');
    e.preventDefault();
    return;
  }
  if(dialog.classList.contains('open')) return;
  if(e.key === 'ArrowUp'){
    selectedIndex = (selectedIndex - 1 + P.length) % P.length;
    selMove = 0;
    render();
    e.preventDefault();
    return;
  }
  if(e.key === 'ArrowDown'){
    selectedIndex = (selectedIndex + 1) % P.length;
    selMove = 0;
    render();
    e.preventDefault();
    return;
  }
  if(e.key === 'ArrowLeft' || e.key === 'ArrowRight'){
    selMove = (selMove + (e.key === 'ArrowLeft' ? 4 : 1)) % 5;
    render();
    e.preventDefault();
    return;
  }
  if(e.key === 'Enter' || e.key.toLowerCase() === 'z'){
    detailMove(selMove);
    e.preventDefault();
    return;
  }
});

function scale(){
  const sc = Math.min(window.innerWidth / 1600, window.innerHeight / 900);
  document.getElementById('stage').style.transform = `scale(${sc})`;
}
window.addEventListener('resize', scale);
scale();

// decor ruins
const ruins = document.getElementById('ruins');
for(let i=0; i<12; i++){
  let h = 130 + (i*67)%250, x = i*142 + 25;
  ruins.insertAdjacentHTML('beforeend', `<i class="spire" style="--h:${h}px;--x:${x}px"></i><i class="lamp" style="--h:${h}px;--x:${x}px"></i>`);
}

render();
})();
</script></body></html>'''

html_final = html_template.replace('__PANCHAM_ART__', art['pancham'])
html_final = html_final.replace('__ABRA_ART__', art['abra'])
html_final = html_final.replace('__GIBLE_ART__', art['gible'])
html_final = html_final.replace('__PANCHAM_FACE__', art['pancham_face'])
html_final = html_final.replace('__ABRA_FACE__', art['abra_face'])
html_final = html_final.replace('__GIBLE_FACE__', art['gible_face'])

with open('STATUS_PROTOTIPOS.html', 'w', encoding='utf-8') as f:
    f.write(html_final)

print('Updated cleanly!')
