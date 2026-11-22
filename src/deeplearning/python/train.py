import argparse
import json
import time

import numpy as np
import torch
import torch.nn as nn
from torch.utils.data import DataLoader

from classes import CLASS_NAMES, NUM_CLASSES, IGNORE_INDEX
from dataset import CamVidDataset
from model import build_model


def confusion(pred, target, n=NUM_CLASSES):
    valid = target != IGNORE_INDEX
    idx = target[valid] * n + pred[valid]
    return torch.bincount(idx, minlength=n * n).reshape(n, n)


def metrics(conf):
    conf = conf.astype(np.float64)
    tp = np.diag(conf)
    with np.errstate(divide="ignore", invalid="ignore"):
        iou = tp / (conf.sum(0) + conf.sum(1) - tp)  
    return {"pixel_acc": float(tp.sum() / conf.sum()),
            "miou": float(np.nanmean(iou)),
            "iou": [None if np.isnan(v) else float(v) for v in iou]}


@torch.no_grad()
def evaluate(model, loader, device):
    model.eval()
    conf = torch.zeros(NUM_CLASSES, NUM_CLASSES, dtype=torch.long)
    for x, y in loader:
        pred = model(x.to(device))["out"].argmax(1).cpu()
        conf += confusion(pred, y)
    return metrics(conf.numpy())


def compute_class_weights(ds):
    counts = np.zeros(NUM_CLASSES, dtype=np.float64)
    for i in range(len(ds)):
        lbl = ds.load_label(i)
        counts += np.bincount(lbl[lbl != IGNORE_INDEX].ravel(), minlength=NUM_CLASSES)
    p = counts / counts.sum()
    return torch.tensor(1.0 / np.log(1.02 + p), dtype=torch.float32)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--data_dir", required=True)
    ap.add_argument("--arch", default="resnet50", choices=["resnet50", "mobilenet"])
    ap.add_argument("--epochs", type=int, default=30)
    ap.add_argument("--batch_size", type=int, default=4) 
    ap.add_argument("--lr", type=float, default=1e-3)     
    ap.add_argument("--backbone_lr_mult", type=float, default=0.1)  
    ap.add_argument("--height", type=int, default=360)
    ap.add_argument("--width", type=int, default=480)
    ap.add_argument("--workers", type=int, default=2)
    ap.add_argument("--class_weights", action="store_true")
    ap.add_argument("--out", default="camvid_deeplabv3.pth")
    args = ap.parse_args()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print("Device:", device)
    size = (args.height, args.width)

    train_ds = CamVidDataset(args.data_dir, "train", size, augment=True)
    val_ds = CamVidDataset(args.data_dir, "val", size)
    test_ds = CamVidDataset(args.data_dir, "test", size)
    print(f"train={len(train_ds)} val={len(val_ds)} test={len(test_ds)}")

    train_dl = DataLoader(train_ds, args.batch_size, shuffle=True, drop_last=True,
                          num_workers=args.workers, pin_memory=True)
    val_dl = DataLoader(val_ds, 4, num_workers=args.workers)
    test_dl = DataLoader(test_ds, 4, num_workers=args.workers)

    model = build_model(args.arch, pretrained=True).to(device)

    weight = compute_class_weights(train_ds).to(device) if args.class_weights else None
    if weight is not None:
        print("Class weights:", dict(zip(CLASS_NAMES, weight.cpu().numpy().round(2))))
    criterion = nn.CrossEntropyLoss(weight=weight, ignore_index=IGNORE_INDEX)

    optimizer = torch.optim.AdamW([
        {"params": model.backbone.parameters(), "lr": args.lr * args.backbone_lr_mult},
        {"params": model.classifier.parameters(), "lr": args.lr},
    ], weight_decay=1e-4)
    max_it = args.epochs * len(train_dl)
    sched = torch.optim.lr_scheduler.LambdaLR(optimizer, lambda it: (1 - it / max_it) ** 0.9)

    use_amp = device.type == "cuda"
    scaler = torch.cuda.amp.GradScaler(enabled=use_amp)

    best, history = -1.0, []
    for epoch in range(1, args.epochs + 1):
        model.train()
        t0, total = time.time(), 0.0
        for x, y in train_dl:
            x, y = x.to(device), y.to(device)
            optimizer.zero_grad(set_to_none=True)
            with torch.cuda.amp.autocast(enabled=use_amp):
                loss = criterion(model(x)["out"], y)
            scaler.scale(loss).backward()
            scaler.step(optimizer)
            scaler.update()
            sched.step()
            total += loss.item()

        val = evaluate(model, val_dl, device)
        avg = total / len(train_dl)
        history.append({"epoch": epoch, "loss": avg, "val_miou": val["miou"],
                        "val_acc": val["pixel_acc"]})
        print(f"Epoch {epoch:3d}/{args.epochs}  loss={avg:.4f}  "
              f"val_mIoU={val['miou']:.4f}  val_acc={val['pixel_acc']:.4f}  "
              f"({time.time() - t0:.0f}s)")

        if val["miou"] > best:  
            best = val["miou"]
            torch.save({"model": model.state_dict(), "arch": args.arch,
                        "height": args.height, "width": args.width,
                        "classes": CLASS_NAMES, "epoch": epoch, "val_miou": best},
                       args.out)

    ck = torch.load(args.out, map_location=device)
    model.load_state_dict(ck["model"])
    test = evaluate(model, test_dl, device)
    print(f"\nTEST  mIoU={test['miou']:.4f}  pixel_acc={test['pixel_acc']:.4f}")
    for name, v in zip(CLASS_NAMES, test["iou"]):
        print(f"  {name:11s} IoU = {'n/a' if v is None else f'{v:.4f}'}")

    with open(args.out + ".log.json", "w") as f:
        json.dump({"history": history, "test": test, "args": vars(args)}, f, indent=2)


if __name__ == "__main__":
    main()