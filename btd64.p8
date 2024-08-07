pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--game data

--map_pts = {{-1,3},{9,3},{9,6},{1,6},{1,8},{11,8},{11,16}}
map_pts = {{-1,6},{3,6},{3,4},{6,4},{6,10},{1,10},{1,14},{11,14},{11,6},{16,6}}
gnd = 28
gnd_clr = 3

waves_data = {
	{10,{30,2}},
	{25,{20,1}},
	{15,{40,1}},
	{15,{30,1},{15,2}},
	{15,{1,3}},
}

--raw wave data
waves = {}
for k,v in pairs(waves_data) do
	waves[k] = {}
	for i,g in pairs(v) do
		if i > 1 then
			for l=1,g[1] do
				add(waves[k],g[2])
			end
		end
	end
end

function _init()
	def_monkeys()
end

-->8
--game

round = 0
playing = false
spawning = true
spawn_index = 0
spawn_timer = 0

gspd = 1

entered_menu = false

function start_round()
	round += 1
	playing = true
	spawning = true
	spawn_index = 1
	spawn_timer = 0
end

function spawn_bloons()
	if playing and spawning then
		spawn_timer -= gspd
		if spawn_timer <= 0 then
			spawn_timer = waves_data[round][1]
			t = waves[round][spawn_index]
			sx = map_pts[1][1]*8
			sy = map_pts[1][2]*8
			spawn_bloon({sx,sy},t)
			spawn_index += 1
			if spawn_index > #waves[round] then
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
	spawn_bloons()
	--perf_o(0,12)
end

function _update()
	main()
end
-->8
--bloons

--speed,img,size,{splits to},{{color from,color to}},health,moab
bloon_types = {
	{0.5, 48, 1, {}, {},1,false},
	{0.7, 48, 1, {1}, {{8,12}},1,false},
	{0.25, 37, 2, {}, {},700,true},
}

bloons = {}

bloons_buffer = {}
function empty_bloons_buffer()
	for k,v in pairs(bloons_buffer) do
		spawn_bloon(v[1],v[2],v[3],v[4],v[5],v[6],v[7])
	end
	bloons_buffer = {}
end

function confuse_bloon(b)
	if b.pt > 1 then
		b.cnf = b.pt
		b.s -= b.ptss[b.pt]
		b.pt -= 1
	end
end

function pop_bloon(bi,pp,pmom)
	b = bloons[bi]
	bt = bloon_types[b.t]
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
				p,v,bi,b.pt,b.s,b.ptss,b.cnf}
			)
		end
	end
	del(bloons,b)
end

function spawn_bloon(pos,t,id,pt,s,ptss,cnf)
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
		h=bloon_types[t][6], --health
		lmd={0,0}
	})
end

function draw_bloons()
	--h = nil
	for k,v in pairs(bloons) do
		bt = bloon_types[v.t]
		img = bt[2]
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
		spd = bloon_types[v.t][1]*gspd
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
				lives -= #bloon_types[v.t][4]+1
				del(bloons,v)
			end
		end
	end
end
-->8
--player

cash = 6500
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
				cls(0)
				print(dump(m),7)
				--stop()
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
		crsr[1] = 0
	elseif crsr[1] > 15  do
		crsr[1] = 15
	end
	if crsr[2] < 1 do
		crsr[2] = 1
	elseif crsr[2] > 15 do
		crsr[2] = 15
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

function rectborder(x1,y1,x2,y2,clr1,clr2)
	rectfill(x1,y1,x2,y2,clr1)
	rect(x1,y1,x2,y2,clr2)
end

function draw_tooltip()
	rectfill(0,120,127,127,0)
	
	o = "open menu"
	x = false
	if in_menu != -1 then
		o = "close menu"
		x = "select"
	elseif placing != -1 then
		o = "cancel"
		x = "confirm"
	else
		if monkey_at({crsr[1]*8,crsr[2]*8}) != false then
			x = "select"		
		end
	end
	
	print("🅾️ "..o,0,121,7)
	if x != false then
		print("❎ "..x,64,121,7)
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
		menu_crsr = 0
	elseif menu_crsr > mx then
		menu_crsr = mx
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
				cash += m.vl
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
						u[3](m)
					end
				end
			end
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
			elseif v == 1 then
				rect(128-w,k*10,127,10+k*10,15)
				print("max upg.",128-w+2+3,k*10+2,15)
			else
				rectfill(128-w+3,k*10,128-w+9+3,10+k*10,0)				
				rect(128-w,k*10,127,10+k*10,15)
				spr(v[2],130-w+3,k*10+2)
				print("$"..v[1],128-w+12+3,k*10+2,15)
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
		print("sell $"..m.vl,130-w,32,15)
		
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
		if mget(crsr[1],crsr[2]) != gnd then
			valid = false
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
		cmo=false, --camo
		tgt=0, --target (0 first, 1 strong, 2 near, 3 last)
		i=1, --sprite
		trac=14, --transparency colour
		r=2.5, --range
		a=reg_attack, --attack func
		proji=1, --current proj index
		projs={base_proj},
		adc=0, --attack delay counter
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
		pcer=false, --ceramic
	}

	dart = new_mk({
		cs={
			{{8,4}},
			{{8,11}},
			{}
		},
		u1={
			{90,65,function (this)
				this.r = 2.9
				this.ccs=max(2,this.ccs)
			end},
			{120,66,function (this)
				this.r = 3.4
				this.ccs=max(3,this.ccs)
			end}
		},
		u2={
			{140,81,function (this)
				this.projs[1].pr += 1
				this.projs[1].pl += 5
				this.ccs=max(2,this.ccs)
			end},
			{170,82,function (this)
				this.projs[1].pr += 1
				this.projs[1].pl += 5
				this.cmo = true
				this.ccs=max(3,this.ccs)
			end}
		}
	})
	
	tack_shtr = new_mk({
		i=2,
		r=1.4,
		trac=0
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
			{300,68,function(this)
				this.r = 3.2
				this.ad = 12
				this.ccs=max(2,this.ccs)
			end},
			{300,69,function(this)
				this.pr = 3
				this.ccs=max(5,this.ccs)
			end},
			{850,70,function(this)
				this.projs[1].amt = 2
				this.ccs=6
			end}
		},
		u2={
			{250,84,function(this)
				this.projs[1].phm = true
				this.projs[1].pl += 10
				this.ccs=max(3,this.ccs)
			end},
			{350,85,function(this)
				this.ccs=max(4,this.ccs)
				this.projs[1].phfn = ph_stun
			end},
			{2750,86,function(this)
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
		a=reg_attack,
		c=500,
		projs={{ --first proj
			amt=1,		--shuriken
			ad=2,
			ps=6,
			pr=2,
			pdf=dp_shuriken,
			pstnc=15, --proj stun chance
		},
			{ad=16} --second proj
		},							--only delay
		r=2.9,
		cmo=true
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
			{200,77,function (this)
				this.r += 0.3
				this.ccs=max(2,this.ccs)
			end},
			{300,78,function (this)
				this.ccs=max(3,this.ccs)
				this.projs[1].pfrag = true
			end},
			{800,79,function (this)
				this.ccs=max(4,this.ccs)
				this.projs[1].pfragbmb = true
				if this.i != 4 then
					this.ccs=6
				end
			end}
		},
		u2={
			{400,93,function (this)
				this.projs[1].pvr = 2
				this.projs[1].pp = 2
				this.projs[1].pbr = 12

				this.ccs=max(2,this.ccs)
			end},
			{400,94,function (this)
				this.projs[1].pvr = 3
				this.projs[1].pp = 4
				this.r += 0.1
				this.projs[1].ad -= 0.4
				this.projs[1].ps += 3
				this.ccs=max(3,this.ccs)
				this.ccs += 2
				this.i = 20
			end},
			{900,95,function (this)
				this.projs[1].pvr = 4
				this.projs[1].pmom = 10
				this.i = 36
			end}
		},
		i=4,
		c=650,
		ad=42,
		projs={{
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
	apprentice = new_mk({
		cs={
			{}
		},
		i=5,
		r=2.9,
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
			b,dx,dy,d,k =	bloon_near(v.p,v.r*8+4,0)
			v.a(v,b,dx,dy,d,k)
			if v.pshfn != nil then
				v.pshfn(v)				
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

function bloons_near(pos,r)
	t = {}
	for k,v in pairs(bloons) do
		x = v.p[1]+4
		y = v.p[2]+4
		tx = pos[1]
		ty = pos[2]
		dx = (x-tx)
		dy = (y-ty)
		d = sqrt(dx^2+dy^2)
		if d < r then
			add(t,v)
		end
	end
	return t
end

--sort
--0 first
--1 strong
--2 near
--3 last
function bloon_near(pos,r,sort)
	b = {nil,0,0,0,0,0}
	for k,v in pairs(bloons) do
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
	end
	return b[2],b[3],b[4],b[5],b[6]
end

function reg_attack(this,b,dx,dy,d,k)
	if b != 0 then
		if this.adc <= 0 then
			total = 0
			for k,v in pairs(this.projs) do
				if v.amt != nil then
					total += v.amt
				else
					total += 1
				end
			end
			
			p = nil
			cpi = 1
			i = this.proji
			while p == nil do
				a = this.projs[cpi].amt or 1
				if a >= i then
					p = this.projs[cpi]
					break
				end
				i -= a
				cpi += 1
			end
			if p.ps != nil then
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
			end
			
			--reset
			this.adc = p.ad
			this.proji += 1
			if this.proji > total then
				this.proji = 1
			end
		end
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
		if v.plc >= v.pl then
			del(proj,v)
		else			
		
			--to not hit same bloon twice
			hit_bloons = {}
			
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
				max_gap = 7
				ttmx = {}
				ttmy = {}
				
				mxs = max(ceil(abs(tmx)/max_gap),ceil(abs(tmy)/max_gap))
	   for j=1,mxs do
	    add(ttmx, tmx/mxs)
	    add(ttmy, tmy/mxs)
				end
				
				for k,csmx in pairs(ttmx) do
					csmy = ttmy[k]
					v.p[1] += csmx
					v.p[2] += csmy
					
					b,dx,dy,d,bi = bloon_near(v.p,4,0)
					if b != 0 and not has_value(hit_bloons, b) then
						cash += 1
						pop_bloon(bi, v.pp, v.pmom)
						add(hit_bloons, b)
						if v.phfn != nil then
							v.phfn(v)
						end
						
						v.prc += 1
						if v.prc == v.pr then
							del(proj,v)
							break
						end
						
					--check if can home
					if v.phm == true then
						b,dx,dy,d,bi = bloon_near(v.p,20,0)
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
			v.pdf(v)			
		end
	end
end

function dp_dart(p)
	line(p.p[1],p.p[2],p.p[1]+p.mv[1]*2,p.p[2]+p.mv[2]*2,0)
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

function dp_shuriken(p)
	circ(p.p[1],p.p[2],1,0)
end

function dp_magic_bolt(p)
	circfill(p.p[1],p.p[2],1,14)
end

function ph_flash_bmb(this)
	spwn_particle(this.p,dpr_explosion)
	ph_stun(this)
end

function ph_stun(this)
	rng = rnd(100)
	if rng < this.pstnc then
		bls = bloons_near(this.p, 13)
		for k,v in pairs(bls) do
			--dont confuse moabs
			--or already confused bloons
			if bloon_types[v.t][7] == false and 
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
	bls = bloons_near(this.p, this.pbr)
	for k,v in pairs(bls) do
		pop_bloon(indexof(bloons,v),1,1)
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
			powner = {
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
				pbr=8
			}
			if this.pfragbmb == true then
				powner.phfn = ph_bomb
			end
			spwn_proj(
				{this.p[1],this.p[2]},
				{v[1],v[2]},
				powner
			)
		end
	end
end
-->8
--functions

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

function has_value (tab, val)
 for index, value in ipairs(tab) do
	 if value == val then
	  return true
	 end
 end

 return false
end


function spr_r(s,x,y,a,w,h)
	rspr(flr(s%16)*8,flr(s/16)*8,0,8,a,w)
 sspr(0,8,8*w,8*w,x,y,8*w,8*w)
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

function	spwn_particle(p,dpr)
	add(particles, {p,dpr,0})
end

function draw_particles()
	for k,v in pairs(particles) do
		v[3] += gspd
		if v[2](v) == true then
			del(particles,v)
		end
	end
end

function dpr_big_explosion(this)
	if this[3] > 15 then
		return true
	end
	si = 160+flr(this[3]/5)*2
	spr(si,this[1][1]-8,this[1][2]-8,2,2)
end

function dpr_explosion(this)
	if this[3] > 15 then
		return true
	end
	si = 128+flr(this[3]/5)*2
	spr(si,this[1][1]-8,this[1][2]-8,2,2)
end
__gfx__
00000000eeeeeeee0e00e000eeeeeeeee11111eeeeeeeeee00000000000000000000000000000000000000000000000033333333333333333333333333333333
00000000eeeeeee60066660eeeeeeee4ee999eeee4eeee4e0000000000000000000000000000000000000000000000003338333333ffffffffffffffffffff33
00700700ee4444e4065ee560ee8888e84e555e4ee504405e000000000000000000000000000000000000000000000000338838333ffffffffffffffffffffff3
00077000e4044044e6e55e60ea0aa0884555554e04555540000000000000000000000000000000000000000000000000333bb3333ffffffffffffffffffffff3
00077000e444444406e55e6ee88888884888884e05555550000000000000000000000000000000000000000000000000333b33333ffffffffffffffffffffff3
00700700e888888e065ee560e888888e4599954e055555500000000000000000000000000000000000000000000000003b3b3b333ffffffffffffffffffffff3
00000000ee4444eee0666600ee8888ee4555554ee055550e00000000000000000000000000000000000000000000000033bbb3333ffffffffffffffffffffff3
00000000eeeeeeee000e00e0eeeeeeee4e555e4eee0550ee000000000000000000000000000000000000000000000000333333333fffffff33333333fffffff3
00000000000000000000000000000000ee6886eeeeeeeeeeeeeeeeceeeeeee9e00000000000000000000000000000000333333333ffffff333bbbb3300000000
00000000000000000000000000000000e658856ee4eeee4ee4eeee4ee4eeee4e00000000000000000000000000000000333333333ffffff33bbbbbb300000000
00000000000000000000000000000000655cc556e000000eeccccccee999999e00000000000000000000000000000000333333333ffffff33bbbbbb300000000
00000000000000000000000000000000655cc55605555550c111111c9888888900000000000000000000000000000000333333333ffffff33bbbbbb300000000
00000000000000000000000000000000658cc85605555550c111111c9888888900000000000000000000000000000000333333333ffffff3bbbbbbbb00000000
000000000000000000000000000000006585585605555550c111111c9888888900000000000000000000000000000000333333333ffffff3bbbbbbbb00000000
00000000000000000000000000000000e655556ee055550eec1111cee988889e00000000000000000000000000000000333333333ffffff3bbbbbbbb00000000
00000000000000000000000000000000ee6666eeee0550eeeec11ceeee9889ee00000000000000000000000000000000333333333ffffff3bbbbbbbb00000000
00000000000000000000000000000000ee6aa6ee0000000000000000000000000000000000000077770000000001111cc11110003fffffffbbbbbbbbfffffff3
00000000000000000000000000000000e65aa56e0000000000000000000000000000000000000777777000000000011cc11000003fffffffbbbbbbbbfffffff3
0000000000000000000000000000000065aaaa5600000000000000000000000000000000000077cccc770000000001cccc1000003fffffffbbbbbbbbfffffff3
0000000000000000000000000000000065aaaa56110000c7cccc0000110000c7ccdd000000007cccccc7000000000777777000003fffffffbbbbbbbbfffffff3
000000000000000000000000000000006a9aa9a611007cc7cccc770010007dc7cccc6600000cccccccccc00000007cccccc700003fffffffbbbbbbbbfffffff3
000000000000000000000000000000006a9aa9a61117ccc7ccccc7701117ddc7ccccc770000cccccccccc0000000cccccccc00003fffffffbbbbbbbbfffffff3
00000000000000000000000000000000ea5aa5ae11c7ccc7cccccc7711cddcc7ccdccc76000cccccccccc000000cccc77cccc00033ffffffbbbbbbbbffffff33
00000000000000000000000000000000ee6666eeccc7cc77cccccc77cccdcc77ccddcc77000cccccccccc000000777777777700033333333bbbbbbbb33333333
00888800006665000044440000dddd0000dddd00ccc7cc77cccccc77ccc7cc77cccdcc770007777777777000000cccccccccc00000000000bbbbbbbb00000000
0888888006655550094444900dddddd00dddddd011c7ccc7cccccc7711c7ccc7ccddcc77000cccc77cccc000000cccccccccc00000000000bbbbbbbb00000000
0888888006555550049999400dddddd00dddddd01117ccc7ccccc7701117cdc7ccccc7600000cccccccc0000000cccccccccc00000000000bbbbbbbb00000000
0888888006555550044444400dddddd00dddddd011007cc7cccc770011007dd7cccc760000007cccccc70000000cccccccccc00000000000bbbbbbbb00000000
0888888006555550094444900dddddd00dddddd0110000c7cccc0000010000d6dccc0000000007777770000000007cccccc70000000000003bbbbbb300000000
0888888005555550049999400dddddd00dddddd000000000000000000000000000000000000001cccc100000000077cccc770000000000003344443300000000
00888800005555000044440000dddd0000dddd00000000000000000000000000000000000000011cc11000000000077777700000000000003344443300000000
000880000005500000044000000dd000000dd000000000000000000000000000000000000001111cc11110000000007777000000000000003333333300000000
000000000000a0000000000000000000ffffff000000000000000000000000000000000000000000000000000000000000000000000000980099550000000598
000000000055a66600000000000000000f4f4f4000000000505000000000000000000000000000000000000000000000000000000000055009a5550000805550
0000a0000500a00022222222000000000ffffff00800008005000000000000000000000000000000000000000000000000000000006055550577759005980500
0000aa0050000000299079920000000004444f4088850888505050500000000000000000000000000000000000000000000000000600055057777a9955500000
0000aaa0500000b029900992000000000ffffff00055588800000500000000000000000000000000000000000000000000000000600000b09a77775505000080
0000aa0050bb0bbb02999920000000000f44f440088508880000505000000000000000000000000000000000000000000000000060bb0bbb5a77aa5000000598
0000a0005bbbbbbb00222200000000000ffffff088800888000000000000000000000000000000000000000000000000000000006bbbbbbb05a7a99000005550
00000000bbbbbbbb00000000000000000fffffff0800008000000000000000000000000000000000000000000000000000000000bbbbbbbb9955509000000500
0066660000000000000000000000000000000a0000a0000000089800000000000000000000000000000000000000000000000000000898000000088800000aaa
006006000000006000000020000000000005aaa0000000a00055800000000000000000000000000000000000000000000000000000558000000066680000aaaa
0060060000066600000ee2000000000000555aaa0000baaa050005000000000000000000000000000000000000000000000000000500650000066668009aaaaa
099999900066660000e22200000000000775aaaaa00bbba050a0a05000000000000000000000000000000000000000000000000050000650006686600999aaa0
09955990006666000022220000000000777aaaaaaa0bbb00500a005000000000000000000000000000000000000000000000000050000050cc686600aa9a9a00
09959990a06660002022200000000000770aaaaaa00bbb0050a0a05000000000000000000000000000000000000000000000000050000050c1866000cca99900
099999900600000005000000000000007000aaa0000bbb0005000500000000000000000000000000000000000000000000000000050005001c1c0000caca9000
0000000000a00000002000000000000070000a000000b0000055500000000000000000000000000000000000000000000000000000555000c1cc0000ccca0000
0000000000050000005000059008800900000000000000000000000000000000000000000000000000000000000000000000000000e00e00000eee0001111110
000000000050000055000550098008900000000000000000000000000000000000000000000000000000000000000000000000000000000000ee000055555555
000000005500000005000050080880800000000000000000000000000000000000000000000000000000000000000000000000000e00000000e0000000111110
00000000050000000000500080899808000000000000000000000000000000000000000000000000000000000000000000000000000eee000eeeeee005555000
0000000000005000005500008089980800000000000000000000000000000000000000000000000000000000000000000000000000e222e000000e0000011100
0000000000050005000500050808808000000000000000000000000000000000000000000000000000000000000000000000000000e222e00000ee0000555500
0000000005500550050005500980089000000000000000000000000000000000000000000000000000000000000000000000000000e222e0000ee00000011000
00000000005000505000005090088009000000000000000000000000000000000000000000000000000000000000000000000000000eee0000ee000000055000
00000000000006000000060000700000000000000000000000000000000000000000000000000000000000000000000000000000000900000000500000000999
00000000005506660055066600777000000000000000000000000000000000000000000000000000000000000000000000000000000090000000500000099990
00000000050006000500060007666770000000000000000000000000000000000000000000000000000000000000000000000000000090000005500000999009
00000000500000005000000007606700000000000000000000000000000000000000000000000000000000000000000000000000090990900055550099aa0999
00000000500000b05000000077666700000000000000000000000000000000000000000000000000000000000000000000000000009a990000555500aaa99999
0000000050bb0bbb5000000000777000000000000000000000000000000000000000000000000000000000000000000000000000009aa90005555550099a0999
000000005bbbbbbb5bbcbcc000007000000000000000000000000000000000000000000000000000000000000000000000000000009aa9005555555500099000
00000000bbbbbbbbbcccbbcb00000000000000000000000000000000000000000000000000000000000000000000000000000000000990000000000000000999
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077777700000
0000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000000000077cccc770000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cccc7c00001100007cccccc70000
000000880000000000000008880880000000a0088800000000000000000000000000000000000000000000000000000000777ccc7cc70011000cccccccccc000
000080888800000000000888888800000000008888880000000000000000000000000000000000000000000000000000077ccccc7ccc7111000cccccccccc000
00000888988000000000008889888000000000889988000000000000000000000000000000000000000000000000000077cccccc7ccc7c11000cccccccccc000
0000088999800000000008898a9800000000888999880a0000000000000000000000000000000000000000000000000077cccccc77cc7ccc000cccccccccc000
000088999880000000008889aa98000000a089099998000000000000000000000000000000000000000000000000000077cccccc77cc7ccc0007777777777000
00000888880000000000088898880000000088099998000000000000000000000000000000000000000000000000000077cccccc7ccc7c11000cccc77cccc000
000008000080000000000888888800000000899999888000000000000000000000000000000000000000000000000000077ccccc7ccc71110000cccccccc0000
00000000000000000000080800800000000088098880000000000000000000000000000000000000000000000000000000777ccc7cc7001100007cccccc70000
0000000000000000000000000000000000000888880a00000000000000000000000000000000000000000000000000000000cccc7c0000110000077777700000
00000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000000000000000000001cccc100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011cc1100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111cc1111000
000000000000000000000880000000000000000000000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000888000000000aa00000000088aa000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000888888800000aaa000088888880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000008880000000008889898880000a88888888099080000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888880000000000888809088000898988889999008000000000000000000000000000000000000000000000000000000000000000000000000000000000
000008888880000000088a8999988000889999899999880000000000000000000000000000000000000000000000000000000000000000000000000000000000
000008999988000000098889a9998000080999999908880000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008889999800000009890999998000088890999090880000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008909988800000000899099999800000888999999980aa00000000000000000000000000000000000000000000000000000000000000000000000000000000
00088889998000000008a88908a8000000a889999000888000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008098998800000000889899989000000a888090099888000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088888880000000000808008800000000088909099988000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000888880000000000989909998808000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000809988098988000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000aa888888888aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000a08880888880a0000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0e0e0e2f1c1c1d1c1c1c1c0d0e0e0e0e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1d1c1c1c1c1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1d1c1c1c1c1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1d1c1c1c1c1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c0d0e0e0e0e2f1c1c1c1e1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1c1c1c1c1c1c1c1c3e1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d0c1c1c1c1c1c1c1c1c1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1d1c0c1c1c1c1c1c1c1c1d1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c2d0e0e0e0e0e0e0e0e0e2f1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
