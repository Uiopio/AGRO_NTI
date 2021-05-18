
-- объявление переферии
-------------------------------------------------------------------------------------------------------------------------
-- Создание порта управления магнитом - порт PC3 на плате версии 1.2
local magnet = Gpio.new(Gpio.C, 3, Gpio.OUTPUT)

-- объявление пульта радиоуправления
local rc = Sensors.rc
local range = Sensors.range

-- кол-во светодиодов и создание порта управления светодиодов
local ledNumber = 8
local leds = Ledbar.new(ledNumber)

--  инициализируем Uart интерфейс
local uartNum = 4 -- номер Uart интерфейса (USART4)
local baudRate = 9600 -- скорость передачи данных
local dataBits = 8
local stopBits = 1
local parity = Uart.PARITY_NONE
local uart = Uart.new(uartNum, baudRate, parity, stopBits) --  создание протокола обмена

local unpack = table.unpack
-------------------------------------------------------------------------------------------------------------------------
local flight = true -- флаг для определения состояния полета


-------------------------------------------------------------------------------------------------------------------------
-- функция, которая меняет цвет светодиодов на красный и выключает таймер
local function emergency()
   takePhotoTimer:stop()
   -- так как после остановки таймера его функция выполнится еще раз, то меняем цвета светодиодов на красный через секунду
   Timer.callLater(1, function () changeColor(1, 0, 0) end)
end

-- определяем функцию анализа возникающих событий в системе
function callback(event)
   -- проверка, низкое ли напряжение на аккумуляторе 
	if (event == Ev.LOW_VOLTAGE2) then
       emergency()
	end
   
end
-------------------------------------------------------------------------------------------------------------------------



function getData() -- функция приёма пакета данных
    if uart:bytesToRead() ~= 0 then
        return uart:read(1)
    else
        return -1 
    end
end


-- блок обработки светодиодов
-------------------------------------------------------------------------------------------------------------------------
-- мигание светодиодом, означает, что скрипт работает
local heartBeatIsOn = false  						-- флаг для переключаения режима светодиода
local function heartBeat()
    if heartBeatIsOn == true then 					-- если светодиоды горят, то выключим их
        leds:set(i, 0, 0, 0)
    else                    						-- если не горят, то включим
        leds:set(i, 0.2, 0.2, 0)
    end
    heartBeatIsOn = not heartBeatIsOn
end

-- включает все светодиоды с заданным цветом. 0,0,0 - выключение
local function changeColor(red, green, blue)
   for i=0, ledNumber - 1, 1 do
       leds:set(i, red, green, blue)
   end
end

-- мигание светодиодами при считывание меток
local ledIsOn = false 								-- флаг переключения светодиодов при считывание меток
local function ledMarker(r,g,b)
    if ledIsOn == true then 						-- если светодиоды горят, то выключим их
        changeColor(0,0,0)
    else                    						-- если не горят, то включим
        changeColor(r,g,b)
    end
    ledIsOn = not ledIsOn
end
------------------------------------------------------------------------------------------------------------------------


-- блок объявления переменных
------------------------------------------------------------------------------------------------------------------------
-- флаг того, что необходимо 5 сек мигать светодиодами
local id_is_on = {false, false, false, false}




-- Хранение считанных светодиодов
local correct_ID = {false, false, false, false}


local count = 0 									-- счетчик для отображения работы луа скрипта
local countLed = 0 									-- счетчик для мигания в течении 5 секунд 

local countLetter = {0, 0, 0, 0}


local count_finish_flight = 0 						-- счетчик для вывода считанных маркеров
local finish_flight_is_start = false 				-- флаг того, что полет завершен и нужно вывести считанные маркеры


local intensity = 1 								-- интенсивность
local time_timer = 0.1 								-- частота запуска функции main в секундах
local time_heartBeat = 0.5 							-- частота мигания индикатора рабоыт скрипта в секундах
local time_led_marker = 5 							-- время работы отображения считанного маркера
local time_finish_flight = 3 						-- время свечения светодиодов при завершении полета


-- Время работы любого куска кода рассчитывается по следующей формуле:
-- count = time / time_timer 
-- count - сколько раз нужно выполнить часть кода, чтобы по времени это было равно time
-- time - желаемое время в секундах (например time_led_marker = 5)
-- time_timer - время срабатываения таймера и вызова функции main
------------------------------------------------------------------------------------------------------------------------

local testOn = false
local colors = {{intensity, intensity, intensity}, {intensity, 0, 0}, {0, intensity, 0}, {0, 0, intensity}}
local color = {}

local main = function () -- функция для периодического чтения данных из UART
    local id_marker = getData()

    -- считывание маркеров
    for i=1, 4, 1 do
        if (id_marker == tostring(i-1)) and (correct_ID[i] == false) then
            countLetter[i] = countLetter[i] + 1 
            if countLetter[i] >= 7 then
                correct_ID[i] = true
                --id_is_on[i] = true
                testOn = true
                color = colors[i]
                countLed = 0
            end
        end   
    end 
    
    -- индикация считывания
    if(testOn == true) then
        ledMarker(unpack(color))
        countLed = countLed + 1  
    end

    
    -- после 50 тиков флаг показа сбрасывается, тем самым показ идет только один раз
    if countLed >= (time_led_marker / time_timer) then
        for i=1, 4, 1 do
            id_is_on[i] = false
            countLetter[i] = 0
        end
        testOn = false
        countLed = 0
        changeColor(0,0,0)
    end

    -- индикация работы скрипта
    count = count + 1
    if (count >= (time_heartBeat / time_timer) ) and (testOn ==false) then
        heartBeat()
        count = 0
    end

    -- переключение магнита
    
    ch1, ch2, ch3, ch4, ch5, ch6, ch7, ch8 = rc()-- считываем сигнал на пульте

    if ch8 > 0 then
        magnet:set()
    end
    if(ch8 < 0) then
        magnet:reset()
    end

    -- вывод считанных маркеров
    if ch6 <= 0 then
        finish_flight_is_start = true
    end    
    if ch6 > 0 then
        finish_flight_is_start = false
        count_finish_flight = 0
    end
    


    -- вывод соответствующего цвета для считанного маркера в течении 1 секунды
    if (finish_flight_is_start == true) then
        count_finish_flight = count_finish_flight + 1
        
        if (correct_ID[1] == true) and (count_finish_flight < (time_finish_flight / time_timer)) then
            changeColor(intensity,intensity,intensity)
        elseif (correct_ID[2] == true) and (count_finish_flight >= (time_finish_flight / time_timer)) and (count_finish_flight < 2*(time_finish_flight / time_timer)) then
            changeColor(intensity,0,0)
        
        elseif (correct_ID[3] == true) and (count_finish_flight >= 2*(time_finish_flight / time_timer)) and (count_finish_flight < 3*(time_finish_flight / time_timer)) then
            changeColor(0,intensity,0)
        
        elseif (correct_ID[4] == true) and (count_finish_flight >= 3*(time_finish_flight / time_timer)) and (count_finish_flight < 4*(time_finish_flight / time_timer)) then
            changeColor(0,0,intensity)
        elseif count_finish_flight>=4*(time_finish_flight / time_timer) then
            changeColor(0,0,0)
            count_finish_flight = 0
            finish_flight_is_start = false
			
        end
        
    end


end

markerTimer = Timer.new(time_timer, function () main() end)
markerTimer:start()
