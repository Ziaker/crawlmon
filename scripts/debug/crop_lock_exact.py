from PIL import Image

main = Image.open('level_up_hud_main_capture.png')
# From inspect_left_col: LeftCol pos=(0, 0), AdvanceLockNotice pos=(0, 531) inside LeftCol.
# LeftCol in window: X=0 to 420 (or relative to ContentArea).
# ContentArea pos=(0, 50).
# So AdvanceLockNotice is at X=0, Y=50+531 = 581!
# Size: 420 x 32 -> X=0..420, Y=581..613!
lock_exact = main.crop((0, 575, 430, 620))
lock_exact.save('C:/Users/zerke/.gemini/antigravity/brain/46602981-5c4d-4b7f-bad5-df456d718436/lock_exact.png')
print("Saved lock_exact.png (size: 430x45)")
