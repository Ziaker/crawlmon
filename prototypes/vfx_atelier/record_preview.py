"""Record the existing HTML for inspection; this is NOT a Godot validation."""
from pathlib import Path
from playwright.sync_api import sync_playwright
import subprocess, imageio_ffmpeg
p=Path(__file__).parent
with sync_playwright() as pw:
    browser=pw.chromium.launch(executable_path='C:/Users/zerke/AppData/Local/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-win64/chrome-headless-shell.exe',headless=True,args=['--use-angle=swiftshader','--enable-unsafe-swiftshader'])
    context=browser.new_context(viewport={'width':1440,'height':900},record_video_dir=str(p/'recording'),record_video_size={'width':1440,'height':900})
    page=context.new_page()
    page.goto((p/'atelier.html').as_uri())
    page.wait_for_function('window.atelier')
    page.evaluate("document.getElementById('btn-toggle-sfx').click();const l=document.createElement('div');l.id='record-label';l.style='position:fixed;right:22px;top:80px;z-index:100;color:white;background:#081622;padding:10px;font:16px monospace';document.body.append(l)")
    for actor,target,label in [(0,2,'HTML · Vista normal'),(2,0,'HTML · Vista espelhada')]:
        page.evaluate('([a,t,label])=>{atelier.select(a,t);document.getElementById("record-label").textContent=label;}',[actor,target,label])
        for move in range(8):
            page.evaluate('(id)=>{atelier.actors.forEach(a=>{a.hp=a.maxHp;a.burnRemaining=0;a.model.burnTint=0;});atelier.cast(id);}',move)
            page.wait_for_function('!atelier.current',timeout=20000)
            page.wait_for_timeout(350)
            print(label,move,flush=True)
    video=page.video
    context.close()
    source=video.path()
    browser.close()
subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-y','-i',str(source),'-an','-c:v','libx264','-crf','23','-pix_fmt','yuv420p','-movflags','+faststart',str(p/'preview-normal-espelhado.mp4')],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
print('Saved preview-normal-espelhado.mp4')
