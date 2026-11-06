waves = '''25|20,red
 15|30,red
 15|20,red|5,blue
 15|30,red|15,blue
 15|5,red|25,blue
 15|15,red|15,blue|4,green
 15|20,red|25,blue|5,green
 15|10,red|20,blue|14,green
 15|30,green
 15|102,blue
 15|10,red|10,blue|12,green|2,yellow
 15|15,blue|10,green|5,yellow
 15|100,red|23,green|4,yellow
 15|49,red|15,blue|10,green|9,yellow
 15|20,red|12,green|5,yellow|3,pink
 15|20,green|7,yellow|4,pink
 15|7,yellow
 15|70,green
 15|10,green|4,yellow|5,yellow|6,pink
 15|6,black
 15|14,pink
 15|7,white
 15|5,black|4,white
 15|1,green+
 15|31,yellow
 15|23,pink|4,lead
 10|120,red|55,blue|45,green|45,yellow
 15|4,lead
 15|25,yellow|12,pink
 15|9,lead
 15|8,zebra|2,zebra
 15|25,black|28,white|8,lead
 25|20,yellow+
 15|140,yellow|5,zebra
 15|35,pink|25,white|5,rainbow
 15|81,pink
 15|20,black|20,white|7,white+|15,lead|10,zebra
 15|42,pink|17,white|14,lead|10,zebra|4,rainbow
 15|10,black|10,white|20,lead|20,zebra|18,rainbow
 15|10,rainbow|4,ceramic
 15|60,black|60,zebra
 15|6,rainbow+|6,rainbow
 15|10,rainbow|7,ceramic
 15|50,zebra
 10|200,pink|8,lead|25,rainbow
 15|1,moab
 15|70,pink+|12,ceramic
 10|120,pink|50,rainbow
 10|343,green|20,zebra|20,rainbow|10,rainbow|18,ceramic
 20|20,red|8,lead|20,ceramic|2,moab
 15|10,rainbow|28,ceramic
 15|25,rainbow|10,ceramic|2,moab
 15|80,pink+|3,moab
 15|35,ceramic|2,moab
 15|45,ceramic|1,moab
 15|40,rainbow|1,moab
 15|40,rainbow|4,moab
 15|29,ceramic|5,moab
 17|28,lead+|50,ceramic
 15|1,bfb
'''.strip()

import pyperclip

bloon_types = [
	["red",1/2,192,1,[],[],1,1],
	["blue",1.5/2,192,1,[1],[[8,12],[14,13],[2,1]],1,2],
	["green",1.8/2,192,1,[2],[[8,11],[14,4],[2,3]],1,3],
	["yellow",3.2/2,192,1,[3],[[8,10],[14,7],[2,9]],1,4],
	["pink",1.8/2,192,1,[4],[[8,14],[14,7]],1,5],
	["black",1.8/2,192,1,[4,4,5,5],[[8,0]],1,11],
	["white",2/2,192,1,[4,4,5,5],[[8,7],[14,5],[2,6]],1,11],
	["zebra",3/2,193,1,[6,7],[[5,0]],1,23],
	["lead",1.8/2,194,1,[6,6],[],1,23],
	["rainbow",2.2/2,195,1,[8],[],1,47],
	["ceramic",2.5/2,196,1,[10,10],[],10,104],
	["moab",1/2,204,2,[11,11,11,11],[],200,616,True],
	["bfb",0.34/2,236,2,[12,12,12,12],[],700,3164,True],
]

maps = [
	[28,[-1,6],[3,6],[3,4],[6,4],[6,10],[1,10],[1,14],[11,14],[11,6],[16,6]],
	[48,[-1,9],[8,9],[8,11],[13,11],[13,7],[7,7],[7,4],[4,4],[4,7],[0,7],[0,2],[11,2],[11,4],[14,4],[14,0]],
	[54,[-1,14],[6,14],[6,11],[5,11],[5,9],[8,9],[8,12],[11,12],[11,6],[9,6],[9,9],[15,9],[15,4],[6,4],[6,5],[4,5],[4,0]],
	[191,[4,0],[4,10],[9,10],[9,5],[8,5],[4,5],[4,10],[9,10],[9,5],[8,5],[4,5],[4,15],[4,15]],
	[28,[5,15],[5,12],[3,12],[3,10],[2,10],[2,2],[6,2],[6,3],[14,3],[14,13],[13,13],[13,14],[8,14],[8,15]]
]

# replace waves with proper waves
new = ""
for wave in waves.split("\n"):
	bloons = []
	parts = wave.split("|")
	speed = parts.pop(0)
	for item in parts:
		p = item.split(",")
		amt = p[0]
		ty = p[1]
		camo = False
		if ty.endswith("+"):
			ty = ty[:len(ty)-1]
			camo = True

		# resolve name to index
		for idx,bt in enumerate(bloon_types):
			if bt[0] == ty:
				ty = idx+1
				break
		if isinstance(ty, str):
			print(f"bad entry: {repr(ty)}")
			exit(1)

		if camo:
			ty = str(ty+100)
		bloons.append(f"{amt},{ty}")
	new += f"{speed}|{'|'.join(bloons)}\n"
waves = new[:len(new)-1]

# encode bloon_types to WLF:
# s,i,s,h,ST,dmg,6060,EPF,UPT
bloon_types_wlf = ""
for bt in bloon_types:
	bt = bt[1::]
	if len(bt) <= 7:
		bt.append(False)
	bloon_types_wlf += f" {bt[0]}|1,{bt[1]}|1,{bt[2]}|1,{bt[5]}|1,{bt[6]}"
	for st in bt[3]:
		bloon_types_wlf += f"|1,{st}"
	bloon_types_wlf += f"|1,6060"
	for st in bt[4]:
		bloon_types_wlf += f"|1,{st[0]}|1,{st[1]}"
	bloon_types_wlf += "\n"

bloon_types_wlf = bloon_types_wlf[:-1]

# encode maps data to WLF:
# gnd,EX,UY

maps_wlf = ""
for d in maps:
	print((len(d)-1)*2)
	maps_wlf += f" {d[0]}"
	for pt in d[1::]:
		maps_wlf += f"|1,{pt[0]}|1,{pt[1]}"
	maps_wlf += "\n"

maps_wlf = maps_wlf[:-1]

text = f'''--game data raw
waves = load_wlf([[{waves}]])
bloon_types = load_wlf([[{bloon_types_wlf}]])
maps = load_wlf([[{maps_wlf}]])'''

print(text)
pyperclip.copy(text)
print("\n(copied to clipboard)")
