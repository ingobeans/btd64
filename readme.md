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

# Todo

- Add options to change monkey targetting (code already exists, just need to make UI options for it)
- More maps (new maps don't take up any tokens so there's a lot of space for more)
- Improve saves (can only save the first 59 monkeys, and it uses a lot of tokens)
- Add sound effects & music (none so far)

# Data

Data is loaded in my proprietary WLF format (weird line format). `data_to_wlf.py` compiles the `waves_data`, `bloon_types`, and `maps` from python arrays to WLF.
