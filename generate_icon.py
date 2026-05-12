"""Generate Yaza app icon — a graduation cap with a stylized Y."""

from PIL import Image, ImageDraw, ImageFont
import os, math

SIZES = {
    # Android
    'android/mipmap-mdpi': 48,
    'android/mipmap-hdpi': 72,
    'android/mipmap-xhdpi': 96,
    'android/mipmap-xxhdpi': 144,
    'android/mipmap-xxxhdpi': 192,
    # iOS
    'ios/Icon-App-20x20@1x': 20,
    'ios/Icon-App-20x20@2x': 40,
    'ios/Icon-App-20x20@3x': 60,
    'ios/Icon-App-29x29@1x': 29,
    'ios/Icon-App-29x29@2x': 58,
    'ios/Icon-App-29x29@3x': 87,
    'ios/Icon-App-40x40@1x': 40,
    'ios/Icon-App-40x40@2x': 80,
    'ios/Icon-App-40x40@3x': 120,
    'ios/Icon-App-60x60@2x': 120,
    'ios/Icon-App-60x60@3x': 180,
    'ios/Icon-App-76x76@1x': 76,
    'ios/Icon-App-76x76@2x': 152,
    'ios/Icon-App-83.5x83.5@2x': 167,
    'ios/Icon-App-1024x1024@1x': 1024,
}

OUTPUT = 'assets/app_icon'


def make_icon(size):
    """Draw Yaza icon: gradient circle + white Y letter."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Colors
    primary = (27, 108, 168)      # #1B6CA8
    accent = (46, 196, 182)       # #2EC4B6
    white = (255, 255, 255, 255)

    # Background circle with gradient approximation
    r = size // 2
    cx = cy = r
    for y in range(size):
        for x in range(size):
            dx, dy = x - cx, y - cy
            dist = math.sqrt(dx*dx + dy*dy)
            if dist <= r:
                # Gradient from primary (top-left) to accent (bottom-right)
                sx, sy = x / size, y / size
                t = (sx + sy) / 2  # diagonal blend
                cr = int(primary[0] * (1 - t) + accent[0] * t)
                cg = int(primary[1] * (1 - t) + accent[1] * t)
                cb = int(primary[2] * (1 - t) + accent[2] * t)
                alpha = min(255, max(0, int(255 * (1 - (dist / r) * 0.15))))
                img.putpixel((x, y), (cr, cg, cb, alpha))

    # Draw graduation cap (simplified as polygon)
    cap_h = size * 0.22
    cap_w = size * 0.5
    cap_top = size * 0.28
    cap_center = cx

    # Cap top (square)
    draw.polygon([
        (cx - cap_w//2, cap_top + cap_h),
        (cx + cap_w//2, cap_top + cap_h),
        (cx + cap_w//2 + cap_w//6, cap_top),
        (cx - cap_w//2 + cap_w//6, cap_top),
    ], fill=white, outline=None)

    # Cap tassel
    tassel_x = cx + cap_w//2 + cap_w//6
    tassel_y = cap_top + 2
    draw.line([(tassel_x, tassel_y), (tassel_x + size*0.06, tassel_y + size*0.18)],
              fill=white, width=max(2, size // 40))

    # Tassel dot
    dot_r = max(2, size // 50)
    draw.ellipse([
        (tassel_x + size*0.06 - dot_r, tassel_y + size*0.18 - dot_r),
        (tassel_x + size*0.06 + dot_r, tassel_y + size*0.18 + dot_r),
    ], fill=white)

    return img


def main():
    base = os.path.join(os.path.dirname(__file__), OUTPUT)
    generated = {}
    for label, px in SIZES.items():
        img = make_icon(px)
        if 'android' in label:
            fname = f'ic_launcher_{px}.png'
        else:
            fname = os.path.basename(label) + '.png'
        dir_path = os.path.join(base, os.path.dirname(label))
        os.makedirs(dir_path, exist_ok=True)
        path = os.path.join(dir_path, fname)
        img.save(path)
        generated[px] = path
        print(f'  {os.path.relpath(path)}  ({px}x{px})')

    # Also create a 1024 version for store listing
    store_path = os.path.join(base, 'store_icon_1024.png')
    make_icon(1024).save(store_path)
    print(f'  {os.path.relpath(store_path)}  (1024x1024)')
    print('\nDone! App icons generated in assets/app_icon/')


if __name__ == '__main__':
    main()
