local c = require('component') 
local event = require("event")
local term = require('term')
local srl = require('serialization')
local fl = require('filesystem')
local un = require('unicode')
local mod = c.modem
local inv = c.invoke
local gpu = c.gpu
local W, H = gpu.getResolution()
local b_color, f_color = gpu.getBackground(), gpu.getForeground()
 
local setting = {}
local temp = {}
 
tButtons = {}
 
local function curPhrase(line) --вырезка фразы с разделителем
  local tbl = {}
  for part in line:gmatch("[^;]+") do
    table.insert(tbl, part) 
  end
  return tbl
end
 
local function drawButton(n) -- функция рисования кнопки
  gpu.setBackground(tButtons[n].color)
  gpu.setForeground(tButtons[n].textColor)
  gpu.fill(tButtons[n].X, tButtons[n].Y, tButtons[n].W, tButtons[n].H, ' ')
  if tButtons[n].vertical then
    gpu.set(tButtons[n].X+(tButtons[n].W/2), tButtons[n].Y+(tButtons[n].H/2)-(un.len(tButtons[n].text)/2), tButtons[n].text, true)
  else
    if tButtons[n].textR then
      local tmp = curPhrase(tButtons[n].text)
      for i = 1, #tmp do
        if tmp[i] ~= '#' then
          gpu.set(tButtons[n].X, tButtons[n].Y+i-1, tmp[i])
        end
      end
    else
      gpu.set(tButtons[n].X+(tButtons[n].W/2)-(un.len(tButtons[n].text)/2), tButtons[n].Y+(tButtons[n].H/2), tButtons[n].text)
    end
  end
end
 
function toggleVisible(n) -- переключение видимости кнопки
  if tButtons[n].visible then
    tButtons[n].visible = false
    gpu.setBackground(b_color)
    gpu.fill(tButtons[n].X, tButtons[n].Y, tButtons[n].W, tButtons[n].H, ' ')
  else
    tButtons[n].visible = true
    drawButton(n)
  end
end
 
local function blink(n) -- мигание кнопки
  local temp = ''
  for i=tButtons[n].X, tButtons[n].W+tButtons[n].X-1 do
    temp = temp..gpu.get(i,tButtons[n].Y)
  end
  tButtons[n].color, tButtons[n].textColor = tButtons[n].textColor, tButtons[n].color
  drawButton(n)
  os.sleep(0.09)
  tButtons[n].color, tButtons[n].textColor = tButtons[n].textColor, tButtons[n].color
  drawButton(n)
  gpu.set(tButtons[n].X,tButtons[n].Y,temp)
  gpu.setBackground(b_color)
  gpu.setForeground(f_color)
end
 
function activBottom() --активатор кнопок
  for i = 1, #tButtons do
    toggleVisible(i)
  end
  gpu.setBackground(b_color)
  gpu.setForeground(f_color)
end
 
local function bottomInstall(tbl)
  tButtons = {}
  local posX, j, k = 0, 1, 0
  local tmp = {}
  local vr = ''
  local resX, _ = math.modf(#tbl/5)+1
  local resY = 0
  if #tbl < 4 then
    resY = 7*#tbl
  else
    resY = 25
  end
  gpu.setResolution(14*resX+1, resY)
  for i = 1, #tbl do
    vr = ''
    tmp[i] = {['text'] = 0, ['color'] = 0}
    if i < 10 then
      vr = vr..'#; Reactor: '..i..';'
    else
      vr = vr..'#; Reactor:'..i..';'
    end
    if tbl[i].Act then
      tmp[i].color = 0x00ff00
    else
      tmp[i].color = 0xff0000
    end
    vr = vr..' Heat: '..tbl[i].Heat..'%;'
    vr = vr..' EU/t:'..tbl[i].Out..';'
    tmp[i].text = vr
  end
  for i = 1, #tbl do
    if k+1 == 5 then
      j = j + 1
      posX = posX + 12
      k = 1
    else
      k = k + 1
    end
    tButtons[#tButtons+1] = { visible = false, X = 2*j+posX, Y = ((k-1)*6)+2, W = 12, H = 5, color = tmp[i].color, textColor = 0xffffff, textR = true, text = tmp[i].text,
      action = function()
        mod.broadcast(setting.port, 'ON_OFF', i)
      end}
  end
  activBottom()
end
 
local function readSettingBase()
  setting = {}
  print('Загрузка базы реакторов')
  local f = io.open('/etc/reactor/setting.cfg', 'r')
  if f then
    setting = srl.unserialize(f:read())
    f:close()
    print('Загрузка завершена')
  else
    fl.makeDirectory('/etc/reactor')
    print('Укажите номер диапазона для дистанционной связи')
    setting.port = tonumber(io.read())
    local f = io.open('/etc/reactor/setting.cfg', 'w')
    f:write(srl.serialize(setting))
    f:close()
  end
end
 
readSettingBase()
mod.open(setting.port)
term.clear()
 
while true do
  tmp = {event.pullMultiple('modem_message', 'touch')}
  if tmp[1] == 'modem_message' then
    if tmp[6] == 'INFO' then
      bottomInstall(srl.unserialize(tmp[7]))
    end
  else
    for i = 1, #tButtons do
      if tButtons[i].visible then
        if tmp[3] >= tButtons[i].X and tmp[3] <= tButtons[i].X+tButtons[i].W-1 and tmp[4] >= tButtons[i].Y and tmp[4] <= tButtons[i].Y+tButtons[i].H-1 then
          blink(i)
          tButtons[i].action()
          break
        end
      end
    end
  end
end