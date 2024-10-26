# btd64

A Pico-8 demake of Bloons Tower Defense (5).
The code is really unreadable because of all the dumb techniques used to cram as much gameplay in to 8000 tokens.

# Data

Data is loaded in my proprietary WLF format (weird line format). `data_to_wlf.py` compiles the `waves_data`, `bloon_types`, and `maps` from python arrays to WLF.
