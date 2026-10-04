"""Prepare the supplied chroma-screen portraits; never overwrite originals."""
import argparse
import json
import sys
from pathlib import Path

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--dependency-dir", type=Path)
parser.add_argument("--preview-dir", type=Path)
args = parser.parse_args()
if args.dependency_dir:
    sys.path.insert(0, str(args.dependency_dir))

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets/portraits"
# Original-image mask-face boxes, used only for common optical scale/position.
FACES = {"player": (815, 165, 1395, 865), "curator": (810, 90, 1190, 550)}
portraits = []
report = []
for name, (left, top, right, bottom) in FACES.items():
    source = Image.open(ROOT / "assets/exp" / f"{name}.jpg").convert("RGB")
    rgb = np.asarray(source).astype(np.float32)
    red, green, blue = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    chroma = np.minimum(red - green, blue - green)
    alpha = np.clip((160.0 - chroma) / 100.0, 0.0, 1.0)
    labels, _ = ndimage.label(alpha > 0.1)
    counts = np.bincount(labels.ravel())
    counts[0] = 0
    main = labels == counts.argmax()
    alpha *= main
    # JPEG can leave dark magenta spill in otherwise opaque boundary pixels.
    # Only touch a narrow outline, retaining interior colors and green rim light.
    edge = (ndimage.distance_transform_edt(main) <= 4) | (alpha < 1.0)
    spill = np.where(edge, np.maximum(0.0, np.minimum(red, blue) - green), 0.0)
    rgb[:, :, 0] -= spill
    rgb[:, :, 2] -= spill
    rgb[alpha == 0] = 0
    rgba = np.dstack((np.clip(rgb, 0, 255), alpha * 255)).astype(np.uint8)
    cutout = Image.fromarray(rgba)
    reference_scale = source.width / 2000.0
    scale = 300.0 / ((bottom - top) * reference_scale)
    resized = cutout.resize((round(source.width * scale), round(source.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (640, 512))
    offset = (round(320 - (left + right) * 0.5 * reference_scale * scale), round(76 - top * reference_scale * scale))
    canvas.alpha_composite(resized, offset)
    pixels = np.array(canvas)
    # Both source busts end below the mask. Match their low edge without a hard
    # rectangular torso seam on the desktop or the black introductory stage.
    fade = np.clip((480.0 - np.arange(512)) / 36.0, 0.0, 1.0)
    pixels[:, :, 3] = (pixels[:, :, 3] * fade[:, None]).astype(np.uint8)
    pixels[pixels[:, :, 3] == 0, :3] = 0
    canvas = Image.fromarray(pixels)
    canvas.save(OUTPUT / f"{name}.png", optimize=True)
    portraits.append(canvas)
    report.append({"character": name, "source": source.size, "canvas": canvas.size,
                   "removed_pixels": int((~main).sum()), "alpha_bounds": canvas.getbbox()})

portraits[0].crop((128, 32, 512, 416)).resize((256, 256), Image.Resampling.LANCZOS).save(OUTPUT / "player-icon.png", optimize=True)
if args.preview_dir:
    for label, color in [("black", (7, 13, 20, 255)), ("teal", (55, 109, 112, 255))]:
        sheet = Image.new("RGBA", (1280, 512), color)
        for i, portrait in enumerate(portraits):
            sheet.alpha_composite(portrait, (i * 640, 0))
        sheet.convert("RGB").save(args.preview_dir / f"portraits-{label}.webp", quality=92)
print(json.dumps(report, indent=2))
