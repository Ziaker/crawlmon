from pathlib import Path
from playwright.sync_api import sync_playwright
import json
p=Path(__file__).parent
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='C:/Users/zerke/AppData/Local/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-win64/chrome-headless-shell.exe',headless=True,args=['--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    page=browser.new_page(viewport={'width':1440,'height':900},device_scale_factor=1)
    errors=[]
    page.on('pageerror',lambda e:errors.append(str(e)))
    page.on('console',lambda e: errors.append(e.text) if e.type=='error' else None)
    page.goto((p/'atelier.html').as_uri())
    page.wait_for_timeout(1000)
    print('BOOT',errors)
    page.screenshot(path=str(p/'initial.png'))
    if not errors:
        page.evaluate('atelier.state.paused=true')
        for i in range(8):
            page.evaluate('(id)=>{atelier.state.paused=false;atelier.cast(id);atelier.state.paused=true;}',i)
            page.evaluate('for(let j=0;j<111;j++)atelier.step(1/120)')
            page.wait_for_timeout(60)
            page.screenshot(path=str(p/f'move-{i}.png'))
            page.evaluate('for(let j=111;j<360;j++)atelier.step(1/120)')
            page.wait_for_timeout(40)
            print('MOVE',i,page.evaluate('({busy:!!atelier.current,particles:atelier.sessions.reduce((n,s)=>n+s.vfx.activeParticlesCount,0)})'),errors[-3:])
        page.evaluate('for(let i=0;i<1200;i++)atelier.step(1/120)')
        print('CLEANUP',page.evaluate('({sessions:atelier.sessions.length,queue:atelier.timeline.queue.length,memory:atelier.renderer.info.memory})'))
        for actor,target,size in [(1,2,.65),(2,0,1.6),(2,1,1)]:
            page.evaluate('([a,t,s])=>{atelier.select(a,t);atelier.actors[t].model.root.scale.setScalar(s);}',[actor,target,size])
            for i in range(8):
                page.evaluate('(id)=>{atelier.state.paused=false;atelier.cast(id);atelier.state.paused=true;for(let j=0;j<111;j++)atelier.step(1/120);}',i)
                page.wait_for_timeout(35)
                if i in [1,5]:page.screenshot(path=str(p/f'mirror-{actor}-{target}-{i}.png'))
                page.evaluate('for(let j=111;j<400;j++)atelier.step(1/120)')
                assert page.evaluate('atelier.current===null'),(actor,target,i,'busy')
            print('PARTICIPANTS',actor,target,size,'8 moves',errors[-2:])
        for mode in ['dual','retarget']:
            page.evaluate('(mode)=>{atelier.setClones(true);atelier.select(2,0);atelier.state.mode=mode;atelier.state.paused=false;atelier.cast(5);atelier.state.paused=true;}',mode)
            page.evaluate('for(let j=0;j<130;j++)atelier.step(1/120)')
            page.wait_for_timeout(50)
            page.screenshot(path=str(p/f'splitter-{mode}.png'))
            page.evaluate('for(let j=130;j<1000;j++)atelier.step(1/120)')
            print('SPLITTER',mode,page.evaluate('atelier.actors.map(a=>a.hp)'),errors[-2:])
        page.evaluate('for(let j=0;j<1200;j++)atelier.step(1/120)')
        print('FINAL',page.evaluate('({sessions:atelier.sessions.length,queue:atelier.timeline.queue.length,memory:atelier.renderer.info.memory})'))
    (p/'test-results.json').write_text(json.dumps({'errors':errors},indent=2),encoding='utf8')
    browser.close()
