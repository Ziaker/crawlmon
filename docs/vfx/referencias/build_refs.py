"""Gera o dataset do dossiê e baixa as imagens de capa das 60 referências selecionadas.

Uso: python docs/vfx/referencias/build_refs.py
Saída: refs.json, images/*.jpg, contact-<id>.png
"""
from __future__ import annotations

import json
import pathlib
import re
import time

import requests

ROOT = pathlib.Path(__file__).resolve().parent
IMG = ROOT / "images"
IMG.mkdir(parents=True, exist_ok=True)

H = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36",
    "Accept-Language": "en-US,en;q=0.9",
}

YT = {
    "ggjohnny": "https://www.youtube.com/watch?v=wyJHtD5qo5Q",
    "ggaba": "https://www.youtube.com/watch?v=N1g21MYhCxE",
    "ssjaura": "https://www.youtube.com/watch?v=ESOShZCqVZY",
    "tornado4": "https://www.youtube.com/watch?v=oa2TK0zP8lc",
    "vfxhit2d": "https://www.youtube.com/watch?v=Zzha-1ccQak",
    "impactframes": "https://www.youtube.com/watch?v=HVLuol2m5gQ",
    "animestyle": "https://www.youtube.com/watch?v=fOTL1CtnZ58",
}

U = {
    "fireslash": "https://mouradzzz.artstation.com/projects/3EaexB",
    "aura": "https://mouradzzz.artstation.com/projects/AZ6XqW",
    "slashlix": "https://lixsh.artstation.com/projects/ea8PrX",
    "genshinbreak": "https://www.vfxapprentice.com/blog/genshin-impact-stylized-vfx-breakdown",
    "hsrstudy": "https://nathanlacsamana.com/hsr-vfx-style-study",
    "brais": "https://realtimevfx.com/t/brais-sketchbook/31406",
    "noska": "https://realtimevfx.com/t/noska-sketch-50/19460",
    "stt": "https://realtimevfx.com/t/stt-sketch-22/8586",
    "venomslash": "https://realtimevfx.com/t/venom-slash-breakdown-of-the-effect-included/18903",
    "ali": "https://realtimevfx.com/t/alis-sketchbook/29539/6",
    "ggreverse": "https://realtimevfx.com/t/please-help-me-reverse-engineer-this-effect-from-guilty-gear-strive/30609",
    "swordwip": "https://realtimevfx.com/t/wip-sword-slash-attack/1272",
    "firebeam": "https://80.lv/articles/using-unreal-engine-to-make-an-anime-inspired-stylized-fire-beam-vfx",
    "kamehameha": "https://80.lv/articles/crafting-a-kamehameha-like-vfx-001agt",
    "doctorstrange": "https://www.framestore.com/work/doctor-strange",
    "chavez": "https://britishcinematographer.co.uk/framestore-creates-mind-bending-vfx-for-doctor-strange-in-the-multiverse-of-madness",
    "zzz": "https://80.lv/articles/check-out-this-fancy-real-time-attack-vfx-for-zenless-zone-zero-animation",
    "ggcombo": "https://80.lv/articles/animating-guilty-gear-inspired-fighting-game-combo-in-maya",
    "onepunch": "https://rebelway.net/one-punch-man-houdini-tutorial",
    "roclicks": "https://roclicks.gg/resources/animation/hit-feel",
    "impactpack": "https://3dxdev.com/assets/impact-frames-anime-hit-effects-for-unreal-engine-5",
    "stylizedvol1": "https://www.fab.com/listings/2b4f57ab-e9e8-42a2-953c-c0431148b101",
    "animepack": "https://www.fab.com/listings/d85dee78-9584-4b4b-a3b7-4b96de33c2b8",
    "meleetrails": "https://www.fab.com/listings/bb36b822-001a-4927-a02b-79b17cf2b36b",
    "tornado_cghow": "https://dev.epicgames.com/community/learning/tutorials/XvOj9/unreal-engine-simple-stylized-tornado-vfx-in-ue5-niagara-torus-mesh-erode-dynamic-params",
    "tornado_gustavo": "https://80.lv/articles/neat-stylized-tornado-vfx-set-up-in-unreal-engine-s-niagara",
    "tornado_kfir": "https://80.lv/articles/take-a-look-at-these-stylized-tornado-vfx-created-with-ue5-s-niagara",
    "groundcrack": "https://www.1mafx.com/blog/ground-crack-vfx-breakdown",
    "cgcircuit": "https://www.cgcircuit.com/tutorial/houdini-rbd-ii---ground-destruction",
    "concrete": "https://80.lv/articles/creating-cracking-concrete-effect-using-houdini",
    "keiren": "https://keirenwall.com/home/Houdini-Decals",
    "sidefx": "https://www.sidefx.com/learn/talks/destruction-vfx-techniques-with-houdini-and-unreal/",
    "groundbreak": "https://realtimevfx.com/t/the-ground-breaking-effect/5832",
    "pawel": "https://80.lv/articles/breakdown-creating-vfx-in-unreal-engine-4",
    "impactue5": "https://realtimevfx.com/t/impact-frames-in-ue5/24982",
    "lightning": "https://realtimevfx.com/t/lightning-strike-stylized-what-do-you-guys-think-update/1972",
    "fireball": "https://realtimevfx.com/t/stylized-fireball-projectile/31658",
    "impacthit": "https://www.fab.com/listings/a26762b8-4e7b-4009-b0cb-864b8249b3be",
    **YT,
}


def ref(n, title, key, why, note=""):
    return {"n": n, "title": title, "url": U[key], "source": key, "why": why, "note": note}


CATS = [
    {
        "id": "vortex", "lib": "LIB-VFX-01", "name": "Vortex Mesh",
        "candidates": [
            ref(1, "Doctor Strange — eldritch portal (sparks)", "doctorstrange",
                "Portal feito de faíscas longas e curvas, com centro de energia — a referência mais próxima de vórtice com leitura espacial."),
            ref(2, "America Chavez — star portal (crystal edges)", "chavez",
                "Borda que se fragmenta e se reconstrói, sugando detritos: ensina a tratar o aro do vórtice como peça viva."),
            ref(3, "CGHOW — stylized tornado (torus mesh + vortex force)", "tornado_cghow",
                "Vórtice baseado em malha de toro com erode e parâmetros por partícula; resolve volume sem sprite."),
            ref(4, "Gustavo Dresch Rosa — cone tornado study", "tornado_gustavo",
                "Camadas de cone com shader de tornado e detritos orbitando; silhueta Ghibli."),
            ref(5, "Kfir Balouka — storm tornado (UE5 + Substance)", "tornado_kfir",
                "Texturas autorais e erosão; mostra como o ruído dá breakup à parede do vórtice."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "funnel", "lib": "LIB-VFX-02", "name": "Tornado / Funnel",
        "candidates": [
            ref(1, "CGHOW — simple stylized tornado", "tornado_cghow",
                "Malha de toro + vortex force + erode por partícula; o método mais replicável."),
            ref(2, "Gustavo Dresch Rosa — layered cone tornado", "tornado_gustavo",
                "Camadas cônicas com shader e detritos; leitura de volume em rotação."),
            ref(3, "Kfir Balouka — stormy tornado", "tornado_kfir",
                "Textura/erosão autoral, silhueta irregular e clima."),
            ref(4, "UE4 Niagara — stylized tornado preview", "tornado4",
                "Vídeo de estudo com foco em forma e movimento, não em realismo."),
            ref(5, "Brais — explosion smoke cloud meshes", "brais",
                "Nuvens em malha (não sprite) com depth fade: referência para a base de poeira do funil."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "ribbon", "lib": "LIB-VFX-03", "name": "Spiral Ribbon",
        "candidates": [
            ref(1, "Mourad El Ghali — Fire Slash (Genshin-inspired)", "fireslash",
                "Fita de fogo com fases charge/impact/slash e dissipação; boa referência de largura e ponta."),
            ref(2, "Lucie Travaux — Slash VFX (Unity Shader Graph)", "slashlix",
                "Fita/arco com textura alpha e leitura limpa em 3D."),
            ref(3, "Ali's Sketchbook — procedural slash shader (MIT)", "ali",
                "Shader que desenha triângulo, distorce com ruído e dissolve: base para fita 3D."),
            ref(4, "Stt Sketch #22 — mesh slash textures", "stt",
                "Duas camadas de textura (emissiva + trilha escura) em malha de slash."),
            ref(5, "Fab — Melee Weapon Aura & Trails", "meleetrails",
                "Pacote com fitas de arma e aura; referência de continuidade e taper."),
        ],
        "selected": [1, 3, 5],
    },
    {
        "id": "helix", "lib": "LIB-VFX-04", "name": "Helix Cylinder",
        "candidates": [
            ref(1, "Rayane Saada — anime fire beam", "firebeam",
                "Feixe com buildup/impact/release, fresnel e textura panning distorcida."),
            ref(2, "Harry Alisavakis — Kamehameha-like laser", "kamehameha",
                "Núcleo, esferas de carga e poeira circular; timing de feixe."),
            ref(3, "VFX Apprentice — Genshin VFX breakdown", "genshinbreak",
                "Malhas 3D assimétricas para slashes/feixes, impacto em 2 frames."),
            ref(4, "Vefects — Anime Stylized VFX (pack)", "animepack",
                "Slash/projéteis/explosões com estética anime; referência de reuso de material."),
            ref(5, "Nathan Lacsamana — HSR style study", "hsrstudy",
                "Impacto azul direcional com fragmentos e kaleidoscópio; referência de cor e breakup."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "dissolve", "lib": "LIB-VFX-05", "name": "Spiral Erosion",
        "candidates": [
            ref(1, "Venom Slash — alpha mask + noise", "venomslash",
                "Máscara anelar, ruído rolando e atlas de respingos: erosão aplicada a uma superfície real."),
            ref(2, "Ali's Sketchbook — procedural slash dissolve", "ali",
                "Dissolve com ruído e distorção, código MIT; referência de shader."),
            ref(3, "Brais — reusable procedural smoke material", "brais",
                "Material paramétrico com dissolve e gradient; como manter a superfície legível."),
            ref(4, "Kfir Balouka — tornado erosion material", "tornado_kfir",
                "Erosão aplicada a um volume em movimento."),
            ref(5, "CGHOW — tornado erode material", "tornado_cghow",
                "Erode/tiling por partícula; breakup não uniforme."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "thrust", "lib": "LIB-VFX-06", "name": "Thrust Cone",
        "candidates": [
            ref(1, "Guilty Gear combo breakdown (80.lv)", "ggcombo",
                "Dash com linhas de velocidade, rim light e impact frames; ritmo de anime fighter."),
            ref(2, "GG Strive 2.0 — Johnny breakdown", "ggjohnny",
                "Vídeo de referência de dash/close slash; timing real do jogo."),
            ref(3, "Stormhound — ZZZ attack VFX", "zzz",
                "Ataque com faíscas e flares; referência de aceleração e cone."),
            ref(4, "Vefects — Anime Stylized VFX (dash)", "animepack",
                "Pack com dash e slash; referência de composição."),
            ref(5, "Lucie Travaux — Slash VFX", "slashlix",
                "Fita com direção clara; base para o cone de avanço."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "speedlines", "lib": "LIB-VFX-07", "name": "Speed Lines",
        "candidates": [
            ref(1, "Guilty Gear combo breakdown", "ggcombo",
                "Speed lines 2D sobre 3D, com rim light e hitstop."),
            ref(2, "GG Strive Johnny breakdown", "ggjohnny",
                "Referência de dash e close slash no jogo real."),
            ref(3, "Genshin VFX breakdown", "genshinbreak",
                "Timing snappy e linhas de ação; contraste e restrição."),
            ref(4, "VFX Apprentice — 2D hit impact", "vfxhit2d",
                "Linhas de impacto desenhadas quadro a quadro."),
            ref(5, "ZZZ attack VFX", "zzz",
                "Flares e riscos de velocidade em ataque 3D."),
        ],
        "selected": [1, 2, 4],
    },
    {
        "id": "motiontrail", "lib": "LIB-VFX-08", "name": "Motion Trail",
        "candidates": [
            ref(1, "Fab — Melee Weapon Aura & Trails", "meleetrails",
                "Trilhas de arma com largura/taper e continuidade."),
            ref(2, "Lucie Travaux — Slash VFX", "slashlix",
                "Fita que preserva a curva do movimento."),
            ref(3, "Mourad — Fire Slash", "fireslash",
                "Rastro de fogo com dissipação."),
            ref(4, "Stt Sketch #22", "stt",
                "Trilha escura secundária sob o slash emissivo."),
            ref(5, "Venom Slash", "venomslash",
                "Máscara + ruído para a trilha não ficar rígida."),
        ],
        "selected": [1, 2, 4],
    },
    {
        "id": "aura", "lib": "LIB-VFX-09", "name": "Aura Burst",
        "candidates": [
            ref(1, "Mourad — Outline Anime Aura (Genshin-inspired)", "aura",
                "Aura com outline e gradiente, adaptável a qualquer modelo."),
            ref(2, "Super Saiyan Aura — After Effects tutorial", "ssjaura",
                "Referência de silhueta de aura DBZ, com camadas e ruído."),
            ref(3, "Genshin VFX breakdown", "genshinbreak",
                "Buffs/auras com timing e cor."),
            ref(4, "Vefects — Anime Stylized VFX (buff)", "animepack",
                "Buff cast + loop; referência de loop e dissipação."),
            ref(5, "Brais — fake light / gradient material", "brais",
                "Como dar luz falsa e volume a uma superfície."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "dust", "lib": "LIB-VFX-10", "name": "Dust Trail",
        "candidates": [
            ref(1, "Brais — smoke cloud meshes", "brais",
                "Nuvens de fumaça em malha com dissolve e depth fade."),
            ref(2, "Guilty Gear combo breakdown", "ggcombo",
                "Poeira de dash e pouso no ritmo do jogo."),
            ref(3, "Noska Sketch #50", "noska",
                "Fumaça/explosão com camadas e antecipação."),
            ref(4, "1mafx — ground crack breakdown", "groundcrack",
                "Dust bursts em impactos de solo."),
            ref(5, "Venom Slash", "venomslash",
                "Respingos com atlas e dissolve."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "scuff", "lib": "LIB-VFX-11", "name": "Brake Dust",
        "candidates": [
            ref(1, "Guilty Gear combo breakdown", "ggcombo",
                "Frenagem/slide com poeira direcional."),
            ref(2, "Stormhound — ZZZ attack", "zzz",
                "Parada brusca com faíscas e poeira."),
            ref(3, "1mafx — ground crack", "groundcrack",
                "Poeira em leque no impacto de solo."),
            ref(4, "Brais — smoke", "brais",
                "Nuvem com expansão e dissipação."),
            ref(5, "GG Strive Johnny breakdown", "ggjohnny",
                "Referência de dash/parada."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "scratch", "lib": "LIB-VFX-12", "name": "Ground Scratch",
        "candidates": [
            ref(1, "Keiren Wall — ground slam decals", "keiren",
                "Rachadura com height/normal/roughness e parallax; profundidade real."),
            ref(2, "1mafx — ground crack", "groundcrack",
                "Fratura procedural + textura + VFX de poeira."),
            ref(3, "Pol Villà — cracking concrete", "concrete",
                "Rachadura em concreto com atributos e shader."),
            ref(4, "RealTimeVFX — ground breaking", "groundbreak",
                "Discussão de mesh/skeletal para o chão quebrar."),
            ref(5, "CGcircuit — Houdini RBD ground destruction", "cgcircuit",
                "Rachaduras e importação para Unreal."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "shockwave", "lib": "LIB-VFX-13", "name": "Shockwave Ring",
        "candidates": [
            ref(1, "Brais — shockwave disk + heat distortion", "brais",
                "Disco com UV radial e distorção de calor; referência de frente de onda."),
            ref(2, "Noska Sketch #50 — shockwave mesh", "noska",
                "Malha de shockwave com escala e cor; antecipação e impacto."),
            ref(3, "80.lv — stylized lightning", "lightning",
                "Crítica de timing: atrasar a onda 0,1–0,15 s e encurtar o impacto."),
            ref(4, "CGHOW — radial to shockwave (Niagara)", "tornado_cghow",
                "Gradiente radial → onda sem textura; técnica limpa."),
            ref(5, "Rebelway — One-Punch Man impact", "onepunch",
                "Impacto de escala grande com onda e detritos."),
        ],
        "selected": [1, 2, 5],
    },
    {
        "id": "crown", "lib": "LIB-VFX-14", "name": "Impact Crown",
        "candidates": [
            ref(1, "VFX Apprentice — Genshin impact frames", "genshinbreak",
                "Impacto em 2 frames, contraste alto e silhueta antes do detalhe."),
            ref(2, "3dxdev — Impact Frames (UE5)", "impactpack",
                "Pacote de frames de impacto: branco, silhueta e linhas."),
            ref(3, "80.lv — Guilty Gear combo", "ggcombo",
                "Impact frames + hitstop + speed lines no ritmo de anime fighter."),
            ref(4, "Rebelway — One-Punch Man impact", "onepunch",
                "Impacto cinematográfico com poeira, detritos e onda."),
            ref(5, "RoClicks — hitstop/impact frames", "roclicks",
                "Tempos de vida por elemento (flash 0,03–0,15 s; corpo 0,35–1,2 s)."),
        ],
        "selected": [1, 2, 4],
    },
    {
        "id": "blastcone", "lib": "LIB-VFX-15", "name": "Blast Cone",
        "candidates": [
            ref(1, "Rayane Saada — anime fire beam", "firebeam",
                "Cone/feixe direcional com release instantâneo."),
            ref(2, "Rebelway — One-Punch Man impact", "onepunch",
                "Cone de pressão com poeira e detritos."),
            ref(3, "Brais — initial blast", "brais",
                "Duas esferas/malhas para o blast inicial, sem sprite."),
            ref(4, "Noska Sketch #50", "noska",
                "Explosão com malha e flipbook."),
            ref(5, "Pawel Margacz — cast/impact breakdown", "pawel",
                "Impacto com flash, círculo, faíscas e detritos."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "fracture", "lib": "LIB-VFX-16", "name": "Ground Fracture",
        "candidates": [
            ref(1, "1mafx — ground crack (3 parts)", "groundcrack",
                "Houdini RBD + Substance + Niagara; pipeline completo."),
            ref(2, "Keiren Wall — ground slam decals", "keiren",
                "Fratura convertida em decal com parallax."),
            ref(3, "Pol Villà — cracking concrete", "concrete",
                "Fratura com feedback loop e detalhe no shader."),
            ref(4, "SideFX — destruction techniques", "sidefx",
                "Aulas de fratura Houdini → Unreal/Niagara."),
            ref(5, "CGcircuit — Houdini RBD II", "cgcircuit",
                "Cracks e RBD para ground destruction."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "flipbook", "lib": "LIB-VFX-17", "name": "Anime Impact Flipbook",
        "candidates": [
            ref(1, "VFX Apprentice — 2D hit impact (part 3)", "vfxhit2d",
                "Construção quadro a quadro de um impacto 2D; dissolve e in-between."),
            ref(2, "3dxdev — Impact Frames UE5", "impactpack",
                "Frames brancos/negativos e como aplicar em Niagara."),
            ref(3, "RealTimeVFX — impact frames in UE5", "impactue5",
                "Discussão de sprite vs post-process e LUT."),
            ref(4, "GG Strive effect reverse engineering", "ggreverse",
                "Hipótese de flipbook em malha 3D no jogo."),
            ref(5, "Genshin VFX breakdown", "genshinbreak",
                "Impacto em 2 frames e leitura de atlas."),
        ],
        "selected": [1, 2, 4],
    },
    {
        "id": "sparks", "lib": "LIB-VFX-18", "name": "Kinetic Sparks",
        "candidates": [
            ref(1, "Venom Slash — splash atlas", "venomslash",
                "Atlas de respingos com glow e dissolve; direção do corte."),
            ref(2, "Stylized Fireball — impact particles", "fireball",
                "Faíscas/partículas com bandas de cor e line art."),
            ref(3, "Pawel Margacz — impact", "pawel",
                "Faíscas com várias configurações no mesmo impacto."),
            ref(4, "Guilty Gear combo", "ggcombo",
                "Hit sparks com timing e hitstop."),
            ref(5, "1mafx — ground crack", "groundcrack",
                "Fragmentos e poeira no impacto de solo."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "debris", "lib": "LIB-VFX-19", "name": "Directional Debris",
        "candidates": [
            ref(1, "Brais — debris ribbons + cloud meshes", "brais",
                "Detritos com ribbons e nuvens em malha; profundidade."),
            ref(2, "1mafx — ground crack debris", "groundcrack",
                "Pedras e poeira em camadas separadas."),
            ref(3, "SideFX — destruction techniques", "sidefx",
                "Fratura + Niagara para detritos e poeira."),
            ref(4, "Noska Sketch #50", "noska",
                "Detritos e faíscas com escalas diferentes."),
            ref(5, "CGcircuit — ground destruction", "cgcircuit",
                "RBD e cacos com peso."),
        ],
        "selected": [1, 2, 3],
    },
    {
        "id": "slash", "lib": "LIB-VFX-20", "name": "Slash Arc",
        "candidates": [
            ref(1, "Mourad — Fire Slash", "fireslash",
                "Corte de fogo com charge/impact/slash e dissipação."),
            ref(2, "Ali's Sketchbook — procedural slash (MIT)", "ali",
                "Shader de slash com triângulo distorcido, ruído e aberração cromática."),
            ref(3, "Venom Slash — ring mesh + noise", "venomslash",
                "Malha anelar, alpha mask e duas texturas multiplicadas."),
            ref(4, "Stt Sketch #22", "stt",
                "Camadas de textura e mesh particles."),
            ref(5, "Lucie Travaux — Slash VFX", "slashlix",
                "Fita limpa com shader graph e alpha."),
        ],
        "selected": [1, 2, 3],
    },
]


def og_image(url: str):
    if "youtube.com/watch" in url:
        vid = re.search(r"v=([\w-]{6,})", url)
        if vid:
            return f"https://img.youtube.com/vi/{vid.group(1)}/hqdefault.jpg"
    try:
        r = requests.get(url, headers=H, timeout=30)
        if r.status_code >= 400:
            return None
        html = r.text
        pats = [
            r'<meta[^>]+(?:property|name)=["\'](?:og:image|twitter:image)["\'][^>]+content=["\']([^"\']+)',
            r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+(?:property|name)=["\'](?:og:image|twitter:image)["\']',
        ]
        for p in pats:
            m = re.findall(p, html, flags=re.I)
            if m:
                return m[0]
    except Exception:
        return None
    return None


if __name__ == "__main__":
    manifest = []
    for cat in CATS:
        entry = {k: cat[k] for k in ("id", "lib", "name", "candidates", "selected")}
        manifest.append(entry)

    (ROOT / "refs.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")

    for cat in CATS:
        for n in cat["selected"]:
            c = next(x for x in cat["candidates"] if x["n"] == n)
            out = IMG / f"{cat['id']}-{n}.jpg"
            if out.exists():
                continue
            img_url = og_image(c["url"])
            if not img_url:
                print("sem imagem:", cat["id"], n, c["url"])
                continue
            try:
                r = requests.get(img_url, headers=H, timeout=40)
                if r.status_code == 200 and len(r.content) > 2000:
                    out.write_bytes(r.content)
                    print("ok", out.name, len(r.content))
                else:
                    print("falhou", cat["id"], n, r.status_code, len(r.content))
            except Exception as e:
                print("erro", cat["id"], n, e)
            time.sleep(0.2)
