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
      const a=atelier;a.state.paused=false;a.state.speed=1;a.cast(6);
      const start=a.timeline.time;
      a.advanceReal(.4);a.state.speed=.25;a.advanceReal(1.6);
      const before={time:a.timeline.time-start,hp:a.actors[2].hp};
      a.state.paused=true;a.advanceReal(10);
      const pause={time:a.timeline.time-start,hp:a.actors[2].hp};
      a.state.paused=false;a.state.speed=.5;a.advanceReal(.54);
      const prehit={time:a.timeline.time-start,hp:a.actors[2].hp};
      a.advanceReal(.06);
      const hit={time:a.timeline.time-start,hp:a.actors[2].hp};
      a.state.paused=true;
      return {before,pause,prehit,hit};
    }''')
    print(json.dumps(data),flush=True)
    (p/'clock-results.json').write_text(json.dumps(data,indent=2),encoding='utf8')
    assert data['before']['hp']==60 and data['pause']==data['before']
    assert data['prehit']['hp']==60 and data['hit']['hp']==24
    assert abs(data['hit']['time']-1.1)<.01
    (p/'clock-results.json').write_text(json.dumps(data,indent=2),encoding='utf8')
    print(json.dumps(data))
    browser.close()
