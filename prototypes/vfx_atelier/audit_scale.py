"""Check mesh/particle dimensions, excluding positions, across participants and sizes."""
from pathlib import Path
from playwright.sync_api import sync_playwright
import json
p=Path(__file__).parent
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='C:/Users/zerke/AppData/Local/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-win64/chrome-headless-shell.exe',headless=True,args=['--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    page=browser.new_page()
    page.goto((p/'atelier.html').as_uri())
    page.wait_for_function('window.atelier')
    data=page.evaluate('''()=>{
      const a=atelier;a.state.paused=true;document.getElementById('btn-toggle-sfx').click();a.setClones(true);
      const random=Math.random, results=[];
      const round=x=>+x.toFixed(5);
      for(let move=0;move<8;move++){
        const samples=[];
        for(const [attacker,target,sourceScale,targetScale] of [[0,2,1,1],[2,0,1,1],[2,0,.65,1.6]]){
          for(let j=0;j<1200;j++)a.step(1/120);
          a.actors.forEach(x=>{x.hp=x.maxHp;x.burnRemaining=0;x.model.root.scale.setScalar(1);});
          a.actors[attacker].model.root.scale.setScalar(sourceScale);a.actors[target].model.root.scale.setScalar(targetScale);
          a.select(attacker,target);
          let seed=54321;Math.random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
          a.state.paused=false;a.cast(move);a.state.paused=true;
          const c=a.current, snaps=[];
          for(let j=0;j<200;j++){
            a.step(1/120);
            if([29,107,179].includes(j)){
              const meshes=c.vfx.meshes.map(x=>({type:x.mesh.type,scale:x.mesh.scale.toArray().map(round),geometry:x.mesh.geometry?.parameters||null}));
              const sizes=c.vfx.systems.map(s=>s.particles.slice(0,s.particleNum).map(p=>round(p.atelier.sizeStart)));
              snaps.push({frameScale:c.frame.scale.toArray(),meshes,sizes});
            }
          }
          Math.random=random;samples.push({attacker,target,sourceScale,targetScale,snaps});
        }
        results.push({move,sizeInvariant:JSON.stringify(samples[1].snaps)===JSON.stringify(samples[2].snaps),crossActorRandomSamplesEqual:JSON.stringify(samples[0].snaps)===JSON.stringify(samples[1].snaps),samples});
      }
      Math.random=random;return results;
    }''')
    (p/'scale-results.json').write_text(json.dumps(data,indent=2),encoding='utf8')
    print(json.dumps([{'move':x['move'],'sizeInvariant':x['sizeInvariant']}for x in data]),flush=True)
    assert all(x['sizeInvariant'] for x in data)
    browser.close()
