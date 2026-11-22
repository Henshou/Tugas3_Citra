import torch.nn as nn
from torchvision.models import segmentation as seg

from classes import NUM_CLASSES


def build_model(arch="resnet50", pretrained=True):
    if arch == "resnet50":
        fn = seg.deeplabv3_resnet50
        weights = seg.DeepLabV3_ResNet50_Weights.DEFAULT
    elif arch == "mobilenet":
        fn = seg.deeplabv3_mobilenet_v3_large
        weights = seg.DeepLabV3_MobileNet_V3_Large_Weights.DEFAULT
    else:
        raise ValueError(f"arch tidak dikenal: {arch}")

    if pretrained:
        model = fn(weights=weights)
        in_ch = model.classifier[4].in_channels
        model.classifier[4] = nn.Conv2d(in_ch, NUM_CLASSES, kernel_size=1)
    else:
        model = fn(weights=None, weights_backbone=None,
                   num_classes=NUM_CLASSES, aux_loss=False)

    model.aux_classifier = None  
    return model