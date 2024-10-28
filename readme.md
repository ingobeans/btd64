# btd64

![image](https://github.com/user-attachments/assets/94e71171-8fef-4a14-ad83-da31fee5db06)

A Pico-8 demake of Bloons Tower Defense (5).
The code is really unreadable because of all the dumb techniques used to cram as much gameplay in to 8000 tokens.

# Features

- 8 different monkeys from BTD5
- Two upgrade paths, each with three upgrades
- Automatically game saves after each round
- The first 60 waves from BTD5
- Three maps
- UI tooltips
- Monkey upgrade information (press left/right in upgrade menu to show/hide upgrade desc)
- Monkey targeting options

# Todo

- More maps (new maps don't take up any tokens so there's a lot of space for more)
- Add music
- Fix sniper monkey randomly looking in the wrong direction when firing

# Saving

Game saves after each round, saving lives, round, cash, map index and the first 62 monkeys.

### Save Structure

Index 0 stores:

- Map index (first 4 bits),
- Lives (the following 8 bits)
- Round (the following 8 bits)

Index 1 stores cash

All following entries store a monkey, i.e. indices 2-63.

Monkey data is formatted like:

- Monkey type index (first 4 bits)
- Monkey X (following 4 bits)
- Monkey Y (following 4 bits)
- Monkey upgrade index path 1 (following 4 bits)
- Monkey upgrade index path 2 (following 4 bits)
- Monkey targeting (following 4 bits)

# Data

Data is loaded in my proprietary WLF format (weird line format). `data_to_wlf.py` compiles the `waves_data`, `bloon_types`, and `maps` from python arrays to WLF.
