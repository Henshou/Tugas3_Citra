
import argparse
import sys
import time

import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image

from classes import colorize
from dataset import MEAN, STD
from model import build_model


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--weights", required=True)
    ap.add_argument("--image", required=True)
    ap.add_argument("--out_label", required=True)
    ap.add_argument("--out_color", required=True)
    ap.add_argument("--out_overlay", required=True)
    ap.add_argument("--device", default="auto", choices=["auto", "cpu", "cuda"])
    ap.add_argument("--alpha", type=float, default=0.5)
    args = ap.parse_args()

    if args.device == "auto":
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    else:
        device = torch.device(args.device)

    t0 = time.time()
    ck = torch.load(args.weights, map_location="cpu")
    model = build_model(ck["arch"], pretrained=False)   # tanpa unduh bobot ImageNet/COCO
    model.load_state_dict(ck["model"])
    model.to(device).eval()

    img = Image.open(args.image).convert("RGB")
    W, H = img.size
    inp = img.resize((ck["width"], ck["height"]), Image.BILINEAR)
    x = torch.from_numpy(np.asarray(inp, dtype=np.float32) / 255.0).permute(2, 0, 1)
    mean = torch.tensor(MEAN).view(3, 1, 1)
    std = torch.tensor(STD).view(3, 1, 1)
    x = ((x - mean) / std).unsqueeze(0).to(device)

    with torch.inference_mode():
        logits = model(x)["out"]
        logits = F.interpolate(logits, size=(H, W), mode="bilinear", align_corners=False)
        label = logits.argmax(1)[0].cpu().numpy().astype(np.uint8)

    color = colorize(label)
    overlay = (args.alpha * color + (1 - args.alpha) * np.asarray(img)).astype(np.uint8)

    Image.fromarray(label, mode="L").save(args.out_label)
    Image.fromarray(color).save(args.out_color)
    Image.fromarray(overlay).save(args.out_overlay)
    print(f"OK device={device} time={time.time() - t0:.2f}s")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:           # pesan jelas untuk ditampilkan di MATLAB
        print(f"ERROR: {type(e).__name__}: {e}", file=sys.stderr)
        sys.exit(1)