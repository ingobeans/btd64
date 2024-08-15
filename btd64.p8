pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--game data

map_pts = {{-1,6},{3,6},{3,4},{6,4},{6,10},{1,10},{1,14},{11,14},{11,6},{16,6}}
gnd = 28 --ground tile
wtr = 31 --water tile
gnd_clr = 3
lead_id = 9

sell_percent = 0.8
waves_data = [[
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
 15|120,1|55,2|45,3|45,4
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
 15|200,5|8,9|25,10
 15|1,12
 15|70,5c|12,11
 15|120,5|50,10
 15|343,3|20,8|20,10|10,10|18,11
 20|20,1|8,9|20,11|2,12
 15|10,10|28,11
 15|25,10|10,11|2,12
 15|80,5c|3,12
 15|35,11|2,12
 15|45,11|1,12
 15|40,10|1,12
 15|40,10|4,12
 15|29,11|5,12
 15|28,9c|50,11
]]

--raw wave data
lines = split(waves_data,"\n")
waves = {}
for k,l in pairs(lines) do
	if k != #lines then
		local d = split(l,"|")
		local w = {d[1]}
		for i,c in pairs(d) do
			if i != 1 then
				local vs = split(c,",")
				local cbt = vs[2]
				--if data has q at end,
				--make camo
				if type(vs[2]) == "string" and sub(vs[2],-1,nil) == "c" then
					cbt = tonum(sub(vs[2],1,#vs[2]-1)+100)
				end
				for b=1,vs[1] do
					add(w,cbt)
				end
			end
		end
		add(waves,w)
	end
end

function _init()
	def_monkeys()
end

-->8
--game

round = 38
playing = false
spawning = true
spwn_index = 2
spwn_timer = 0

slowc = 0
slowdown = 0
gspd = 1

entered_menu = false

function start_round()
	round += 1
	playing = true
	spawning = true
	spwn_index = 2
	spwn_timer = 0
end

function spwn_bloons()
	if playing and spawning then
		spwn_timer -= gspd
		if spwn_timer <= 0 then
			spwn_timer = waves[round][1]
			t = waves[round][spwn_index]
			sx = map_pts[1][1]*8
			sy = map_pts[1][2]*8
			spwn_bloon({sx,sy},t)
			spwn_index += 1
			if spwn_index > #waves[round] then
				spawning = false
			end
		end
	elseif playing then
		if #bloons == 0 then
			cash += 100
			playing = false
		end
	end
end

function main()
	player_input()
	mv_bloons()
	
	cls(gnd_clr)
	map()
	
	draw_bloons()
	update_monkeys()
	update_proj()
	
	draw_cursor()
	draw_ui()
	draw_tooltip()
	draw_particles()
	empty_bloons_buffer()
	spwn_bloons()
	--perf_o(0,12)
end

function _update()
	if btn(❎) and btn(🅾️) and false then
		slowdown = 5
	else
		slowdown = 0
	end
	if slowc == 0 then
		main()
		slowc = slowdown
	else
		slowc -= 1
	end
end
-->8
--bloons

--speed,img,size,{splits to},{{color from,color to}},health,moab

bloon_types = {
	--red 1
	{1/2,192,1,{},{},1},
	--blue 2
	{1.5/2,192,1,{1},{{8,12},{14,13},{2,1}},1},
	--green 3
	{1.8/2,192,1,{2},{{8,11},{14,4},{2,3}},1},
  --yellow 4
	{3.2/2,192,1,{3},{{8,10},{14,7},{2,9}},1},
  --pink 5
	{1.8/2,192,1,{4},{{8,14},{14,7}},1},
  --black 6
	{1.8/2,192,1,{4,4,5,5},{{8,0}},1},
  --white 7
	{2/2,192,1,{4,4,5,5},{{8,7},{14,5},{2,6}},1},
  --zebra 8
	{3/2,193,1,{6,7},{{5,0}},1},
  --lead 9
	{1.8/2,194,1,{6,6},{},1},
  --rainbow 10
	{2.2/2,195,1,{8},{},1},
  --ceramic 11
	{2.5/2,196,1,{10,10},{},10},
  --moab
	{1/2,204,2,{},{},700,true},
}

bloons = {}

bloons_buffer = {}
function empty_bloons_buffer()
	for k,v in pairs(bloons_buffer) do
		spwn_bloon(v[1],v[2],v[3],v[4],v[5],v[6],v[7])
	end
	bloons_buffer = {}
end

function confuse_bloon(b,amt)
	amt = amt or 1
	if amt > b.pt then
		amt = b.pt
	end
	if b.pt > 0 and amt > 0 then
		b.cnf = b.pt
		for i=1,amt do
			b.s -= b.ptss[b.pt-i+1]
		end
		b.pt -= amt
	end
end

function pop_bloon(bi,pp,pmom,plead)
	b = bloons[bi]
	if b == nil then
		return
	end
	bt = btype(b.t)
	if b.t == lead_id and plead != true then
		return
	end
	if bt[6] != 1 then
		if b.h > 1 then
			m = 1
			if bt[7] == true then
				m = pmom
			end
			b.h -= pp*m
			
			if b.h > 1 then
				return
			end
		end
	end
	for k,v in pairs(bt[4]) do
		if k >= pp then
			p = {b.p[1], b.p[2]}
			add(bloons_buffer,{
			 p,v,bi,b.pt,b.s,b.ptss,b.cnf
			})
		end
	end
	cash += 1
	del(bloons,b)
end

function bloons_at(pos)
	b = {}
	x = pos[1]
	y = pos[2]
	for k,v in pairs(bloons) do
		cx = v.p[1]
		cy = v.p[2]
		if x > cx and x < cx+8 and
				 y > cy and y < cy+8 then
			add(b,{v,k})
		end
	end
	return b
end

function btype(t)
	if t > 100 then
  return bloon_types[t-100]
	end
	return bloon_types[t]
end

function spwn_bloon(pos,t,id,pt,s,ptss,cnf)
	id = id or #bloons + 1
	pt = pt or 1
	ptss = ptss or {0}
	cnf = cnf or false
	s = s or 0
	add(bloons, {
		p=pos, --pos
		t=t, --type
		pt=pt, --point target
		s=s, --score
		ptss=ptss, --point scores 
		cnf=cnf, --confused
		h=btype(t)[6], --health
		lmd={0,0}
	})
end

function draw_bloons()
	--h = nil
	for k,v in pairs(bloons) do
		bt = btype(v.t)
		img = bt[2]
		if v.t > 100 then
			img += 16
		end
		bs = bt[3]
		pcs = bt[5]
		bmxh = bt[6]
		
		if bmxh != 1 then
			if v.h < bmxh / 2 then
				img += bs
			end
		end
		
		for k,c in pairs(pcs) do
			pal(c[1], c[2])
		end
		
		--if moab, calculate angle
		--of move, and draw rotated
		if bt[7] == true then
			print(v.h,v.p[1]+12,v.p[2],0)
			--normalise move dir
			md = sqrt(abs(v.lmd[1])^2+abs(v.lmd[2])^2)
			
			mnx = v.lmd[1]/md
			mny = v.lmd[2]/md
			a = atan2(mny,mnx)+0.25
			spr_r(img, v.p[1]-4, v.p[2]-4, a, bs, bs)
		else
			spr(img, v.p[1], v.p[2], bs, bs)
		end
		--if h == nil or v.s > h[1] then
		--	h = {v.s,{v.p[1],v.p[2]}}
		--end
		pal()
	end
	--if h != nil then
	--	spr(64, h[2][1], h[2][2])
	--	print(h[1],h[2][1], h[2][2])
	--end
end

function mv_bloons()
	for k,v in pairs(bloons) do
		--if flr(v.p[1]/8) == crsr[1] and
		--			flr(v.p[2]/8) == crsr[2] then
		--	confuse_bloon(v)
		--end
		mv = {0,0}
		pt = map_pts[v.pt]
		spd = btype(v.t)[1]*gspd
		next_pt = map_pts[v.pt+1]
		dix = v.p[1]-next_pt[1]*8
		diy = v.p[2]-next_pt[2]*8
		ma = 0
		
		if dix < 0 then
			mv[1] = min(spd,-dix)
		elseif dix > 0 then
			mv[1] = -min(spd,dix)
		end
		if diy < 0 then
			mv[2] = min(spd,-diy)
		elseif diy > 0 then
			mv[2] = -min(spd,diy)
		end
		
		nx = v.p[1] + mv[1]
		ny = v.p[2] + mv[2]
		ma = abs(mv[1]) + abs(mv[2])
		
		--give no score if confused
		if v.cnf == false then
			v.s += ma
			v.ptss[v.pt] += ma
		end
		v.p = {nx, ny}
		v.lmd = mv
		
		if nx/8 == next_pt[1] and
					ny/8 == next_pt[2] do
			v.pt += 1
			v.ptss[v.pt] = 0
			if v.cnf == v.pt then
				v.cnf = false
			end
			if v.pt >= #map_pts then
				lives -= #btype(v.t)[4]+1
				del(bloons,v)
			end
		end
	end
end
-->8
--player

cash = 650 *10*5
lives = 100
crsr = {8,8}

function monkey_at(pos)
	for k,v in pairs(monkeys) do
		if pos[1] == v.p[1]-4 and
					pos[2] == v.p[2]-4 then
			return v,k
		end
	end
	return false,false
end

function player_input()
	if in_menu == -1 then
		mv_crsr()
		if btnp(🅾️) then
			if placing != -1 then		
				placing = -1
			else
				menu_crsr = 0
				in_menu = 0
				entered_menu = true
			end
		elseif btnp(❎) and placing == -1 then
			crp = {crsr[1]*8,crsr[2]*8}
			
			m,i = monkey_at(crp)
			if m != false then
				menu_crsr = 0
				in_menu = i
				entered_menu = true
			end
		elseif btnp(❎) and valid then
			mt = monkey_types[placing]
			cash -= mt.c
			spwn_monkey({crsr[1]*8+4,crsr[2]*8+4},placing)
			placing = -1
		end
	else
		if btnp(🅾️) then
			in_menu = -1
		end
	end
end

function mv_crsr()
	if btnp(⬅️) do
		crsr[1] -= 1
	elseif btnp(➡️) do
		crsr[1] += 1
	end
	if btnp(⬆️) do
		crsr[2] -= 1
	elseif btnp(⬇️) do
		crsr[2] += 1
	end
	
	if crsr[1] < 0 do
		crsr[1] = 15
	elseif crsr[1] > 15  do
		crsr[1] = 0
	end
	if crsr[2] < 1 do
		crsr[2] = 15
	elseif crsr[2] > 15 do
		crsr[2] = 1
	end
end
-->8
--ui

-- -1 none
-- 0 build
-- <monkey id> upgrade
in_menu = -1
menu_crsr = 0

-- -1 none
-- <monkey id> placing
placing = -1
valid = true

--in upgrade menu
extra_info = false

function rectborder(x1,y1,x2,y2,clr1,clr2)
	rectfill(x1,y1,x2,y2,clr1)
	rect(x1,y1,x2,y2,clr2)
end

function draw_tooltip()
	rectfill(0,120,127,127,0)
	
	o = "menu"
	x = false
	l = false
	r = false
	if in_menu != -1 then
		o = "exit"
		x = "select"
		if in_menu != 0 then
			if extra_info then
				r = "show less"
			else
				l = "show more"
			end
		end
	elseif placing != -1 then
		o = "exit"
		x = "confirm"
	else
		if monkey_at({crsr[1]*8,crsr[2]*8}) != false then
			x = "select"		
		end
	end
	
	print("🅾️ "..o,0,121,7)
	if x != false then
		print("❎ "..x,8*4,121,7)
	end
	if l != false then
		print("⬅️ "..l,8*4+10*4,121,7)
	end
	if r != false then
		print("➡️ "..r,8*4+10*4,121,7)
	end
end

function mv_menu_crsr()
	if btnp(⬆️) then
		menu_crsr -= 1
	elseif btnp(⬇️) then
		menu_crsr += 1
	end
	mx = 2
	if in_menu == 0 then
		mx = #monkey_types+1
	end
	if menu_crsr < 0 then
		menu_crsr = mx
	elseif menu_crsr > mx then
		menu_crsr = 0
	end
end

function menu_input()
	mv_menu_crsr()
	if in_menu == 0 then
		if btnp(❎) then
			if menu_crsr == 0 then
				if not playing then
					start_round()
				end
			elseif menu_crsr == 1 then
				if gspd == 1 then
					gspd = 3
				else
					gspd = 1
				end
			else
				mt = monkey_types[menu_crsr-1]
				if cash > mt.c then
					in_menu = -1
					placing = menu_crsr-1
				end
			end
	 end
	else
		m = monkeys[in_menu]
		if btnp(❎) then
			if menu_crsr == 2 then
				cash += flr(m.vl*sell_percent+0.5)
				in_menu = -1
				del(monkeys,m)
			else
				u = nil
				if menu_crsr == 0 then
					if m.ui2 < 4 or m.ui1 != 3 then
						u = m.u1[m.ui1]
					end
				else
					if m.ui1 < 4 or m.ui2 != 3 then
						u = m.u2[m.ui2]
					end
				end
				if u != nil then
					if cash >= u[1] then
						if menu_crsr == 0 then
							m.ui1 += 1
						else
							m.ui2 += 1
						end
						cash -= u[1]
						m.vl += u[1]
						u[4](m)
					end
				end
			end
		elseif btnp(⬅️) then
			extra_info = true
		elseif btnp(➡️) then
			extra_info = false
		end
	end
end

function draw_menu()
	w = 48
	rectborder(128-w,0,127,127,4,15)
	if in_menu == 0 then
		if not playing then
			rectfill(129-w,1,126,10,12)
			print("start round",130-w,2,15)
		else
			rectfill(129-w,1,126,10,1)
			print("start round",130-w,2,5)
		end
		rectborder(128-w,10,127,20,12,15)
		print("speed "..gspd.."x",130-w,12,15)
		--draw monkey buttons
		for k,v in pairs(monkey_types) do
			rectfill(128-w,k*10+10,128-w+9,20+k*10,0)
			rect(128-w,k*10+10,127,20+k*10,15)
			draw_base_monkey(k,{129-w,k*10+11})
			print("$"..v.c,128-w+12,k*10+12,15)
		end
		spr(64,128-w-8,menu_crsr*10)
	else
		m = monkeys[in_menu]
		rectfill(129-w,1,126,9,0)
		print("upgrade",129-w+12,2,7)
		draw_base_monkey(m.ti,{129-w,1})
		
		--draw upgrade buttons
		buttons = {m.u1[m.ui1],m.u2[m.ui2]}
		

		--lock upgrade paths
		--by setting button to 0
		if m.ui1 >= 4 and m.ui2 == 3 then
			buttons[2] = 0
		elseif m.ui2 >= 4 and m.ui1 == 3 then
			buttons[1] = 0
		end

		--nil gets skipped in
		--pair loops so we flag
		--nil values by 1
		if	buttons[1] == nil then
			buttons[1] = 1
		end
		if buttons[2] == nil then
			buttons[2] = 1
		end
		
		for k,v in pairs(buttons) do
			if v == 0 then
				rect(128-w,k*10,127,10+k*10,15)
				spr(80,130-w+3,k*10+2)
				print("locked",128-w+12+3,k*10+2,15)
				if extra_info then
					rectborder(0,k*10,128-w,k*10+10,4,15)
					print("path is locked",0+2,k*10+2,15)
				end
			elseif v == 1 then
				rect(128-w,k*10,127,10+k*10,15)
				print("max upg.",128-w+2+3,k*10+2,15)
				if extra_info then
					rectborder(0,k*10,128-w,k*10+10,4,15)
					print("all upgrades",0+2,k*10+2,15)
				end
			else
				rectfill(128-w+3,k*10,128-w+9+3,10+k*10,0)				
				rect(128-w,k*10,127,10+k*10,15)
				spr(v[2],130-w+3,k*10+2)
				print("$"..v[1],128-w+12+3,k*10+2,15)
				if extra_info then
					rectborder(0,k*10,128-w,k*10+10,4,15)
					print(v[3],0+2,k*10+2,15)
				end
			end
		end
		
		--draw upgrade progress
		for k,v in pairs({m.ui1,m.ui2}) do
			for i=1,3 do
				c = 3
				
				--if upgrade is bought
				if 4-i<v then
					c = 11
				end 
				
				rectfill(129-w,k*10+i*3-3+1,128-w+3,k*10+i*3,c)
			end
		end
		
		rectborder(128-w,30,127,40,8,15)
		print("sell $"..flr(m.vl*sell_percent+0.5),130-w,32,15)
		
		spr(64,128-w-8,menu_crsr*10+10)
	end
	if entered_menu == false then
		menu_input()
	else
		entered_menu = false
	end
end

function draw_cursor()
	clr = 7
	if placing != -1 then
		valid = true
		if monkey_types[placing].wb == false then
			if mget(crsr[1],crsr[2]) != gnd then
				valid = false
			end
		else
			if mget(crsr[1],crsr[2]) != wtr then
				valid = false
			end
		end
		if valid then
			for k,v in pairs(monkeys) do
				if v.p[1]-4 == crsr[1]*8 and
							v.p[2]-4 == crsr[2]*8 then
					valid = false
				end
			end
		end
		if not valid then
			clr = 8
		end
		mt = monkey_types[placing]
		draw_base_monkey(placing,{crsr[1]*8,crsr[2]*8})
		circ(crsr[1]*8+4,crsr[2]*8+4,mt.r*8,0)
	end
	rect(crsr[1]*8-1, crsr[2]*8-1, crsr[1]*8+8, crsr[2]*8+8, clr)
end

function draw_ui()
	draw_topbar()
	if in_menu != -1 then
		draw_menu()
	end
end

function draw_topbar()
	rectfill(0,0,128,8,0)
	round_clr = 7
	if playing then
		round_clr = 8
	end
	print("round "..round,0,0,round_clr)
	print("$"..cash,52,0,10)
	print("♥"..lives,108,0,8)
end
-->8
--monkeys data

monkey_types = {}

function new_mk(t)
	base = {
		p={0,0},	--pos
		cs={{}}, --color states
		ccs=1,	--current color state
		vl=0,	--value
		c=200,--cost
		wb=false, --water bound
		camo=false, --camo
		tgt=0, --target (0 first, 1 strong, 2 near, 3 last)
		i=1, --sprite
		trac=14, --transparency colour
		r=2.5, --range
		proji=1, --current proj index
		projs={base_proj},
		adc=0, --attack delay counter
		tg=0, --targeting
		lar={0,-1}, --last attack dir
		u1={}, --upgrade path 1
		u2={}, --upgrade path 2
		ui1=1, --upgrade index 1
		ui2=1 --upgrade index 2
	}
	b = merge(base,t)
	b.vl = b.c
	b.ti = #monkey_types+1
	add(monkey_types, b)
	return b
end

function merge(b,n)
	local m = deep(b)
	for k,v in pairs(n) do
		if b[k] != nil then
			if type(v) == "table" then
				m[k] = merge(b[k],n[k])
			else
				m[k] = n[k]
			end
		else
			m[k] = v
		end
	end
	return m
end	

function def_monkeys()
	base_proj = {
		a = reg_attack, --atack func
		amt=1, --times to loop proj
		ad=27, --attack delay
		ps=4, --proj speed
		pp=1, --proj pop power
		phm=false, --proj homing
		pr=1, --proj pierce
		pdf=dp_dart, --proj draw func
		pl=10, --proj lifetime
		pvr=1, --proj variant
		pmom=1, --proj moab dmg multi
		phfn=nil, --proj hit func
		pshfn=nil, --post shoot func
		plead=false,	--lead
	}

	dart = new_mk({
		cs={
			{{8,4}},
			{{8,11}},
			{}
		},
		u1={
			{90,65,"long range",function (this)
				this.r = 2.9
				this.ccs=max(2,this.ccs)
			end},
			{120,66,"longer range",function (this)
				this.r = 3.4
				this.ccs=max(3,this.ccs)
				this.camo = true
			end},
			{500,67,"spikeball",function (this)
				this.projs[1].pr += 17
				this.projs[1].ad = 46
				this.projs[1].ps = 2
				this.projs[1].pl = 65
				this.projs[1].pdf = dp_spikeball
				this.i = 16
			end}
		},
		u2={
			{140,81,"sharp darts",function (this)
				this.projs[1].pr += 1
				this.projs[1].pl += 5
				this.ccs=max(2,this.ccs)
			end},
			{170,82,"sharper darts",function (this)
				this.projs[1].pr += 2
				this.projs[1].pl += 5
				this.ccs=max(3,this.ccs)
			end},
			{330,83,"triple darts",function (this)
				this.ccs = 3
				this.i = 17
				this.projs[1].paof = 15
				this.projs[1].a = triple_attack
			end}
		}
	})
	
	tack_shtr = new_mk({
		u1={
			{210,97,"fast shoot",function (this)
				this.projs[1].ad -= 2
			end},
			{300,98,"faster shoot",function (this)
				this.projs[1].ad -= 2
				this.i = max(18, this.i)
			end},
			{2500,99,"ring of fire",function (this)
				this.i = 33
				this.projs[1].a = rof_attack
			end},
		},
		u2={
			{100,113,"long range",function (this)
				this.r = 1.8
			end},
			{225,114,"longer range",function (this)
				this.r = 2.2
				this.i = max(18, this.i)
			end},
			{680,115,"blade shooter",function (this)
				this.i = 34
				this.projs[1].pdf = dp_blade
				this.projs[1].pr += 7
				this.projs[1].ad -= 1
			end},
		},
		i=2,
		r=1.4,
		trac=12,
		projs={{
			pl=6,
			ad=18,
			a=tack_attack
		}},
	})
	sniper = new_mk({
		cs={
			{{12,11}},
			{},
			{{12,2}},
			{{12,0}},
		},
		u1={
			{350,71,"pop 4 layers, lead", function (this)
				this.ccs = max(2,this.ccs)
				this.projs[1].plead = true
				this.projs[1].pp += 2
			end},
			{2200,72,"pop 7 layers!", function (this)
				this.ccs = max(3,this.ccs)
				this.projs[1].pp += 3
			end},
			{4000,73,"18 dmg (full cer)", function (this)
				this.ccs = 4
				this.projs[1].pp += 11
			end},
		},
		u2={
			{400,87,"faster firing", function (this)
				this.ccs = max(2,this.ccs)
				this.projs[1].ad /= 1.4
			end},
			{300,88,"camo goggles", function (this)
				this.camo = true
				this.i = max(24,this.i)
			end},
			{3500,89,"3x fire rate", function (this)
				this.projs[1].ad /= 3
				this.i = 25
				this.ccs = 2
			end},
		},
		projs={{
			pr=1,
			pp=2,
			ad=66,
			plead=false,
			pmom=5,
			a=sniper_attack,
		}},
		i=8,
		c=350,
		r=1.4,
	})
	ninja = new_mk({
		cs={
			{{10,4}},
			{{10,5},{8,7}},
			{{10,7},{8,5}},
			{{10,12},{8,5}},
			{{10,14},{8,7}},
			{{10,8},{8,7}},
			{{10,8},{8,5}},
		},
		u1={
			{300,68,"large range,faster",function(this)
				this.r = 3.2
				this.ad = 12
				this.ccs=max(2,this.ccs)
			end},
			{300,69,"sharp shurikens",function(this)
				this.pr = 3
				this.ccs=max(5,this.ccs)
			end},
			{850,70,"double shot",function(this)
				this.projs[1].amt = 2
				this.ccs=6
			end}
		},
		u2={
			{250,84,"seeking shuriken",function(this)
				this.projs[1].phm = true
				this.projs[1].pl += 10
				this.ccs=max(3,this.ccs)
			end},
			{350,85,"distraction",function(this)
				this.ccs=max(4,this.ccs)
				this.projs[1].phfn = ph_stun
			end},
			{2750,86,"flash bomb",function(this)
				this.ccs=7
				np = merge(base_proj,{
					ad=0,
					pstnc=100,
					phfn=ph_flash_bmb
				})
				this.projs[1].ad = 18
				this.projs[1].amt = 4
				this.projs[2] = np
			end}
		},
		i=3,
		c=500,
		projs={{ --first proj
			amt=1,		--shuriken
			ad=2,
			ps=6,
			pr=2,
			a=reg_attack,
			pdf=dp_shuriken,
			pstnc=15, --proj stun chance
		},
			{ad=16,a=0} --second proj
		},							--only delay
		r=2.9,
		camo=true
	})
	bomb_shtr = new_mk({
		cs={
			{{8,5},{9,5},{1,5}},
			{{9,5},{1,5}},
			{{9,8},{1,5}},
			{{5,11},{9,11},{8,11},{1,10}},
			{{12,6}},
			{{5,3},{6,11},{12,6}}
		},
		u1={
			{200,77,"large range",function (this)
				this.r += 0.3
				this.ccs=max(2,this.ccs)
			end},
			{300,78,"frag bombs",function (this)
				this.ccs=max(3,this.ccs)
				this.projs[1].pfrag = true
			end},
			{800,79,"cluster bombs",function (this)
				this.ccs=max(4,this.ccs)
				this.projs[1].pfragbmb = true
				if this.i != 4 then
					this.ccs=6
				end
			end}
		},
		u2={
			{400,93,"bigger bombs",function (this)
				this.projs[1].pvr = 2
				this.projs[1].pp = 2
				this.projs[1].pbr = 12

				this.ccs=max(2,this.ccs)
			end},
			{400,94,"missile launcher",function (this)
				this.projs[1].pvr = 3
				this.projs[1].pp = 4
				this.r += 0.1
				this.projs[1].ad -= 0.4
				this.projs[1].ps += 3
				this.ccs=max(3,this.ccs)
				this.ccs += 2
				this.i = 20
			end},
			{900,95,"moab mauler",function (this)
				this.projs[1].pvr = 4
				this.projs[1].pmom = 10
				this.i = 36
			end}
		},
		i=4,
		c=650,
		projs={{
			ad=33,
			ps=2,
			pbr=8,
			pl=20,
			phfn=ph_bomb,
			pdf=dp_bomb,
			pfrag=false,
			pfragbmb=false,
			pbig=false,
		}},
		r=3
	})
	buccaneer = new_mk({
		cs={
			{{14,2}},
			{}
		},
		u1={
			{400,103,"faster shooting", function (this)
				this.projs[1].ad *= 0.75
			end},
			{180,104,"longer range", function (this)
				this.ccs = max(2, this.ccs)
				this.i = max(26,this.i)
				this.r = 4.5
			end},
			{2200,105,"destroyer", function (this)
				this.ccs = 2
				this.i = 42
				for _,p in pairs(this.projs) do
					p.ad /= 5
				end
				this.projs[1].amt = 5
			end},
		},
		u2={
			{500,119,"grape shot", function (this)
				this.ccs = max(2, this.ccs)
				add(this.projs, merge(base_proj, {
					pdf=dp_grape,
					ad=20,
					paof=50,
					a=triple_attack,
				}))
			end},
			{250,120,"camo sight", function (this)
				this.ccs = max(2, this.ccs)
				this.i = max(26,this.i)			
				this.camo = true	
			end},
			{1200,121,"bomb cannon", function (this)
				this.ccs = 2
				this.i = 58
				add(this.projs, merge(base_proj, {
					ad=0,
					ps=2,
					pbr=8,
					pl=20,
					phfn=ph_bomb,
					pdf=dp_bomb,
					pfrag=false,
					pfragbmb=false,
					pbig=false,
				}))
			end},
		},
		projs={{
			pr=1,
			pp=1,
			ad=30,
			plead=false,
		}},
		i=10,
		r=3.9,
		wb=true,
		trac=12,
	})
	super = new_mk({
		u1={
			{3500,100,"laser blasts",function (this)
				this.i = max(43, this.i)
				this.projs[1].pr += 1
				this.projs[1].pdf = dp_laser
				this.projs[1].a = double_attack
			end},
			{5000,101,"plasma blasts",function (this)
				this.i = max(59, this.i)
				this.projs[1].pr += 1
				this.projs[1].pdf = dp_plasma
				this.projs[1].ad = 1
				this.projs[1].plead = true
				if this.ui2 < 4 then
					this.projs[1].a = reg_attack
				end
			end},
			{16500,102,"sun god",function (this)
				this.i = 60
				this.projs[1].paof = 20
				this.projs[1].a = triple_attack
				this.projs[1].pr = 15
				this.projs[1].pdf = dp_sunbeam
			end},
		},
		u2={
			{1000,116,"super range",function (this)
				this.r += 1
			end},
			{1500,117,"epic range",function (this)
				this.i = max(27, this.i)
				this.r += 1
			end},
			{9000,118,"robo monkey",function (this)
				this.i = 61
				this.projs[1].a = double_attack
				this.projs[1].pr += 2
			end},
		},
		projs={{
			ad=1.7,
			pl=30
		}},
		i=11,
		c=3500,
		r=2.9,
		trac=13,
	})
	apprentice = new_mk({
		cs={
			{}
		},
		u1={
			{300,109,"intense magic",function (this)
				if this.ui2 < 3 then
					this.projs[1].pr += 5
				end
			end},
			{1200,110,"lightning bolt",function (this)
				this.i = max(21,this.i)
				add(this.projs, merge(base_proj, {
					ad=0,
					pdf=0,
					phfn=ph_lightning
				}),1)
			end},
			{2000,111,"summon whirlwind",function (this)
				this.i = 22
				add(this.projs, merge(base_proj, {
					phfn=ph_whirlwind,
					pl=49,
					pr=30,
					pdf=dp_whirlwind,
					anim=0,
					ps=2,
					hit={},
					ad=33,
				}))
			end},
		},
		u2={
			{300,125,"fireball",function (this)
				fpi = 1
				if this.ui1 >= 3 then
					fpi = 2
				end
				this.projs[fpi].amt = 2
				add(this.projs, merge(base_proj, {
					ad=5,
					pdf=dp_fireball,
					phfn=ph_fireball,
					plead=true,
					ps=2,
				}))
			end},
			{300,126,"camo sense",function (this)
				this.camo = true
				this.i = max(21,this.i)
			end},
			{4200,127,"dragon's breath",function (this)
				this.i = 23
				--make reg proj
				del(this.projs, this.projs[#this.projs-1])
				--replace fireball proj
				this.projs[#this.projs] = merge(this.projs[#this.projs], {
					ad = 2,
					pp=1,
					pdf = dp_firebreath,
					plead = true,
					phfn = ph_firebreath,
					amt=32,
					ps=1,
					pl=30,
					pmom=0.7,
				})
			end},
		},
		i=5,
		r=2.9,
		c=550,
		projs={{
			pdf=dp_magic_bolt,
			ps=2,
			pr=2,
			ad=33,
			pl=20,
		}},
	})
end
-->8
--monkeys

monkeys = {}

function update_monkeys()
	for k,v in pairs(monkeys) do
		a = atan2(v.lar[2],v.lar[1])-0.5
		palt(0, false)
		palt(v.trac,true)
		rspr_clear_col = v.trac
		for _,c in pairs(v.cs[v.ccs]) do
			pal(c[1],c[2])
		end
		spr_r(v.i, v.p[1]-4, v.p[2]-4,a,1,1)
		pal()
		palt()
		if crsr[1]*8 == v.p[1]-4 and
					crsr[2]*8 == v.p[2]-4 and 
					placing == -1 then
			circ(v.p[1],v.p[2],v.r*8,0)
		end
		
		if playing then
			if v.adc <= 0 then
				--calculate current proj
				total = 0
				for k,v in pairs(v.projs) do
					if v.amt != nil then
						total += v.amt
					else
						total += 1
					end
				end
				
				local p = nil
				local cpi = 1
				local i = v.proji
				while p == nil do
					local a = v.projs[cpi].amt or 1
					if a >= i then
						p = v.projs[cpi]
						break
					end
					i -= a
					cpi += 1
				end
				--p = current proj
				
				--find bloon in range
				local b,dx,dy,d,k =	bloon_near(v.p,v.r*8,v.tg,v.camo)
				local r = false
				if p.a != 0 then
					r = p.a(v,p,b,dx,dy,d,k)
				end
				if p.a == 0 or r == true then
					--reset
					v.adc = p.ad
					v.proji += 1
					if v.proji > total then
						v.proji = 1
					end
				end
				
				--call proj shoot func
				if v.pshfn != nil then
					v.pshfn(v)				
				end
			end
		end
		if v.adc > 0 then
			v.adc -= gspd
		end
	end
end

function draw_base_monkey(ti,pos)
	mt = monkey_types[ti]
	
	palt(0,false)
	palt(mt.trac,true)
	for _,c in pairs(mt.cs[mt.ccs]) do
		pal(c[1],c[2])	
	end
	spr(mt.i,pos[1],pos[2])
	pal()
	palt()
end

function spwn_monkey(pos,ti)
	n = deep(monkey_types[ti])
	n.p = pos
	add(monkeys,n)
end

function bloons_near(pos,r,camo)
	t = {}
	tx = pos[1]
	ty = pos[2]
	for k,v in pairs(bloons) do
		if v.t > 100 and camo != true then
			goto continue
		end
		x = v.p[1]+4
		y = v.p[2]+4
		dx = (x-tx)
		dy = (y-ty)
		d = sqrt(dx^2+dy^2)
		if d < r then
			add(t,v)
		end
		::continue::
	end
	return t
end

--sort
--0 first
--1 strong
--2 near
--3 last
function bloon_near(pos,r,sort,camo)
	b = {nil,0,0,0,0,0}
	for k,v in pairs(bloons) do
		if v.t > 100 and camo != true then
			goto continue
		end
		x = v.p[1]+4
		y = v.p[2]+4
		tx = pos[1]
		ty = pos[2]
		dx = (x-tx)
		dy = (y-ty)
		d = sqrt(dx^2+dy^2)
		if d < r then
			if sort == 0 then
				s = v.s
			elseif sort == 1 then
				s = v.t
			elseif sort == 2 then
				s = -d
			elseif sort == 3 then
				s = -v.s
			end
			
			if b[1] == nil or s > b[1] then
				b={s,v,dx,dy,d,k}
			end
		end
		::continue::
	end
	return b[2],b[3],b[4],b[5],b[6]
end

function sniper_attack(this)
	--get bloon w. inf range
	b,dx,dy,d,k = bloon_near({64,64},128,this.tg,this.camo)
	pop_bloon(k,this.projs[1].pp,this.projs[1].pmom,this.projs[1].plead)
	this.lar = {dx/d,dy/d}
	spwn_particle(this.p,dpr_sniper_fire,this.lar)
	return true
end

function double_attack(this,p,b,dx,dy,d,k)
	if b != 0 then
		angle_offset = 90/370
		poa = 2
		tx = dx/d
		ty =	dy/d
		ta = atan2(ty,tx)
		
		nox = sin(ta+angle_offset)
		noy = cos(ta+angle_offset)
		pos = {
			{this.p[1]+nox*poa,this.p[2]+noy*poa},
			{this.p[1]-nox*poa,this.p[2]-noy*poa}
		}
		this.lar = {tx,ty}
		
		for k,v in pairs(pos) do
			p = copy(this.projs[1])
			spwn_proj(
				v,
				{tx,ty},
				p
			)
		end
		return true
	end
end

function triple_attack(this,p,b,dx,dy,d,k)
	if b != 0 then
		angle_offset = p.paof/360
		tx = dx/d
		ty =	dy/d
		ta = atan2(ty,tx)
		
		dirs = {
			{tx,ty},
			{sin(ta+angle_offset),cos(ta+angle_offset)},
			{sin(ta-angle_offset),cos(ta-angle_offset)}
		}
		this.lar = {tx,ty}
		for k,v in pairs(dirs) do
			p = copy(p)
			spwn_proj(
				{this.p[1],this.p[2]},
				{v[1],v[2]},
				p
			)
		end
		return true
	end
end

function rof_attack(this,p,b,dx,dy,d,k)
	if b != 0 then
		spwn_particle(this.p, dpr_rof)
		bl = bloons_near(this.p,this.r*8,false)
		for k,v in pairs(bl) do
			bi = indexof(bloons, v)
			pop_bloon(bi,this.projs[1].pp,this.projs[1].pmom,true)
		end
		return true
	end
end

function tack_attack(this,p,b,dx,dy,d,k)
	if b != 0 then
		dirs = {
			{0,1},
			{0,-1},
			{1,0},
			{-1,0},
			{0.7,0.7},
			{0.7,-0.7},
			{-0.7,0.7},
			{-0.7,-0.7}
		}
		for k,v in pairs(dirs) do
			p = copy(this.projs[1])
			spwn_proj(
				{this.p[1],this.p[2]},
				{v[1],v[2]},
				p
			)
		end
		return true
	end
end

function reg_attack(this,p,b,dx,dy,d,k)
	if b != 0 then
		x = this.p[1]
		y = this.p[2]
		mx = dx/d
		my = dy/d
		this.lar = {mx,my}
		spwn_proj(
			{x,y},
			{mx,my},
			p
		)
		return true
	end
end


-->8
--proj

--{x,y},{mx,my},ps,pl,pr,pp,l,cer,lifec,popc
proj = {}

function spwn_proj(pos,mv,mk)
	p = copy(mk)
	p.p = pos
	p.mv = mv
	p.plc = 0
	p.prc = 0
	add(proj,p)
end

function update_proj()
	for k,v in pairs(proj) do
		v.plc += gspd
		removed = false
		
		--loop to repeat in case
		--move direction changes
		repeat_move = true
		while repeat_move do
			repeat_move = false
			tmx = v.mv[1]*v.ps*gspd
			tmy = v.mv[2]*v.ps*gspd
			
			--split the movement of proj
			--to chunks smaller than 5 px
			--for a consistent collision
			--detection
			ttmx = {}
			ttmy = {}
			
   for j=1,gspd do
    add(ttmx, tmx/gspd)
    add(ttmy, tmy/gspd)
			end
			
			for k,csmx in pairs(ttmx) do
				if removed == true then
					break
				end
				csmy = ttmy[k]
				v.p[1] += csmx
				v.p[2] += csmy
				
				bloons_hit = bloons_at(v.p)
				for _,bd in pairs(bloons_hit) do
					b = bd[1]
					bi = bd[2]
					if b != 0 then
						if v.phfn != nil then
							r = v.phfn(v,b)
							--allow proj hit func
							--to block bloon pop
							if r != true then
								pop_bloon(bi,v.pp,v.pmom,v.plead)
							end
						else
							pop_bloon(bi,v.pp,v.pmom,v.plead)
						end
						
						v.prc += 1
						if v.prc == v.pr then
							removed = true
							del(proj,v)
							break
						end
						
					--check if can home
					if v.phm == true then
						b,dx,dy,d,bi = bloon_near(v.p,20,0,v.camo)
						--dont home if very close
						if d > 3 then
							if b != 0 then
								v.mv = {dx/d,dy/d}
								repeat_move = true
								break
							end
						end
					end
				end
				end
			end
		end
		if v.plc >= v.pl and 
					removed == false then
			del(proj,v)
		end
		if v.pdf != 0 then
			v.pdf(v)
		end
	end
end

function dp_dart(p)
	line(p.p[1],p.p[2],p.p[1]+p.mv[1]*2,p.p[2]+p.mv[2]*2,0)
end

function dp_spikeball(p)
	spr(154,p.p[1]-4,p.p[2]-4)
end

function dp_grape(p)
	circfill(p.p[1],p.p[2],1,14)
end

function dp_bomb(p)
	if p.pvr == 1 then
		circfill(p.p[1],p.p[2],1,0)
	elseif p.pvr == 2 then
		circfill(p.p[1],p.p[2],2,0)
	elseif p.pvr == 3 or p.pvr == 4 then
		l = 3
		sx = p.p[1]
		ex = sx+p.mv[1]*l
		sy = p.p[2]
		ey = sy+p.mv[2]*l
		cb = 6
		ct = 8
		if p.pvr == 4 then
			cb = 9
			ct = 10
		end
		line(sx,sy,ex,ey,cb)
		pset(ex,ey,ct)
	end
end

function dp_laser(p)
	line(p.p[1],p.p[2],p.p[1]+p.mv[1]*2,p.p[2]+p.mv[2]*2,8)
end

function dp_plasma(p)
	circfill(p.p[1],p.p[2],2,7)
	circ(p.p[1],p.p[2],2,14)
end

function dp_sunbeam(p)
	x = p.p[1]
	y = p.p[2]
	mx = p.mv[1]
	my = p.mv[2]
	
	--offset proj horizontally
	--for width
	af = 90/360
	ta = atan2(my,mx)
	a = ta+af
	ox = sin(a)*3
	oy = cos(a)*3
	
	--draw proj twice
	--offsetting with mv
	--for length
	
	for i=0,1 do
		line(x-ox+mx*i,y-oy+my*i,x+ox+mx*i,y+oy+my*i,10)
	end
end

function dp_shuriken(p)
	circ(p.p[1],p.p[2],1,0)
end

function dp_magic_bolt(p)
	circfill(p.p[1],p.p[2],1,14)
end

function dp_whirlwind(this)
	x = this.p[1]-8
	y = this.p[2]-8
	this.anim += gspd
	af = (flr(this.anim/5) % 2)*2
	spr(150+af,x,y,2,2)
end

function dp_firebreath(p)
	circfill(p.p[1],p.p[2],2,9)
	circ(p.p[1],p.p[2],2,8)
end

function ph_firebreath(this)
	spwn_particle(this.p,dpr_firebreath_hit)
end

function ph_whirlwind(this,b)
	if indexof(this.hit,b) == nil then
		add(this.hit,b)
		confuse_bloon(b,2)
	else
		--to not make the bloon add
		--t0 pierce counter
		this.prc -= 1
	end
	return true
end

function ph_lightning(this)
	pts = {this.p}
	
	for i=1,30 do
		b,dx,dy,d,k = bloon_near(this.p,32,2,this.camo)
		if b == 0 then
			break
		end
		pop_bloon(k,1,1,true)
		add(pts,b.p)
	end
	
	spwn_particle(this.p,dpr_lightning,pts)
end

function dp_blade(p)
	circfill(p.p[1],p.p[2],1,5)
end

function dp_fireball(p)
	circfill(p.p[1],p.p[2],1,9)
end

function ph_fireball(this)
	spwn_particle(this.p,dpr_small_explosion)
	bls = bloons_near(this.p,8,this.camo)
	for k,v in pairs(bls) do
		pop_bloon(indexof(bloons,v),1,1,true)
	end
end

function ph_flash_bmb(this)
	spwn_particle(this.p,dpr_explosion)
	ph_stun(this)
end

function ph_stun(this)
	rng = rnd(100)
	if rng < this.pstnc then
		bls = bloons_near(this.p,13,this.camo)
		for k,v in pairs(bls) do
			--dont confuse moabs
			--or already confused bloons
			if btype(v.t)[7] == false and 
						v.cnf == false then
				confuse_bloon(v)
			end
		end
	end
end

function ph_bomb(this)
	part = dpr_explosion
	if this.pvr != 1 then
		part = dpr_big_explosion
	end
	spwn_particle(this.p,part)
	bls = bloons_near(this.p,this.pbr,this.camo)
	for k,v in pairs(bls) do
		pop_bloon(indexof(bloons,v),1,1,true)
	end
	--if frag upgrade
	--spawn 4 new bombs
	if this.pfrag == true then
		dirs = {
			{0,1},
			{0,-1},
			{1,0},
			{-1,0}
		}
		for k,v in pairs(dirs) do
			nproj = {
				pl=10,
				pp=1,
				pr=1,
				ps=2,
				pmom=1,
				pdf=dp_bomb,
				phfn=nil,
				pvr=1,
				pfrag=false,
				pbig=false,
				pbr=8,
			}
			if this.pfragbmb == true then
				nproj.phfn = ph_bomb
			end
			spwn_proj(
				{this.p[1],this.p[2]},
				{v[1],v[2]},
				nproj
			)
		end
	end
end
-->8
--functions

--functions disabled because
--unused

--[===[
function dir_to(sp,tp)
	x = sp[1]
	y = sp[2]
	tx = tp[1]
	ty = tp[2]
	dx = x-tx
	dy = y-ty
	d = sqrt(dx^2+dy^2)
	return {dx/d, dy/d}
end

function dump(t,ind)
	--stringify table
	s = ""
	if ind == nil then
		s = s.."{\n"
	end
	local indl = ind or 1
	local	indent = ""
	for i=1,indl do
		indent = indent.." "
	end
	for k,v in pairs(t) do
		if type(v) == "table" then
			s = s..indent..k..":{\n"..dump(v,indl+1)..indent.."}\n"
		elseif type(v) == "string" then
			s = s..indent..k..":\""..tostr(v).."\"\n"
		else
			s = s..indent..k..":"..tostr(v).."\n"
		end
	end
	if ind == nil then
		s = s.."}"
	end
	return s
end

function log(s)
	cls(0)
	cursor(0,0)
	color(7)
	print(s)
	stop()
end

function perf_o(x,y)
	x = x or 0
	y = y or 0
	rectfill(x,y,x+45,y+12,0)
	cursor(x+1,y+1)
	color(7)
	mem = stat(0)
	cpu = stat(1)
	print("mem:"..tostr(flr(mem/2048*100)).."% ("..tostr(flr(mem))..")")
	print("cpu:"..tostr(flr(cpu*100)).."%")
end
--]===]

function spr_r(s,x,y,a,w,h)
	rspr(flr(s%16)*8,flr(s/16)*8,14*8,14*8,a,w)
 sspr(14*8,14*8,8*w,8*w,x,y,8*w,8*w)
end

rspr_clear_col=0

function rspr(sx,sy,x,y,a,w)
	local ca,sa=cos(a),sin(a)
	local srcx,srcy,addr,pixel_pair
	local ddx0,ddy0=ca,sa
	local mask=shl(0xfff8,(w-1))
	w*=4
	ca*=w-0.5
	sa*=w-0.5
	local dx0,dy0=sa-ca+w,-ca-sa+w
	w=2*w-1
	for ix=0,w do
		srcx,srcy=dx0,dy0
		for iy=0,w do
			if band(bor(srcx,srcy),mask)==0 then
				local c=sget(sx+srcx,sy+srcy)
				sset(x+ix,y+iy,c)
			else
				sset(x+ix,y+iy,rspr_clear_col)
			end
			srcx-=ddy0
			srcy+=ddx0
		end
		dx0+=ddx0
		dy0+=ddy0
	end
end

function copy(org)
	t = {}
	for k,v in pairs(org) do
  t[k] = v
	end
	return t
end

function deep(org)
	local t = {}
	for k,v in pairs(org) do
		if type(v) == "table" then
			t[k] = deep(v)
		else
	  t[k] = v			
		end
	end
	return t
end

function indexof(array, value)
	for i, v in ipairs(array) do
		if v == value then
			return i
		end
	end
	return nil
end
-->8
--particles

particles = {}

function	spwn_particle(p,dpr,data)
	data = data or {}
	add(particles, {p,dpr,0,data})
end

function draw_particles()
	for k,v in pairs(particles) do
		v[3] += gspd
		if v[2](v) == true then
			del(particles,v)
		end
	end
end

function dpr_sniper_fire(this)
	if this[3] > 4 then
		return true
	end
	mx = this[4][1]
	my = this[4][2]
	x = this[1][1]
	y = this[1][2]
	l = 8
	line(x,y,x+mx*l,y+my*l,10)
end

function dpr_firebreath_hit(this)
	if this[3] > 4 then
		return true
	end
	si = 182+flr(this[3]/(4/3))
	spr(si,this[1][1]-4,this[1][2]-4)
end

function dpr_lightning(this)
	if this[3] > 7 then
		return true
	end
	pts = this[4]
	for k,v in pairs(pts) do
		np = pts[k+1]
		if np == nil then
			break
		end
		line(v[1],v[2],np[1],np[2],14)
	end
end

function dpr_rof(this)
	if this[3] > 7 then
		return true
	end
	
	for i=1,4 do
		circ(this[1][1], this[1][2], 6+this[3]*1.7-i, 9)
	end
end

function dpr_big_explosion(this)
	if this[3] > 14 then
		return true
	end
	si = 160+flr(this[3]/5)*2
	spr(si,this[1][1]-8,this[1][2]-8,2,2)
end

function dpr_explosion(this)
	if this[3] > 14 then
		return true
	end
	si = 128+flr(this[3]/5)*2
	spr(si,this[1][1]-8,this[1][2]-8,2,2)
end

function dpr_small_explosion(this)
	if this[3] > 8 then
		return true
	end
	si = 134+flr(this[3]/2.7)
	spr(si,this[1][1]-4,this[1][2]-4)
end
__gfx__
00000000eeeeeeeececceccceeeeeeeee11111eeeeeeeeee0000000000000000eedeeeee00000000cccc55ccdddddddd33333333333333333333333333333333
00000000eeeeeee6cc6666ceeeeeeee4ee999eeee4eeee4e0000000000000000eedeeeee00000000cc440444ddddddd63338333333ffffffffffffffffffff33
00700700ee4444e4c65ee56cee8888e84e555e4ee504405e0000000000000000eed11eee00000000c4220024dd4444d4338838333ffffffffffffffffffffff3
00077000e4044044e6e55e6cea0aa0884555554e045555400000000000000000ee6444ee0000000042e47704d404404c333bb3333ffffffffffffffffffffff3
00077000e4444444c6e55e6ee88888884888884e055555500000000000000000e464404e000000004e247704dccccccc333b33333ffffffffffffffffffffff3
00700700e888888ec65ee56ce888888e4599954e055555500000000000000000ecccccce00000000c4220024dccccccd3b3b3b333ffffffffffffffffffffff3
00000000ee4444eeec6666ccee8888ee4555554ee055550e0000000000000000ecccccce00000000cc440444d8cccc8d33bbb3333ffffffffffffffffffffff3
00000000eeeeeeeecccecceceeeeeeee4e555e4eee0550ee0000000000000000eeccccee00000000cccc55ccdd8888dd333333333fffffff33333333fffffff3
eee16a61eeeeeeeececceccc00000000ee6886eeeeeeeeeeeeeeeeceeeeeee9eeedeeeeeee5eeeeecccf55ccdddddddd333333333ffffff333bbbb33cccccccc
eee1eae1eeeeeee6cc6666ce00000000e658856ee4eeee4ee4eeee4ee4eeee4eeedeeeeeee5eeeeeccff4044ddddddd6333333333ffffff33bbbbbb3cccccccc
eee1eae1ee4444e4c65e5e6c00000000655cc556e000000ee111111ee999999eeed11eeeee511eeec4ff2004dd4444d4333333333ffffff33bbbbbb3cccccccc
e44445e1e4044044e6e5e56c00000000655cc5560055550011cccc1199888899ee6444eeee6444ee4fff4770d636636c333333333ffffff33bbbbbb3cccccccc
40440451e4444444c65e5e6e00000000658cc856055555501cccccc198888889e565bb5ee565bb5e4fff4770dccccccc333333333ffffff3bbbbbbbbcccccccc
444444e1e088880ec6e5e56c0000000065855856055555501cccccc198888889eccccccee112211ec4ff2004dcccccc3333333333ffffff3bbbbbbbbcccccccc
444444eeee5555aeec6666cc00000000e655556ee055550ee1cccc1ee988889eeccccccee112211eccff4044dbccccb3333333333ffffff3bbbbbbbbcccccccc
e4444eeeeeeeeeeeccceccec00000000ee6666eeee0550eeee1cc1eeee9889eeeecccceeee1111eecccf55ccddbbbb33333333333ffffff3bbbbbbbbcccccccc
00000000c9cc9cccc55c5ccc00000000ee6aa6ee0000000000000000000000000000000000000000ccc55cccdddddddd000000003fffffffbbbbbbbbfffffff3
00000000cc8888c9c566665500000000e65aa56e000000000000000000000000000000000000000056666665dddddddd000000003fffffffbbbbbbbbfffffff3
00000000c8aaaa8cc60ee0650000000065aaaa56000000000000000000000000000000000000000061114716dd8888dd000000003fffffffbbbbbbbbfffffff3
0000000098a99a8c56e00e6c0000000065aaaa56000000000000000000000000000000000000000061147776daaaaaad000000003fffffffbbbbbbbbfffffff3
00000000c8999989c6e00e65000000006a9aa9a6000000000000000000000000000000000000000061147776dccccccd000000003fffffffbbbbbbbbfffffff3
00000000c899998c560ee06c000000006a9aa9a6000000000000000000000000000000000000000061114716dccccccd000000003fffffffbbbbbbbbfffffff3
000000009c8888cc5566665c00000000ea5aa5ae000000000000000000000000000000000000000056666665d8cccc8d0000000033ffffffbbbbbbbbffffff33
00000000ccc9cc9cccc5c55c00000000ee6666ee0000000000000000000000000000000000000000ccc55cccdd8888dd0000000033333333bbbbbbbb33333333
000000000000000000000000000000000000000000000000000000000000000000000000000000005ccc5fc5ddddddddddddddddddddddddbbbbbbbb00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000c5f4ff44dddddddddddddddd2dddddd2bbbbbbbb00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000cff2ff04ddeaaedddd7997dd5d4444d5bbbbbbbb00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000cff2ff70dcaeeacdd99aa99d50000005bbbbbbbb00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000cff2ff70dccccccddaaaaaad555555553bbbbbb300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000cff2ff04dccccccdd9a99a9d555555553344443300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000c5f4ff44decccced99a99a99d555555d3344443300000000
000000000000000000000000000000000000000000000000000000000000000000000000000000005ccc5fc5ddeeeedddda99adddd5555dd3333333300000000
000000000000a0000000000000000000ffffff000000000000000000000070000000700000007000000000000000000000000000000000980099550000000598
000000000055a66600000000050505000f4f4f4000000000505000000007770000077700000777000000000000000000000000000000055009a5550000805550
0000a0000500a00022222222005660000ffffff008000080050000000078cc70007eee7000744470000000000000000000000000006055550577759005980500
0000aa0050000000299079920555650004444f40888508885050505007888ac707cbeaa7079444970000000000000000000000000600055057777a9955500000
0000aaa0500000b029900992005550000ffffff000555888000005007788aaa777bbaac777499947000000000000000000000000600000b09a77775505000080
0000aa0050bb0bbb02999920050505000f44f44008850888000050500788aaa707b8cab70794449700000000000000000000000060bb0bbb5a77aa5000000598
0000a0005bbbbbbb00222200000000000ffffff088800888000000000078aa70007ceb70007999700000000000000000000000006bbbbbbb05a7a99000005550
00000000bbbbbbbb00000000000000000fffffff0800008000000000000777000007770000077700000000000000000000000000bbbbbbbb9955509000000500
0066660000000000000000000000e00000000a0000a0000000089800007777700000000000000000000000000000000000000000000898000000088800000aaa
006006000000006000000020000e00000005aaa0000000a000558000770000070000d000a050000000000000000000000000000000558000000066680000aaaa
0060060000066600000ee2002020000e00555aaa0000baaa0500050066a05500000db0000a5500a05000000000000000000000000500650000066668009aaaaa
099999900066660000e222000200e0200775aaaaa00bbba050a0a050776555550ddddd00a050000a55000000000000000000000050000650006686600999aaa0
099559900066660000222200000e0200777aaaaaaa0bbb00500a005066a05500ddbbdbd0000000a050000000000000000000000050000050cc686600aa9a9a00
09959990a06660002022200020200020770aaaaaa00bbb0050a0a05077000007ddbbdbd0000a050000000000000000000000000050000050c1866000cca99900
099999900600000005000000020000007000aaa0000bbb000500050000777770ddbbdd000000a550000000000000000000000000050005001c1c0000caca9000
0000000000a00000002000000020000070000a000000b00000555000000000000ddd0000000a050000000000000000000000000000555000c1cc0000ccca0000
0000000000050000005000059008800900000000000000000909090000000000440000000000000000000000000000000000000000e00e00000eee0001111110
000000000050000055000550098008900ccc00000cec00009aaa9000a050000041440000008000000000000000000000000000000000000000ee000055555555
00000000550000000500005008088080c8a8c000ce7ec000a777a0000a55000041115550005000000000000000000000000000000e00000000e0000000111110
00000000050000000000500080899808ca8a8000e777e000aa777000a05000004111505005550000000000000000000000000000000eee000eeeeee005555000
000000000000500000550000808998080cc808000e777e000aa777000000a050411150500555000000000000000000000000000000e222e000000e0000011100
00000000000500050005000508088080cccc8080cce777e0aaaa777000000a55411155506666666600000000000000000000000000e222e00000ee0000555500
00000000055005500500055009800890c999c808c99e777eaaaaa7770000a050414400006656656600000000000000000000000000e222e0000ee00000011000
00000000005000505000005090088009c999c080c999e777aaaaa077000000004400000006666660000000000000000000000000000eee0000ee000000055000
00000000000006000000060000700000000080000000080000000000666622000004555500000000000000000000000000000000000900000000500000000990
0000000000550666005506660077700000558ccc005508cc05550000000022000004555000000000000000000000000000000000000090000000500000099999
00000000050006000500060007666770050080000500080011111000662200000004005505550058000000000000000000000000000090000005500000999009
00000000500000005000000007606700500000005000000055444000022220000004000054445556000000000000000000000000090990900055550099aa0990
00000000500000b05000000077666700500000b05000000005550000022220000422220044444556000000000000000000000000009a990000555500aaa99999
0000000050bb0bbb500000000077700050bb0bbb5000000055555000662200000444440044444559000000000000000000000000009aa90005555550099a0990
000000005bbbbbbb5bbcbcc0000070005bbbbbbb5bbcbcc011125200000000220222240044444058000000000000000000000000009aa9005555555500099009
00000000bbbbbbbbbcccbbcb00000000bbbbbbbbbcccbbcb11125200666666220004000004440000000000000000000000000000000990000000000000000990
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000a000000000000008880000089880000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000088000008988000899980000000000000000000000000000000000000000000000000000000000
000000880000000000000008880880000000a0088800000000089000008898000089980000000000000000000000000000000000000000000000000000000000
00008088880000000000088888880000000000888888000000000000000800000008800000000000000000000000000000000000000000000000000000000000
00000888988000000000008889888000000000889988000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000088999800000000008898a9800000000888999880a0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000088999880000000008889aa98000000a089099998000000000111111100000000111111110000000000000000000000000000000000000000000000000000
00000888880000000000088898880000000088099998000000055555555550000005555555555000000000000000000000000000000000000000000000000000
00000800008000000000088888880000000089999988800000000111111000000000111111110000005005000000000000000000000000000000000000000000
00000000000000000000080800800000000088098880000000000555555550000000555555500000000550000000000000000000000000000000000000000000
0000000000000000000000000000000000000888880a000000000011111000000000011111100000000550000000000000000000000000000000000000000000
00000000000000000000000000000000000a00000000000000055555550000000000000555555000005005000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000111110000000000001111100000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000055555500000000055555000000000000000000000000000000000000000000000000000000
000000000000000000000880000000000000000000000aa000000011110000000000001111000000000000000000000000000000000000000000000000000000
00000000000000000000888000000000aa00000000088aa000000555500000000000000555500000000000000000000000000000000000000000000000000000
00000000000000000000888888800000aaa000088888880000000011110000000000001111000000000000000000000000000000000000000000000000000000
00000008880000000008889898880000a88888888099080000000005500000000000000550000000000000000000000000000000000000000000000000000000
00000888880000000000888809088000898988889999008000000000000000000000000000000000000000000000000000000000000000000000000000000000
000008888880000000088a8999988000889999899999880000000000000000000000000000000000000000000000000000000000000000000000000000000000
000008999988000000098889a9998000080999999908880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008889999800000009890999998000088890999090880000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008909988800000000899099999800000888999999980aa00000000000000000000000a00000000000000000000000000000000000000000000000000000000
00088889998000000008a88908a8000000a88999900088800088800000000a000a0000a000000000000000000000000000000000000000000000000000000000
0008098998800000000889899989000000a88809009988800889980000a880000000000000000000000000000000000000000000000000000000000000000000
00088888880000000000808008800000000088909099988008999980008998000000800000000000000000000000000000000000000000000000000000000000
00000000000000000000888880000000000989909998808008999980008998000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000080998809898800089988000a8800000a0000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000aa888888888aa000000880000000a000a00000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000a08880888880a0000000000000000000000000a00000000000000000000000000000000000000000000000000000000
008888000077550000666500008888000044440000dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888880077577700665555009988990094444900dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000
0888888007755550065555500a9999a0049999400dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000
0888888005777750065555500baaaab0044444400dddddd0000000000000000000000000000000000000000000000000110000c7cccc0000110000c7ccdd0000
0888888005555770065555500bbbbbb0094444900dddddd000000000000000000000000000000000000000000000000011007cc7cccc770010007dc7cccc6600
0888888007777770055555500cbbbbc0049999400dddddd00000000000000000000000000000000000000000000000001117ccc7ccccc7701117ddc7ccccc770
00888800005575000055550000cccc000044440000dddd0000000000000000000000000000000000000000000000000011c7ccc7cccccc7711cddcc7ccdccc76
000880000007700000055000000ee00000044000000dd000000000000000000000000000000000000000000000000000ccc7cc77cccccc77cccdcc77ccddcc77
0088ee00887755080066dd00008855000044ff0000dddd00000000000000000000000000000000000000000000000000ccc7cc77cccccc77ccc7cc77cccdcc77
08888ee00885778806655dd00977855009444ff00dddddd000000000000000000000000000000000000000000000000011c7ccc7cccccc7711c7ccc7ccddcc77
082288800788585006115550077999a0042299400dddddd00000000000000000000000000000000000000000000000001117ccc7ccccc7701117cdc7ccccc760
0228888005788750011555500baaaab0022444400dddddd000000000000000000000000000000000000000000000000011007cc7cccc770011007dd7cccc7600
0888822005588870055551100bbbb770094442200dddddd0000000000000000000000000000000000000000000000000110000c7cccc0000010000d6dccc0000
0ee82280088778800dd51150055b77c00ff922400dddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ee88000855758800dd55000055cc0000ff440000dddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000880008007700800055000000ee00000044000000dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000
00775500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07667770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0667777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002200008788880000bb00005b55550000
0777766000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002200788788787700bb00b55b5555bb00
0557667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002227888788778770bbbb555b55755bb0
0055770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002287888788878877bb5b555b57b755bb
0007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008887887788878877555b55bb577775bb
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008887887788878877555b55bb577775bb
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002287888788878877bb5b555b57b755bb
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002227888788778770bbbb555b55755bb0
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002200788788787700bb00b55b5555bb00
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002200008788880000bb00005b55550000
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888eeeeee888eeeeee888eeeeee888eeeeee888eeeeee888eeeeee888777777888eeeeee888888888ff8ff8888228822888222822888888822888888228888
8888ee88eee88ee888ee88ee888ee88ee8e8ee88ee888ee88ee8eeee88778887788ee888ee88888888ff888ff888222222888222822888882282888888222888
888eeee8eee8eeeee8ee8eeeee8ee8eee8e8ee8eee8eeee8eee8eeee8777778778eee8e8ee88888888ff888ff888282282888222888888228882888888288888
888eeee8eee8eee888ee8eeee88ee8eee888ee8eee888ee8eee888ee8777778778eee888ee88e8e888ff888ff888222222888888222888228882888822288888
888eeee8eee8eee8eeee8eeeee8ee8eeeee8ee8eeeee8ee8eee8e8ee8777778778eee8e8ee88888888ff888ff888822228888228222888882282888222288888
888eee888ee8eee888ee8eee888ee8eeeee8ee8eee888ee8eee888ee8777778778eee888ee888888888ff8ff8888828828888228222888888822888222888888
888eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee8777777778eeeeeeee888888888888888888888888888888888888888888888888888888
1111111116661616111111111111116616161111166611111666161617711ccc1177171716111111111111111111111111111111111111111111111111111111
111111111611161611111777111116111616117116161111166616161711111c1117117116111111111111111111111111111111111111111111111111111111
1111111116611666111111111111166616661777166611111616161617111ccc1117177716111111111111111111111111111111111111111111111111111111
1111111116111116111117771111111611161171161111111616166617111c111117117116111111111111111111111111111111111111111111111111111111
1111111116661666111111111111166116661111161111711616116117711ccc1177171716661111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111116616661111111111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111161116161111177711111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111161116611111111111111ccc111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111161116161111177711111c1c111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111116616661111111111111ccc111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111116616661111111111111ccc111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111161111611111177711111c1c111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111161111611111111111111ccc111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111161111611111177711111c1c111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111116611611111111111111ccc111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1eee11111666111116661616166611111111111111111c1c11111eee1e1e1eee1ee1111111111111111111111111111111111111111111111111
1111111111e11e1111111616111116161616161611111777177711111c1c111111e11e1e1e111e1e111111111111111111111111111111111111111111111111
1111111111e11ee111111666111116661616166111111111111111111ccc111111e11eee1ee11e1e111111111111111111111111111111111111111111111111
1111111111e11e111111161111111611166616161111177717771111111c111111e11e1e1e111e1e111111111111111111111111111111111111111111111111
111111111eee1e111111161111711611116116161111111111111111111c111111e11e1e1eee1e1e111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111116616661111111111111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111161116161111177711111c1c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111161116611111111111111ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111116111616111117771111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111661666111111111111111c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111116616661111111111111cc11ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111611116111111777111111c11c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111611116111111111111111c11c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111111611116111111777111111c11c1c1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111116611611111111111111ccc1ccc1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1ee11ee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111e111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111ee11e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111e111e1e1e1e111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111eee1e1e1eee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111b111bbb1bb11bbb11711166161611111166161611111666161611111666161611111166166611711111111111111111111111111111111111111111
111111111b1111b11b1b1b1117111611161611111611161611111611161611111611161611111611161611171111111111111111111111111111111111111111
111111111b1111b11b1b1bb117111666116111111666166611111661116111111661166611111611166111171111111111111111111111111111111111111111
111111111b1111b11b1b1b1117111116161611711116111611711611161611711611111611711611161611171111111111111111111111111111111111111111
111111111bbb1bbb1b1b1bbb11711661161617111661166617111666161617111666166617111166166611711111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111bbb11bb1bbb1bbb11711666161611111666161611111166166611711111111111111111111111111111111111111111111111111111111111111111
111111111b1b1b111b1111b117111611161611111611161611111611116111171111111111111111111111111111111111111111111111111111111111111111
111111111bbb1bbb1bb111b117111661116111111661166611111611116111171111111111111111111111111111111111111111111111111111111111111111
111111111b11111b1b1111b117111611161611711611111611711611116111171111111111111111111111111111111111111111111111111111111111111111
111111111b111bb11bbb11b111711666161617111666166617111166116111711111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1ee11ee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111ee11e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111e111e1e1e1e1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1e1e1eee1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116611666111111661616161616661666161616661661117116661171111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616111116111616161616161161161616111616171116161117111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116161666111116661666161616611161166116611616171116661117111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161611111111161616161616161161161616111616171116111117111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661611166616611616116616161666161616661616117116111171111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111bb1bbb1bbb11bb117116661111166617711cc11177111116661111166617711ccc117711111cc111111ccc117111111111111111111111111111111111
11111b1111b11b1b1b111711161611111616171111c1111711111616111116161711111c1117111111c111111c1c111711111111111111111111111111111111
11111b1111b11bb11b111711166611111666171111c11117111116661111166617111ccc1117111111c111111c1c111711111111111111111111111111111111
11111b1111b11b1b1b111711161111111611171111c11117117116111111161117111c111117117111c111711c1c111711111111111111111111111111111111
111111bb1bbb1b1b11bb117116111171161117711ccc1177171116111171161117711ccc117717111ccc17111ccc117111111111111111111111111111111111
11111111111188888111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1ee11ee188888111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e88888111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e88888111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e88888111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee88888111111111111111111111111111111111111111111111111111111111111111111111111171111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177711111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177771111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111177111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111711111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111116661616111111661666161616611171166616161666116611711111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116161616111116111161161616161711116116161161161111171111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111116661666111116661161161616161711116116661161166611171111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111116111616111111161161161616161711116116161161111611171111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116111616166616611161116616161171116116161666166111711111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666166111661111111111111bbb1bb11bb111711cc11ccc1ccc117111111111111111111111111111111111111111111111111111111111111111111111
11111616161616111111177711111b1b1b1b1b1b171111c11c1c1c1c111711111111111111111111111111111111111111111111111111111111111111111111
11111661161616111111111111111bb11b1b1b1b171111c11c1c1c1c111711111111111111111111111111111111111111111111111111111111111111111111
11111616161616161111177711111b1b1b1b1b1b171111c11c1c1c1c111711111111111111111111111111111111111111111111111111111111111111111111
11111616161616661111111111111b1b1b1b1bbb11711ccc1ccc1ccc117111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee11111666166111661111111711111cc11ccc11111eee1e1e1eee1ee1111111111111111111111111111111111111111111111111111111111111
111111e11e11111116161616161111111171111111c11c11111111e11e1e1e111e1e111111111111111111111111111111111111111111111111111111111111
111111e11ee1111116611616161111111711111111c11ccc111111e11eee1ee11e1e111111111111111111111111111111111111111111111111111111111111
111111e11e11111116161616161611111171111111c1111c111111e11e1e1e111e1e111111111111111111111111111111111111111111111111111111111111
11111eee1e1111111616161616661111111711111ccc1ccc111111e11e1e1eee1e1e111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822882288222888282288288828888888888888888888888888888888888888882828222828882228882822282288222822288866688
82888828828282888888882888288882882888288288828888888888888888888888888888888888888882828282828882828828828288288282888288888888
82888828828282288888882888288222882888288222822288888888888888888888888888888888888882228282822282228828822288288222822288822288
82888828828282888888882888288288882888288282828288888888888888888888888888888888888888828282828288828828828288288882828888888888
82228222828282228888822282228222828882228222822288888888888888888888888888888888888888828222822288828288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c0c1c1c1c1c1c1c1e1c1e1e1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1c1c1c3e1e2e3e1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1c1c1c1c3e3e1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c0d0e0e0f1c1c1c1c1c1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1d1c1c1d1c1c1c1c1c1c0c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0e0e2f1c1c1d1c1c1f1c0d0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1d1c1f1f1c1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1d1c1f1f1c1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1d1c1c1c1c1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0d0e0e0e0e2f1c1c1c1e1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1c1c1c1c1c1c1c1c3e1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d0c1c1c1c1c1c1c1c1c1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1c0c1c1c1c1c1c1c1c1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c2d0e0e0e0e0e0e0e0e0e2f1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
