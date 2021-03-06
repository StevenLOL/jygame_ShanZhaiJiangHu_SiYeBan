function War_AutoMove()
  local pid = WAR.Person[WAR.CurID]["人物编号"]
  local x, y
  War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
  local minDest = math.huge
  local enemyid = War_AutoSelectEnemy()
  War_CalMoveStep(WAR.CurID, 100, 0)
  for i = 0, CC.WarWidth - 1 do
    for j = 0, CC.WarHeight - 1 do
      local dest = GetWarMap(i, j, 3)
      if dest < 128 then
        local dx = math.abs(i - WAR.Person[enemyid]["坐标X"])
        local dy = math.abs(j - WAR.Person[enemyid]["坐标Y"])
        if minDest > dx + dy then
          minDest = dx + dy
          x = i
          y = j
        elseif minDest == dx + dy and Rnd(2) == 0 then
          x = i
          y = j
        end
      end
    end
  end
  if minDest < math.huge then
    while true do
      local i = GetWarMap(x, y, 3)
      if i <= WAR.Person[WAR.CurID]["移动步数"] then
        break
      end
      if GetWarMap(x - 1, y, 3) == i - 1 then
        x = x - 1
      elseif GetWarMap(x + 1, y, 3) == i - 1 then
        x = x + 1
      elseif GetWarMap(x, y - 1, 3) == i - 1 then
        y = y - 1
      elseif GetWarMap(x, y + 1, 3) == i - 1 then
        y = y + 1
      end
    end
    War_MovePerson(x, y)
  end
end

function unnamed(kfid)
  local pid = WAR.Person[WAR.CurID]["人物编号"]
  local kungfuid = JY.Person[pid]["武功" .. kfid]
  local kungfulv = JY.Person[pid]["武功等级" .. kfid]
  if kungfulv == 999 then
    kungfulv = 11
  else
    kungfulv = math.modf(kungfulv / 100) + 1
  end
  local m1, m2, a1, a2, a3, a4, a5 = refw(kungfuid, kungfulv)
  local mfw = {m1, m2}
  local atkfw = {
    a1,
    a2,
    a3,
    a4,
    a5
  }
  if kungfulv == 11 then
    kungfulv = 10
  end
  local kungfuatk = JY.Wugong[kungfuid]["攻击力" .. kungfulv]
  local atkarray = {}
  local num = 0
  CleanWarMap(4, -1)
  local movearray = New_War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
  local starttime = lib.GetTime()
  for i = 0, WAR.Person[WAR.CurID]["移动步数"] do
    local step_num = movearray[i].num
    if step_num == nil or step_num == 0 then
      break
    end
    for j = 1, step_num do
      local xx = movearray[i].x[j]
      local yy = movearray[i].y[j]
      num = num + 1
      atkarray[num] = {}
      atkarray[num].x, atkarray[num].y = xx, yy
      atkarray[num].p, atkarray[num].ax, atkarray[num].ay = GetAtkNum(xx, yy, mfw, atkfw, kungfuatk)
      atkarray[num].p = atkarray[num].p * 5 / (3 + math.max(i, 2))
    end
  end
  for i = 1, num - 1 do
    for j = i + 1, num do
      if atkarray[i].p < atkarray[j].p then
        atkarray[i], atkarray[j] = atkarray[j], atkarray[i]
      end
    end
  end
  if 0 < atkarray[1].p then
    for i = 1, num do
      if atkarray[i].p == 0 or atkarray[i].p < atkarray[1].p / 2 then
        num = i - 1
        break
      end
    end
    for i = 1, num do
      atkarray[i].p = atkarray[i].p + GetMovePoint(atkarray[i].x, atkarray[i].y)
    end
    for i = 1, num - 1 do
      for j = i + 1, num do
        if atkarray[i].p < atkarray[j].p then
          atkarray[i], atkarray[j] = atkarray[j], atkarray[i]
        elseif atkarray[i].p == atkarray[j].p and math.random(2) == 1 then
          atkarray[i], atkarray[j] = atkarray[j], atkarray[i]
        end
      end
    end
    for i = 2, num do
      if atkarray[i].p < atkarray[1].p - 15 then
        num = i - 1
        break
      end
    end
    if num > 6 then
      for i = num, 6 do
        if atkarray[i].p < atkarray[1].p - 50 then
          num = i - 1
          break
        end
      end
    end
    local endtime = starttime + 100 - lib.GetTime()
    if endtime > 0 then
      lib.Delay(endtime)
    end
    local select
    select = 1
    New_War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
    War_MovePerson(atkarray[select].x, atkarray[select].y)
    WAR.Person[WAR.CurID].Action = {
      "atk",
      kfid,
      atkarray[select].ax - atkarray[select].x,
      atkarray[select].ay - atkarray[select].y
    }
    War_Fight_Sub(WAR.CurID, kfid, atkarray[select].ax, atkarray[select].ay)
  else
    local endtime = starttime + 100 - lib.GetTime()
    if endtime > 0 then
      lib.Delay(endtime)
    end
    local jl, nx, ny = War_realjl()
    if jl == -1 then
      AutoMove()
    else
      local vv
      vv = GetWarMap(nx + 1, ny, 2)
      if vv > -1 and WAR.Person[vv]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
      else
        vv = GetWarMap(nx - 1, ny, 2)
        if vv > -1 and WAR.Person[vv]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
        else
          vv = GetWarMap(nx, ny + 1, 2)
          if vv > -1 and WAR.Person[vv]["我方"] ~= WAR.Person[WAR.CurID]["我方"] then
          else
            vv = GetWarMap(nx, ny - 1, 2)
          end
        end
      end
      local array = {}
      local an = 0
      local movearray = New_War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
      New_War_CalMoveStep(vv, jl, 0)
      for i = 1, WAR.Person[WAR.CurID]["移动步数"] do
        local step_num = movearray[i].num
        if step_num == nil or step_num == 0 then
          break
        end
        for j = 1, step_num do
          local xx = movearray[i].x[j]
          local yy = movearray[i].y[j]
          local Dest = GetWarMap(xx, yy, 3)
          if Dest < 255 then
            an = an + 1
            array[an] = {}
            array[an].x = xx
            array[an].y = yy
            array[an].p = jl - Dest
          end
        end
      end
      for i = 1, an - 1 do
        for j = i + 1, an do
          if array[i].p < array[j].p then
            array[i], array[j] = array[j], array[i]
          end
        end
      end
      for i = 2, an do
        if array[i].p < array[1].p / 2 then
          an = i - 1
          break
        end
      end
      for i = 1, an do
        array[i].p = array[i].p + GetMovePoint(array[i].x, array[i].y)
      end
      for i = 1, an - 1 do
        for j = i + 1, an do
          if array[i].p < array[j].p then
            array[i], array[j] = array[j], array[i]
          end
        end
      end
      if an > 0 then
        New_War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
        War_MovePerson(array[1].x, array[1].y)
      else
        AutoMove()
      end
    end
    War_RestMenu()
  end
  return
end
function GetAtkNum(x, y, movfw, atkfw, atk)
  local point = {}
  local num = 0
  local kind, len = movfw[1], movfw[2]
  if kind == 0 then
    local array = MY_CalMoveStep(x, y, len, 1)
    for i = 0, len do
      local step_num = array[i].num
      if step_num == nil or step_num == 0 then
        break
      end
      for j = 1, step_num do
        num = num + 1
        point[num] = {
          array[i].x[j],
          array[i].y[j]
        }
      end
    end
  elseif kind == 1 then
    local array = MY_CalMoveStep(x, y, len * 2, 1)
    for r = 1, len * 2 do
      for i = 0, r do
        local j = r - i
        if len < i or len < j then
          SetWarMap(x + i, y + j, 3, 255)
          SetWarMap(x + i, y - j, 3, 255)
          SetWarMap(x - i, y + j, 3, 255)
          SetWarMap(x - i, y - j, 3, 255)
        end
      end
    end
    for i = 0, len do
      local step_num = array[i].num
      if step_num == nil or step_num == 0 then
        break
      end
      for j = 1, step_num do
        if GetWarMap(array[i].x[j], array[i].y[j], 3) < 128 then
          num = num + 1
          point[num] = {
            array[i].x[j],
            array[i].y[j]
          }
        end
      end
    end
  elseif kind == 2 then
    len = len or 1
    for i = 1, len do
      if x + i < CC.WarWidth - 1 and 0 < GetWarMap(x + i, y, 1) and CC.WarWater[GetWarMap(x + i, y, 0)] == nil then
        break
      end
      num = num + 1
      point[num] = {
        x + i,
        y
      }
    end
    for i = 1, len do
      if x - i > 0 and 0 < GetWarMap(x - i, y, 1) and CC.WarWater[GetWarMap(x - i, y, 0)] == nil then
        break
      end
      num = num + 1
      point[num] = {
        x - i,
        y
      }
    end
    for i = 1, len do
      if y + i < CC.WarHeight - 1 and 0 < GetWarMap(x, y + i, 1) and CC.WarWater[GetWarMap(x, y + i, 0)] == nil then
        break
      end
      num = num + 1
      point[num] = {
        x,
        y + i
      }
    end
    for i = 1, len do
      if y - i > 0 and 0 < GetWarMap(x, y - i, 1) and CC.WarWater[GetWarMap(x, y - i, 0)] == nil then
        break
      end
      num = num + 1
      point[num] = {
        x,
        y - i
      }
    end
  elseif kind == 3 then
    if x + 1 < CC.WarWidth - 1 and GetWarMap(x + 1, y, 1) == 0 and CC.WarWater[GetWarMap(x + 1, y, 0)] == nil then
      num = num + 1
      point[num] = {
        x + 1,
        y
      }
    end
    if 0 < x - 1 and GetWarMap(x - 1, y, 1) == 0 and CC.WarWater[GetWarMap(x - 1, y, 0)] == nil then
      num = num + 1
      point[num] = {
        x - 1,
        y
      }
    end
    if y + 1 < CC.WarHeight - 1 and GetWarMap(x, y + 1, 1) == 0 and CC.WarWater[GetWarMap(x, y + 1, 0)] == nil then
      num = num + 1
      point[num] = {
        x,
        y + 1
      }
    end
    if 0 < y - 1 and GetWarMap(x, y - 1, 1) == 0 and CC.WarWater[GetWarMap(x, y - 1, 0)] == nil then
      num = num + 1
      point[num] = {
        x,
        y - 1
      }
    end
    if x + 1 < CC.WarWidth - 1 and y + 1 < CC.WarHeight - 1 and GetWarMap(x + 1, y + 1, 1) == 0 and CC.WarWater[GetWarMap(x + 1, y + 1, 0)] == nil then
      num = num + 1
      point[num] = {
        x + 1,
        y + 1
      }
    end
    if 0 < x - 1 and y + 1 < CC.WarHeight - 1 and GetWarMap(x - 1, y + 1, 1) == 0 and CC.WarWater[GetWarMap(x - 1, y + 1, 0)] == nil then
      num = num + 1
      point[num] = {
        x - 1,
        y + 1
      }
    end
    if x + 1 < CC.WarWidth - 1 and 0 < y - 1 and GetWarMap(x + 1, y - 1, 1) == 0 and CC.WarWater[GetWarMap(x + 1, y - 1, 0)] == nil then
      num = num + 1
      point[num] = {
        x + 1,
        y - 1
      }
    end
    if 0 < x - 1 and 0 < y - 1 and GetWarMap(x - 1, y - 1, 1) == 0 and CC.WarWater[GetWarMap(x - 1, y - 1, 0)] == nil then
      num = num + 1
      point[num] = {
        x - 1,
        y - 1
      }
    end
  end
  local maxx, maxy, maxnum, atknum = 0, 0, 0, 0
  for i = 1, num do
    atknum = GetWarMap(point[i][1], point[i][2], 4)
    if atknum == -1 or atkfw[1] > 9 then
      atknum = WarDrawAtt(point[i][1], point[i][2], atkfw, 2, x, y, atk)
      if atknum > 0 then
        atknum = atknum + i
      end
      SetWarMap(point[i][1], point[i][2], 4, atknum)
    end
    if maxnum < atknum then
      maxnum, maxx, maxy = atknum, point[i][1], point[i][2]
    end
  end
  return maxnum, maxx, maxy
end
function AutoMove()
  local x, y
  local minDest = math.huge
  local enemyid = War_AutoSelectEnemy()
  New_War_CalMoveStep(WAR.CurID, 100, 0)
  for i = 0, CC.WarWidth - 1 do
    for j = 0, CC.WarHeight - 1 do
      local dest = GetWarMap(i, j, 3)
      if dest < 128 then
        local dx = math.abs(i - WAR.Person[enemyid]["坐标X"])
        local dy = math.abs(j - WAR.Person[enemyid]["坐标Y"])
        if minDest > dx + dy then
          minDest = dx + dy
          x = i
          y = j
        elseif minDest == dx + dy and Rnd(2) == 0 then
          x = i
          y = j
        end
      end
    end
  end
  if minDest < math.huge then
    while true do
      local i = GetWarMap(x, y, 3)
      if i <= WAR.Person[WAR.CurID]["移动步数"] then
        break
      end
      if GetWarMap(x - 1, y, 3) == i - 1 then
        x = x - 1
      elseif GetWarMap(x + 1, y, 3) == i - 1 then
        x = x + 1
      elseif GetWarMap(x, y - 1, 3) == i - 1 then
        y = y - 1
      elseif GetWarMap(x, y + 1, 3) == i - 1 then
        y = y + 1
      end
    end
    War_MovePerson(x, y)
  end
end
function AutoMove11()
  local movearray = New_War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
  local p, tx, ty = -999, 0, 0
  for i = 1, WAR.Person[WAR.CurID]["移动步数"] do
    local step_num = movearray[i].num
    if step_num == nil or step_num == 0 then
      break
    end
    for j = 1, step_num do
      local xx = movearray[i].x[j]
      local yy = movearray[i].y[j]
      local len = -2 * War_realjl() + GetMovePoint(xx, yy)
      if p < len then
        p = len
        tx = xx
        ty = yy
      end
    end
  end
  New_War_CalMoveStep(WAR.CurID, WAR.Person[WAR.CurID]["移动步数"], 0)
  War_MovePerson(tx, ty)
end
function GetMovePoint(x, y, flag)
  local point = 0
  local wofang = WAR.Person[WAR.CurID]["我方"]
  local movearray = MY_CalMoveStep(x, y, 9, 1)
  for i = 1, 9 do
    local step_num = movearray[i].num
    if step_num == nil or step_num == 0 then
      break
    end
    for j = 1, step_num do
      local xx = movearray[i].x[j]
      local yy = movearray[i].y[j]
      local v = GetWarMap(xx, yy, 2)
      if v == -1 or v == WAR.CurID then
      elseif WAR.Person[v]["我方"] == wofang then
        point = point + i * 2 - 19
      elseif WAR.Person[v]["我方"] ~= wofang then
        if flag ~= nil then
          point = point + i - 10
        elseif not instruct_16(WAR.Person[WAR.CurID]["人物编号"]) then
          point = point + 10 - i
        else
          point = point + 10 - i
        end
      end
    end
  end
  return point
end
function MY_CalMoveStep(x, y, stepmax, flag)
  CleanWarMap(3, 255)
  local steparray = {}
  for i = 0, stepmax do
    steparray[i] = {}
    steparray[i].bushu = {}
    steparray[i].x = {}
    steparray[i].y = {}
  end
  SetWarMap(x, y, 3, 0)
  steparray[0].num = 1
  steparray[0].bushu[1] = stepmax
  steparray[0].x[1] = x
  steparray[0].y[1] = y
  New_War_FindNextStep(steparray, 0, flag)
  return steparray
end
function MY_realjl(ida, idb)
  if ida == nil then
    ida = WAR.CurID
  end
  local num
  local movearray = New_War_CalMoveStep(ida, 255, 0)
  for i = 1, 255 do
    num = i
    lib.Debug(i)
    local step_num = movearray[i].num
    if step_num == nil or step_num == 0 then
      break
    end
    for j = 1, step_num do
      local xx = movearray[i].x[j]
      local yy = movearray[i].y[j]
      local v = GetWarMap(xx, yy, 2)
      if idb == nil then
        if v ~= -1 and WAR.Person[v]["我方"] ~= WAR.Person[ida]["我方"] then
          return v, num
        end
      elseif v == idb then
        return v, num
      end
    end
  end
end
function War_realjl(ida, idb)
  if ida == nil then
    ida = WAR.CurID
  end
  CleanWarMap(3, 255)
  local x = WAR.Person[ida]["坐标X"]
  local y = WAR.Person[ida]["坐标Y"]
  local steparray = {}
  steparray[0] = {}
  steparray[0].bushu = {}
  steparray[0].x = {}
  steparray[0].y = {}
  SetWarMap(x, y, 3, 0)
  steparray[0].num = 1
  steparray[0].bushu[1] = 0
  steparray[0].x[1] = x
  steparray[0].y[1] = y
  return New_War_FindNextStep1(steparray, 0, ida, idb)
end
function New_War_FindNextStep(steparray, step, flag, id)
  local num = 0
  local step1 = step + 1
  local function fujinnum(tx, ty)
    if flag ~= 0 or id == nil then
      return 0
    end
    local tnum = 0
    local wofang = WAR.Person[id]["我方"]
    local tv
    tv = GetWarMap(tx + 1, ty, 2)
    if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
      tnum = 9999
    end
    tv = GetWarMap(tx - 1, ty, 2)
    if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
      tnum = 999
    end
    tv = GetWarMap(tx, ty + 1, 2)
    if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
      tnum = 999
    end
    tv = GetWarMap(tx, ty - 1, 2)
    if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
      tnum = 999
    end
    return tnum
  end
  for i = 1, steparray[step].num do
    if 0 < steparray[step].bushu[i] then
      steparray[step].bushu[i] = steparray[step].bushu[i] - 1
      local x = steparray[step].x[i]
      local y = steparray[step].y[i]
      if x + 1 < CC.WarWidth - 1 then
        local v = GetWarMap(x + 1, y, 3)
        if v == 255 and War_CanMoveXY(x + 1, y, flag) == true then
          num = num + 1
          steparray[step1].x[num] = x + 1
          steparray[step1].y[num] = y
          SetWarMap(x + 1, y, 3, step1)
          steparray[step1].bushu[num] = steparray[step].bushu[i] - fujinnum(x + 1, y)
        end
      end
      if 0 < x - 1 then
        local v = GetWarMap(x - 1, y, 3)
        if v == 255 and War_CanMoveXY(x - 1, y, flag) == true then
          num = num + 1
          steparray[step1].x[num] = x - 1
          steparray[step1].y[num] = y
          SetWarMap(x - 1, y, 3, step1)
          steparray[step1].bushu[num] = steparray[step].bushu[i] - fujinnum(x - 1, y)
        end
      end
      if y + 1 < CC.WarHeight - 1 then
        local v = GetWarMap(x, y + 1, 3)
        if v == 255 and War_CanMoveXY(x, y + 1, flag) == true then
          num = num + 1
          steparray[step1].x[num] = x
          steparray[step1].y[num] = y + 1
          SetWarMap(x, y + 1, 3, step1)
          steparray[step1].bushu[num] = steparray[step].bushu[i] - fujinnum(x, y + 1)
        end
      end
      if 0 < y - 1 then
        local v = GetWarMap(x, y - 1, 3)
        if v == 255 and War_CanMoveXY(x, y - 1, flag) == true then
          num = num + 1
          steparray[step1].x[num] = x
          steparray[step1].y[num] = y - 1
          SetWarMap(x, y - 1, 3, step1)
          steparray[step1].bushu[num] = steparray[step].bushu[i] - fujinnum(x, y - 1)
        end
      end
    end
  end
  if num == 0 then
    return
  end
  steparray[step1].num = num
  New_War_FindNextStep(steparray, step1, flag, id)
end
function New_War_CalMoveStep(id, stepmax, flag)
  CleanWarMap(3, 255)
  local x = WAR.Person[id]["坐标X"]
  local y = WAR.Person[id]["坐标Y"]
  local steparray = {}
  for i = 0, stepmax do
    steparray[i] = {}
    steparray[i].bushu = {}
    steparray[i].x = {}
    steparray[i].y = {}
  end
  SetWarMap(x, y, 3, 0)
  steparray[0].num = 1
  steparray[0].bushu[1] = stepmax
  steparray[0].x[1] = x
  steparray[0].y[1] = y
  New_War_FindNextStep(steparray, 0, flag, id)
  return steparray
end
function New_War_FindNextStep1(steparray, step, id, idb)
  local num = 0
  local step1 = step + 1
  steparray[step1] = {}
  steparray[step1].bushu = {}
  steparray[step1].x = {}
  steparray[step1].y = {}
  local function fujinnum(tx, ty)
    local tnum = 0
    local wofang = WAR.Person[id]["我方"]
    local tv
    tv = GetWarMap(tx + 1, ty, 2)
    if idb == nil then
      if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
        return -1
      end
    elseif tv == idb then
      return -1
    end
    if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
      tnum = tnum + 1
    end
    tv = GetWarMap(tx - 1, ty, 2)
    if idb == nil then
      if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
        return -1
      end
    elseif tv == idb then
      return -1
    end
    if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
      tnum = tnum + 1
    end
    tv = GetWarMap(tx, ty + 1, 2)
    if idb == nil then
      if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
        return -1
      end
    elseif tv == idb then
      return -1
    end
    if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
      tnum = tnum + 1
    end
    tv = GetWarMap(tx, ty - 1, 2)
    if idb == nil then
      if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
        return -1
      end
    elseif tv == idb then
      return -1
    end
    if tv ~= -1 and WAR.Person[tv]["我方"] ~= wofang then
      tnum = tnum + 1
    end
    return tnum
  end
  for i = 1, steparray[step].num do
    steparray[step].bushu[i] = steparray[step].bushu[i] + 1
    local x = steparray[step].x[i]
    local y = steparray[step].y[i]
    if x + 1 < CC.WarWidth - 1 then
      local v = GetWarMap(x + 1, y, 3)
      if v == 255 and War_CanMoveXY(x + 1, y, 0) == true then
        num = num + 1
        steparray[step1].x[num] = x + 1
        steparray[step1].y[num] = y
        SetWarMap(x + 1, y, 3, step1)
        local mnum = fujinnum(x + 1, y)
        if mnum == -1 then
          return steparray[step].bushu[i], x + 1, y
        else
          steparray[step1].bushu[num] = steparray[step].bushu[i] + mnum
        end
      end
    end
    if 0 < x - 1 then
      local v = GetWarMap(x - 1, y, 3)
      if v == 255 and War_CanMoveXY(x - 1, y, 0) == true then
        num = num + 1
        steparray[step1].x[num] = x - 1
        steparray[step1].y[num] = y
        SetWarMap(x - 1, y, 3, step1)
        local mnum = fujinnum(x - 1, y)
        if mnum == -1 then
          return steparray[step].bushu[i], x - 1, y
        else
          steparray[step1].bushu[num] = steparray[step].bushu[i] + mnum
        end
      end
    end
    if y + 1 < CC.WarHeight - 1 then
      local v = GetWarMap(x, y + 1, 3)
      if v == 255 and War_CanMoveXY(x, y + 1, 0) == true then
        num = num + 1
        steparray[step1].x[num] = x
        steparray[step1].y[num] = y + 1
        SetWarMap(x, y + 1, 3, step1)
        local mnum = fujinnum(x, y + 1)
        if mnum == -1 then
          return steparray[step].bushu[i], x, y + 1
        else
          steparray[step1].bushu[num] = steparray[step].bushu[i] + mnum
        end
      end
    end
    if 0 < y - 1 then
      local v = GetWarMap(x, y - 1, 3)
      if v == 255 and War_CanMoveXY(x, y - 1, 0) == true then
        num = num + 1
        steparray[step1].x[num] = x
        steparray[step1].y[num] = y - 1
        SetWarMap(x, y - 1, 3, step1)
        local mnum = fujinnum(x, y - 1)
        if mnum == -1 then
          return steparray[step].bushu[i], x, y - 1
        else
          steparray[step1].bushu[num] = steparray[step].bushu[i] + mnum
        end
      end
    end
  end
  if num == 0 then
    return -1
  end
  steparray[step1].num = num
  for i = 1, num - 1 do
    for j = i + 1, num do
      if steparray[step1].bushu[j] < steparray[step1].bushu[i] then
        steparray[step1].bushu[i], steparray[step1].bushu[j] = steparray[step1].bushu[j], steparray[step1].bushu[i]
        steparray[step1].x[i], steparray[step1].x[j] = steparray[step1].x[j], steparray[step1].x[i]
        steparray[step1].y[i], steparray[step1].y[j] = steparray[step1].y[j], steparray[step1].y[i]
      end
    end
  end
  return New_War_FindNextStep1(steparray, step1, id, idb)
end



