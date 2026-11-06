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
      const a=atelier; a.state.paused=true;
      document.getElementById('btn-toggle-sfx').click();
      const rows=[];
      a.state.paused=false;
      const initial=a.timeline.time;a.advanceReal(-.1);
      const negativeIgnored=a.timeline.time===initial;
      a.state.paused=true;
      for(let trial=0;trial<24;trial++){
        for(let j=0;j<1200;j++)a.step(1/120);
        a.actors.forEach(x=>{x.hp=x.maxHp;x.burnRemaining=0;});
        a.state.speed=1;a.state.paused=false;
        // Exercise the fractional remainder of the real-time accumulator.
        a.advanceReal((trial%8)*.0011);
        const accepted=a.cast(6), start=a.timeline.time;
        const events=a.timeline.queue.map(e=>+(e.time-start).toFixed(6));
        a.advanceReal(.4);a.state.speed=.25;a.advanceReal(1.6);
        const before={time:a.timeline.time-start,hp:a.actors[2].hp};
        a.state.paused=true;a.advanceReal(10);
        const pause={time:a.timeline.time-start,hp:a.actors[2].hp};
        a.state.paused=false;a.state.speed=.5;a.advanceReal(.54);
        const prehit={time:a.timeline.time-start,hp:a.actors[2].hp};
        a.advanceReal(.06);
        const hit={time:a.timeline.time-start,hp:a.actors[2].hp};
        a.state.paused=true;
        rows.push({trial,accepted,events,before,pause,prehit,hit,
          pass:accepted&&before.hp===60&&JSON.stringify(before)===JSON.stringify(pause)&&prehit.hp===60&&hit.hp===24});
      }
      return {negativeIgnored,rows};
    }''')
    (p/'clock-diagnostic.json').write_text(json.dumps(data,indent=2),encoding='utf8')
    failures=[x for x in data['rows'] if not x['pass']]
    print(json.dumps({'negativeIgnored':data['negativeIgnored'],'trials':len(data['rows']),'failures':failures}),flush=True)
    assert data['negativeIgnored'] and not failures
    browser.close()
