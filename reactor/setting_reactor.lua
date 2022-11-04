local c = require('component') 
local term = require('term')
local fl = require('filesystem')
local srl = require('serialization')
local inv = c.invoke
 
local tempRed = {}
local tempRea = 0
local setting = {}
local temp = {}
 
term.clear()
fl.remove('/etc/reactor')
fl.makeDirectory('/etc/reactor')
print('Вас приветствует мастер настроек реакторного контроллера\nОтключите все реакторы. Для продолжение нажмите Enter')
io.read()
print('Укажите номер стороны к какой подключен реактор\ndown = 0, up = 1, north = 2, south = 3, west = 4, east = 5')
setting = {['side'] = tonumber(io.read())}
print('Укажите номер стороны к какой подключен индикатор (только для калибровки)')
temp = {['side'] = tonumber(io.read())}
print('Проверка датчиков ...')
for k, _ in pairs(c.list("redstone")) do
  tempRed[#tempRed+1] = k
  for i = 0, 5 do
    if inv(k, 'getOutput', i) > 0 then
      inv(k, 'setOutput', i, 0)
    end
  end
end
for k, _ in pairs(c.list("reactor_chamber")) do
  tempRea=tempRea+1
end
if #tempRed ~= tempRea then
  print('Не совпадет количество реакторов и редстоун контроллеров. Проверьте все подключения и повторите настройку')
  os.exit()
end
print('Проверка завершена. Обнаружено '..tempRea..' датчиков\nСейчас по очереди будут включаться реакторы. Ваша задача указать их порядковый номер.')
repeat
  print('Активация реактора')
  inv(tempRed[1], 'setOutput', setting.side, 255)
  inv(tempRed[1], 'setOutput', temp.side, 255)
  for k, _ in pairs(c.list("reactor_chamber")) do
    if inv(k, 'isActive') then
      temp[1] = k
      break
    end
  end
  print('Укажите порядковый номер активного реактора')
  setting[tonumber(io.read())] = {['reactor'] = temp[1], ['redstone'] = tempRed[1]}
  print('Деактивация реактора')
  inv(tempRed[1], 'setOutput', setting.side, 0)
  inv(tempRed[1], 'setOutput', temp.side, 0)
  table.remove(tempRed, 1)
  term.clear()
until #tempRed == 0
print('Укажите номер диапазона для дистанционной связи')
setting.port = tonumber(io.read())
local f = io.open('/etc/reactor/setting.cfg', 'w')
f:write(srl.serialize(setting))
f:close()
print('Настройка завершена!')