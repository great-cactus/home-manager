"""Register CUDO (Color Universal Design Organization) colors in matplotlib.

Usage:
    import cudo  # noqa: F401
    ax.plot(x, y, color="cudo:red")  # case-insensitive: "CUDO:red" also works
"""

import matplotlib.colors as mcolors

# Same order as the color cycle in cudo-paper.mplstyle (C0..C8).
CUDO = {
    "red": "#FF4B00",
    "blue": "#005AFF",
    "green": "#03AF7A",
    "purple": "#990099",
    "orange": "#F6AA00",
    "brown": "#804000",
    "sky": "#4DC4FF",
    "pink": "#FF8082",
    "yellow": "#FFF100",
}

_mapping = mcolors.get_named_colors_mapping()
for _name, _hex in CUDO.items():
    # Item assignment (not dict.update) so matplotlib clears its color cache.
    _mapping[f"cudo:{_name}"] = _hex
