import numpy as np

CLASS_NAMES = ["Sky", "Building", "Pole", "Road", "Pavement", "Tree",
               "SignSymbol", "Fence", "Car", "Pedestrian", "Bicyclist"]
NUM_CLASSES = len(CLASS_NAMES)
IGNORE_INDEX = 255

PALETTE = np.array([
    (128, 128, 128),  # Sky
    (128, 0, 0),      # Building
    (192, 192, 128),  # Pole
    (128, 64, 128),   # Road
    (60, 40, 222),    # Pavement
    (128, 128, 0),    # Tree
    (192, 128, 128),  # SignSymbol
    (64, 64, 128),    # Fence
    (64, 0, 128),     # Car
    (64, 64, 0),      # Pedestrian
    (0, 128, 192),    # Bicyclist
], dtype=np.uint8)


ORIGINAL_CLASSES = {
    "Animal":           ((64, 128, 64),  "Pedestrian"),
    "Archway":          ((192, 0, 128),  "Building"),
    "Bicyclist":        ((0, 128, 192),  "Bicyclist"),
    "Bridge":           ((0, 128, 64),   "Building"),
    "Building":         ((128, 0, 0),    "Building"),
    "Car":              ((64, 0, 128),   "Car"),
    "CartLuggagePram":  ((64, 0, 192),   "Pedestrian"),
    "Child":            ((192, 128, 64), "Pedestrian"),
    "Column_Pole":      ((192, 192, 128), "Pole"),
    "Fence":            ((64, 64, 128),  "Fence"),
    "LaneMkgsDriv":     ((128, 0, 192),  "Road"),
    "LaneMkgsNonDriv":  ((192, 0, 64),   "Road"),
    "Misc_Text":        ((128, 128, 64), "SignSymbol"),
    "MotorcycleScooter": ((192, 0, 192), "Bicyclist"),
    "OtherMoving":      ((128, 64, 64),  "Car"),
    "ParkingBlock":     ((64, 192, 128), "Pavement"),
    "Pedestrian":       ((64, 64, 0),    "Pedestrian"),
    "Road":             ((128, 64, 128), "Road"),
    "RoadShoulder":     ((128, 128, 192), "Pavement"),
    "Sidewalk":         ((0, 0, 192),    "Pavement"),
    "SignSymbol":       ((192, 128, 128), "SignSymbol"),
    "Sky":              ((128, 128, 128), "Sky"),
    "SUVPickupTruck":   ((64, 128, 192), "Car"),
    "TrafficCone":      ((0, 0, 64),     "Pole"),
    "TrafficLight":     ((0, 64, 64),    "SignSymbol"),
    "Train":            ((192, 64, 128), "Car"),
    "Tree":             ((128, 128, 0),  "Tree"),
    "Truck_Bus":        ((192, 128, 192), "Car"),
    "Tunnel":           ((64, 0, 64),    "Building"),
    "VegetationMisc":   ((192, 192, 0),  "Tree"),
    "Wall":             ((64, 64, 64),   "Building"),
    "Void":             ((0, 0, 0),      None),
}

_LUT = None


def _build_lut():       
    lut = np.full(256 ** 3, IGNORE_INDEX, dtype=np.uint8)
    for rgb, group in ORIGINAL_CLASSES.values():
        if group is None:
            continue
        key = (rgb[0] << 16) | (rgb[1] << 8) | rgb[2]
        lut[key] = CLASS_NAMES.index(group)
    return lut


def rgb_to_label(rgb):
    global _LUT
    if _LUT is None:
        _LUT = _build_lut()
    rgb = rgb.astype(np.int64)
    key = (rgb[..., 0] << 16) | (rgb[..., 1] << 8) | rgb[..., 2]
    return _LUT[key]


def colorize(label):
    out = np.zeros(label.shape + (3,), dtype=np.uint8)
    valid = label < NUM_CLASSES
    out[valid] = PALETTE[label[valid]]
    return out