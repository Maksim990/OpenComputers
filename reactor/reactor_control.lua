local c = require('component') 
local event = require("event")
local term = require('term')
local srl = require('serialization')
local mod = c.modem
local inv = c.invoke
 
local setting = {}
local temp = {}
 
local function readReactorBase()
  setting = {}
  print('Загрузка базы реакторов')
  local f = io.open('/etc/reactor/setting.cfg', 'r')
  if f then
    setting = srl.unserialize(f:read())
    f:close()
    print('Загрузка завершена')
  else
    print('ОШИБКА! Нет файла конфигурации! Выполните настройку!')
  end
end
 
local function reactorOnOff(tupe)
  local tmp = 0
  if inv(setting[tupe].redstone, 'getOutput', setting.side) == 0 then
    tmp = true
    print('Врубаю реактор '..tupe)
    inv(setting[tupe].redstone, 'setOutput', setting.side, 255)
  else
    tmp = false
    print('Вырубаю реактор '..tupe)
    inv(setting[tupe].redstone, 'setOutput', setting.side, 0)
  end
  return tmp
end
 
local function returnStatus()
  local status = {}
  local tmp = 0
  for i = 1, #setting do
    status[#status+1] = {['Act'] = inv(setting[i].reactor, 'isActive'), ['Heat'] = math.ceil(100*inv(setting[i].reactor, 'getHeat')/inv(setting[i].reactor, 'getMaxHeat')),['Out'] = inv(setting[i].reactor, 'getReactorEUOutput')}
  end
  mod.broadcast(setting.port, 'INFO', srl.serialize(status))
end
 
local function pause()
  print('Включен режим паузы')
  event.pull('modem_message')
  print('Выключен режим паузы')
end
 
term.clear()
readReactorBase()
mod.open(setting.port)
 
while true do
  tmp = {event.pull(3, 'modem_message')}
  if tmp[1] then
    if tmp[6] == 'ON_OFF' then
      reactorOnOff(tmp[7])
      returnStatus()
    elseif tmp[6] == 'PAUSE' then
      pause()
    end
  end
  returnStatus()
end