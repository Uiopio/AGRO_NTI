from pyb import UART, LED

import sensor, image, time

ledBlue = LED(2)
ledBlue.on()

sensor.reset()
sensor.set_pixformat(sensor.RGB565)
sensor.set_framesize(sensor.LCD)
sensor.skip_frames(100)

ledBlue.off()

# параметры юарта
uart = UART(3)
uart.init(9600, bits=8, parity=None, stop=1, timeout_char=1000) # init with given parameters

# Словарь меток
tag_families = 0
tag_families |= image.TAG36H11 # comment out to disable this family (default family)

# счетчик для мигания сигнального светодиода
led_count = 0

# рабочий цикл
while(True):
    img = sensor.snapshot() # получение фотографии
    # поиск маркеров на фото
    for tag in img.find_apriltags(families=tag_families):
        uart.write(str(tag.id())) # отправление по юарт id маркера

    # Индикация работы скрипта
    led_count = led_count + 1
    if led_count >=4:
        ledBlue.on()
        led_count = 0
    else:
        ledBlue.off()

    # Задержка
    time.sleep(0.1)


