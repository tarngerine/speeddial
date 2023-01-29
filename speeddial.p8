pico-8 cartridge // http://www.pico-8.com
version 38
__lua__

function _init()
  playing=true
  goal=false

  player={
    health=100,
    sp=1,
    x=10,
    y=10,
    w=8,
    h=8,
    flp=false,
    dx=0,
    dy=0,
    max_dx=1.5,
    max_dy=3,
    acc=0.5,
    speed_up_time=0,
    boost=1,
    airtime=0,
    max_airtime=4,
    anim=0,
    running=false,
    jumping=false,
    falling=false,
    sliding=false,
    landed=false,
    hurt_time=0,
    hurt_locked=false,
    trail={},
    items=0,
  }

  start_time=time()
  finish_time=0
  gravity=0.3
  friction=0.85

  --simple camera
  cam_x=0
  cam_y=0

  --map limits
  map_start=0
  map_end=2048
end

-->8
--update and draw

function _update()
  if playing then
    player_update()
    player_animate()
    
    --simple camera
    cam_x=player.x-64+(player.w/2)
    if cam_x<map_start then
      cam_x=map_start
    end
    if cam_x>map_end-128 then
      cam_x=map_end-128
    end
    cam_y=player.y-82+(player.h/2)
    
    camera(cam_x,cam_y)
  else
    camera(0,0)
    if btnp(❎) then
      _init()
    end
  end
end

function _draw()
  cls()

  if playing then
    map(0,0)
    map(0,16, 1024, 0)
    -- make sprite blue
    pal(13,12)
    pal(14,12)
    pal(5,12)
    for i=1,#player.trail do
      local t=player.trail[i]
      spr(t.sp,t.x,t.y,1,1,t.flp)
    end
    pal()
    if player.hurt_time>0 and time()%0.3<0.15 then
      -- make sprite red
      pal(13,8)
      pal(14,8)
      pal(5,8)
    end
    spr(player.sp,player.x,player.y,1,1,player.flp)
    pal()

    ui()
  else
    rect(0,0,127,8,7)
    print("lab results, week 1",2,2,7)
    rect(0,10,127,64,7)
    print("health",2,12,7)
    print(player.health,126-#(player.health.."")*4,12,7)
    print("time",2,20,7)
    print(flr(finish_time-start_time),126-#(flr(finish_time-start_time).."")*4,20,7)
    print("speed",2,28,7)
    print(player.items,122,28,7)
    -- print("sodium",2,28,7)
    -- print("2",122,28,7)
    -- print("protein",2,36,7)
    -- print("2",122,36,7)
    -- print("creatinine",2,44,7)
    -- print("8",122,44,7)
    -- print("egfr",2,52,7)
    -- print("7",122,52,7)
    rect(0,66,127,66+16,7)
    print("doctors note:",2,68,7)
    print("things look good, keep it up",2,76,7)
    print("press ❎ to continue",2,128-8,7)
  end
end

function ui()
  local h=6
  local x=flr(cam_x)
  local y=flr(cam_y)+127-h
  print("+",x+1, y+1,8)
  x+=6
  rectfill(x,y,x + (player.health/100 * 32),y+h,8)
  rect(x,y,x+32,y+h,7)
  x+=36
  print("s",x,y+1,12)
  x+=4
  rectfill(x,y,x + (player.speed_up_time/120 * 32),y+h,12)
  rect(x,y,x+32,y+h,7)
  x=cam_x+128
  local elapsed=time()-start_time
  -- print(":"..flr(elapsed%60).."hello",x,y+2,7)
  print(flr(elapsed/60)..":"..flr(elapsed%60/10)..flr(elapsed%10),x-16,y+2,7)
end


-->8
--collisions

function collide_map(obj,aim,flag)
 --obj = table needs x,y,w,h
 --aim = left,right,up,down

 local tolerance=1
 local x=obj.x  local y=obj.y
 local w=obj.w  local h=obj.h

 local x1=0	 local y1=0
 local x2=0  local y2=0

 if aim=="left" then
   x1=x+2  y1=y+h-1
   x2=x+2    y2=y+h-3

 elseif aim=="right" then
   x1=x+w-2    y1=y+h-1
   x2=x+w-2  y2=y+h-3

 elseif aim=="up" then
   x1=x+4    y1=y+h-1
   x2=x+4  y2=y+h-4

 elseif aim=="down" then
   x1=x+4      y1=y+h
   x2=x+4    y2=y+h+1
 end

 --pixels to tiles
 x1/=8    y1/=8
 x2/=8    y2/=8

 --handle map wrapping
 if (x1 > 128 or x2 > 128) then
  x1-=128
  x2-=128
  y1+=16
  y2+=16
 end

 if fget(mget(x1,y1), flag) then
    return {x1,y1}
  elseif fget(mget(x1,y2), flag) then
    return {x1,y2}
  elseif fget(mget(x2,y1), flag) then
    return {x2,y1}
  elseif fget(mget(x2,y2), flag) then
    return {x2,y2}
 else
   return false
 end

end

function get_item(obj,flag)
  local left = collide_map(obj,"left",flag)
  local right = collide_map(obj,"right",flag)
  local up = collide_map(obj,"up",flag)
  local down = collide_map(obj,"down",flag)
  if left then
    mset(left[1],left[2],0)
    return true
  elseif right then
    mset(right[1],right[2],0)
    return true
  elseif up then
    mset(up[1],up[2],0)
    return true
  elseif down then
    mset(down[1],down[2],0)
    return true
  else
    return false
  end
end

function fall_off()
  if player.y > 128 then
    player.y=10
    player.x=10
  end
end

function finish_level()

  if collide_map(player,"left",3)or 
  collide_map(player,"right",3)or
  collide_map(player,"up",3)or
  collide_map(player,"down",3) then
    playing=false
    goal=true
    finish_time=time()
  end
end

-->8
--player

function player_update()
  fall_off()
  finish_level()

  --physics
  player.dy+=gravity
  player.dx*=friction

  --speed up
  if get_item(player,1) then
    player.items+=1
    player.speed_up_time=60
  end
  player.max_dx=player.speed_up_time > 0 and 3 or 1.5
  player.speed_up_time=max(player.speed_up_time-1,0)
  if player.speed_up_time>0 then
    if #player.trail>8 then
      del(player.trail,player.trail[1])
    end
    add(player.trail,{x=player.x,y=player.y})
  else
    if #player.trail>0 then
      del(player.trail,player.trail[1])
    end
  end
  --lose health
  if get_item(player,2) then
    player.health-=33
    player.dy=-2
    player.dx=player.flp and 3 or -3
    player.hurt_time=30
    player.hurt_locked=true
  end
  player.hurt_time=max(player.hurt_time-1,0)

  --controls
  if not player.hurt_locked then
  if btn(⬅️) then
    player.dx-=player.acc
    player.running=true
    player.flp=true
  end
  if btn(➡️) then
    player.dx+=player.acc
    player.running=true
    player.flp=false
  end
end

--jump
if btn(❎)
and player.landed then
  player.dy-=player.boost
  player.airtime+=1
  if player.airtime >= player.max_airtime then 
    player.landed=false
    player.airtime=0
  end
end

  --slide
  if player.running
  and not btn(⬅️)
  and not btn(➡️)
  and not player.falling
  and not player.jumping then
    player.running=false
    player.sliding=true
  end

  --check collision up and down
  if player.dy>0 then
    player.falling=true
    player.landed=false
    player.jumping=false

    player.dy=limit_speed(player.dy,player.max_dy)

    if collide_map(player,"down",0) then
      player.landed=true
      player.hurt_locked=false
      player.falling=false
      player.dy=0
      player.y-=((player.y+player.h+1)%8)-1
    end
  elseif player.dy<0 then
    player.jumping=true
    if collide_map(player,"up",0) then
      player.dy=0
    end
  end

  --check collision left and right
  if player.dx<0 then

    player.dx=limit_speed(player.dx,player.max_dx)

    if collide_map(player,"left",0) then
      player.dx=0
    end
  elseif player.dx>0 then

    player.dx=limit_speed(player.dx,player.max_dx)

    if collide_map(player,"right",0) then
      player.dx=0
    end
  end

  --stop sliding
  if player.sliding then
    if abs(player.dx)<.2
    or player.running then
      player.dx=0
      player.sliding=false
    end
  end

  player.x+=player.dx
  player.y+=player.dy

  --limit player to map
  if player.x<map_start then
    player.x=map_start
  end
  if player.x>map_end-player.w then
    player.x=map_end-player.w
  end
end

function player_animate()
  if player.jumping then
    player.sp=0
  elseif player.falling then
    player.sp=0
  elseif player.sliding then
    player.sp=0
  elseif player.running then
    if time()-player.anim>.1 then
      player.anim=time()
      player.sp+=1
      if player.sp>4 then
        player.sp=2
      end
    end
  else --player idle
    if time()-player.anim>.3 then
      player.anim=time()
      player.sp+=1
      if player.sp>1 then
        player.sp=0
      end
    end
  end
end

function limit_speed(num,maximum)
  return mid(-maximum,num,maximum)
end

__gfx__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa000
00ddd0000000000000ddd00000ddd00000ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa00
00dffd0000ddd00000dffd0000dffd0000dffd0000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa
005eed0000dffd00005eed00005eed00005eed00000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaa0
00555d00005eed0000555d0000555d0000555d000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa00
0055500000555d00005550000055500000555000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaa0
0050500000555000005550000555500000555500000000000000000000000000000000000000000000000000000000000000000000000000000000000aa00aa0
005050000050500000505000000050000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa0000aa
ffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08830030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88880880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08808888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999399000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000801000000000000000000000000000000020000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000101010101010101010101010101010020200000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000101010101010101010101010101010101000000000000000000000000000000000
0000000000200000000000000000000000000000001010000010100000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010000000101010101010100000000000000010101000000000000000000000000000000000
0000000010100000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000010000000101010101010100000000000000010101000000000000000000000000000000000
0000000000000000000000000000000000003010000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100010100000000010000000101010101010100000000000000010101000000000000000000000000000000000
0000101000001010000000000010100010101010000000000000000000000000101000101010000000000000103010201030100000000000000000000000000000000000000000000000000000000000101000000010000000000010001000101010101010100000000000000010101000000000000000000000000000000000
0000000000000000000000000000000010100000101010101010100000000000000000100010000000000010101010101010100000000000000000000000000000000000000000000000000000000000000000101010000000000010101000101010101010100000000000000010101000000000000000000000000000000000
101010101010101010100000101010101010000000000000000000000000001010101010001010100010101000000010101010000000001010001010000000000000000000000000000000000000000000000010000000000000000000100010101010101010000000000000001010100000000000000000000000000000000f
000000000000000000000000000000000000000000000000000000000000000000000000000000101010000000000010000000000000001010101010000000000000000000000000000000000000001010101010000000000000000000100010101010101010000000000000001010100000000000000010000000000000000f
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010001010101000001010101010000000000000000000000000000000000010101000000000000000000000000000100010101010101010100000000000000000000000000000001010100000000000000f
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000001010101010000000000000000000101000101000001010000000000000000000000000000000100010101010100000000000000000001010100000000000101010101000000000000f
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010101010101010101010000000000000001010101000101000101000000000000000001010101010101010100010101010100010101010101010101000100000000010101010101010100000000f
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010000000101010000010000000001000000000000000000010000000000000000000101010000000100000000000000000001010101010101010101010101010101010
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010001000100000000010101010101000000000000000000010001010101010101010101010001010100000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000100000000000000000000000000000000000000010000000000000000000000000001000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010100000000000000000000000000000000000000010101010101010101010100010101000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100010000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1010101010101010101010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
