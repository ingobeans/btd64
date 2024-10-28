import pyperclip

waves = '''
 25|20,1
 15|30,1
 15|20,1|5,2
 15|30,1|15,2
 15|5,1|25,2
 15|15,1|15,2|4,3
 15|20,1|25,2|5,3
 15|10,1|20,2|14,3
 15|30,3
 15|102,2
 15|10,1|10,2|12,3|2,4
 15|15,2|10,3|5,4
 15|100,1|23,3|4,4
 15|49,1|15,2|10,3|9,4
 15|20,1|12,3|5,4|3,5
 15|20,3|7,4|4,5
 15|7,4
 15|70,3
 15|10,3|4,4|5,4|6,5
 15|6,6
 15|14,5
 15|7,7
 15|5,6|4,7
 15|1,3c
 15|31,4
 15|23,5|4,9
 10|120,1|55,2|45,3|45,4
 15|4,9
 15|25,4|12,5
 15|9,9
 15|8,8|2,8
 15|25,6|28,7|8,9
 25|20,4c
 15|140,4|5,8
 15|35,5|25,7|5,10
 15|81,5
 15|20,6|20,7|7,7c|15,9|10,8
 15|42,5|17,7|14,9|10,8|4,10
 15|10,6|10,7|20,9|20,8|18,10
 15|10,10|4,11
 15|60,6|60,8
 15|6,10c|6,10
 15|10,10|7,11
 15|50,8
 10|200,5|8,9|25,10
 15|1,12
 15|70,5c|12,11
 10|120,5|50,10
 10|343,3|20,8|20,10|10,10|18,11
 20|20,1|8,9|20,11|2,12
 15|10,10|28,11
 15|25,10|10,11|2,12
 15|80,5c|3,12
 15|35,11|2,12
 15|45,11|1,12
 15|40,10|1,12
 15|40,10|4,12
 15|29,11|5,12
 17|28,9c|50,11
 15|1,13
'''

bloon_types = [
	#red 1
	[1/2,192,1,[],[],1],
	#blue 2
	[1.5/2,192,1,[1],[[8,12],[14,13],[2,1]],1],
	#green 3
	[1.8/2,192,1,[2],[[8,11],[14,4],[2,3]],1],
    #yellow 4
	[3.2/2,192,1,[3],[[8,10],[14,7],[2,9]],1],
    #pink 5
	[1.8/2,192,1,[4],[[8,14],[14,7]],1],
    #black 6
	[1.8/2,192,1,[4,4,5,5],[[8,0]],1],
    #white 7
	[2/2,192,1,[4,4,5,5],[[8,7],[14,5],[2,6]],1],
    #zebra 8
	[3/2,193,1,[6,7],[[5,0]],1],
    #lead 9
	[1.8/2,194,1,[6,6],[],1],
    #rainbow 10
	[2.2/2,195,1,[8],[],1],
    #ceramic 11
	[2.5/2,196,1,[10,10],[],10],
    #moab
	[1/2,204,2,[11,11,11,11],[],200,True],
    #bfb
	[0.34/2,236,2,[12,12,12,12],[],700,True],
]

maps = [
	[28,[-1,6],[3,6],[3,4],[6,4],[6,10],[1,10],[1,14],[11,14],[11,6],[16,6]],
	[48,[-1,9],[8,9],[8,11],[13,11],[13,7],[7,7],[7,4],[4,4],[4,7],[0,7],[0,2],[11,2],[11,4],[14,4],[14,0]],
	[54,[-1,14],[6,14],[6,11],[5,11],[5,9],[8,9],[8,12],[11,12],[11,6],[9,6],[9,9],[15,9],[15,4],[6,4],[6,5],[4,5],[4,0]],
	[191,[4,0],[4,10],[9,10],[9,5],[8,5],[4,5],[4,10],[9,10],[9,5],[8,5],[4,5],[4,15],[4,15]]
]

# encode bloon_types to WLF:
# s,i,s,h,ST,6060,EPF,UPT
bloon_types_wlf = ""
for bt in bloon_types:
	if len(bt) <= 6:
		bt.append(False)
	bloon_types_wlf += f" {bt[0]}|1,{bt[1]}|1,{bt[2]}|1,{bt[5]}"
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
bloon_types = load_wlf([[\n{bloon_types_wlf}\n]])
maps = load_wlf([[\n{maps_wlf}\n]])'''

print(text)
pyperclip.copy(text)
print("\n(copied to clipboard)")