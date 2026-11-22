import os
import random
import numpy as np
import torch
from PIL import Image
from torch.utils.data import Dataset
from torchvision import transforms as T

from classes import rgb_to_label

MEAN = (0.485, 0.456, 0.406) 
STD = (0.229, 0.224, 0.225)


class CamVidDataset(Dataset):
    def __init__(self, root, split, size=(360, 480), augment=False):
        self.img_dir = os.path.join(root, split)
        self.lbl_dir = os.path.join(root, split + "_labels")
        if not os.path.isdir(self.img_dir) or not os.path.isdir(self.lbl_dir):
            raise FileNotFoundError(f"Folder '{split}' / '{split}_labels' tidak ditemukan di {root}")
        self.files = sorted(f for f in os.listdir(self.img_dir)
                            if f.lower().endswith((".png", ".jpg", ".jpeg")))
        self.size = size
        self.augment = augment
        self.jitter = T.ColorJitter(brightness=0.3, contrast=0.3, saturation=0.3)
        self.to_tensor = T.Compose([T.ToTensor(), T.Normalize(MEAN, STD)])

    def __len__(self):
        return len(self.files)

    def _label_path(self, fname):
        base = os.path.splitext(fname)[0]
        for cand in (base + "_L.png", base + ".png"):
            p = os.path.join(self.lbl_dir, cand)
            if os.path.exists(p):
                return p
        raise FileNotFoundError(f"Label untuk {fname} tidak ditemukan")

    def load_label(self, i):
        rgb = np.asarray(Image.open(self._label_path(self.files[i])).convert("RGB"))
        return rgb_to_label(rgb)

    def __getitem__(self, i):
        img = Image.open(os.path.join(self.img_dir, self.files[i])).convert("RGB")
        lbl = Image.fromarray(self.load_label(i), mode="L")

        if self.augment:
            w, h = img.size
            s = random.uniform(0.6, 1.0)
            cw, ch = int(w * s), int(h * s)
            x, y = random.randint(0, w - cw), random.randint(0, h - ch)
            img = img.crop((x, y, x + cw, y + ch))
            lbl = lbl.crop((x, y, x + cw, y + ch))
            if random.random() < 0.5:                      
                img = img.transpose(Image.FLIP_LEFT_RIGHT)
                lbl = lbl.transpose(Image.FLIP_LEFT_RIGHT)
            img = self.jitter(img)                        

        h, w = self.size
        img = img.resize((w, h), Image.BILINEAR)
        lbl = lbl.resize((w, h), Image.NEAREST)             
        return self.to_tensor(img), torch.from_numpy(np.array(lbl, dtype=np.int64))