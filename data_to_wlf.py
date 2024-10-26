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
	[44,[-1,9],[8,9],[8,11],[13,11],[13,7],[7,7],[7,4],[4,4],[4,7],[0,7],[0,2],[11,2],[11,4],[14,4],[14,0]]
]

# encode bloon_types to WLF:
# s,i,s,h,ST,6060,EPF,UPT
bloon_types_wlf = ""
for bt in bloon_types:
	if len(bt) <= 6:
		bt.append(False)
	bloon_types_wlf += f"	{bt[0]}|1,{bt[1]}|1,{bt[2]}|1,{bt[5]}"
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
	maps_wlf += f"	{d[0]}"
	for pt in d[1::]:
		maps_wlf += f"|1,{pt[0]}|1,{pt[1]}"
	maps_wlf += "\n"

maps_wlf = maps_wlf[:-1]

print(f"bloon_types = load_wlf([[\n{bloon_types_wlf}\n]])")
print(f"maps = load_wlf([[\n{maps_wlf}\n]])")

