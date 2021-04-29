from pyb import UART, LED

import sensor, lcd, image, time, utime, math


ledBlue = LED(2)
ledBlue.on()

sensor.reset()                      # Reset and initialize the sensor.
sensor.set_pixformat(sensor.RGB565) # Set pixel format to RGB565 (or GRAYSCALE)
sensor.set_framesize(sensor.LCD)   # Set frame size to QVGA (320x240)
sensor.skip_frames(100)     # Wait for settings take effect.
clock = time.clock()                # Create a clock object to track the FPS.
lcd.init()
ledBlue.off()

uart = UART(3)
uart.init(9600, bits=8, parity=None, stop=1, timeout_char=1000) # init with given parameters


tag_families = 0
tag_families |= image.TAG16H5 # comment out to disable this family
tag_families |= image.TAG25H7 # comment out to disable this family
tag_families |= image.TAG25H9 # comment out to disable this family
tag_families |= image.TAG36H10 # comment out to disable this family
tag_families |= image.TAG36H11 # comment out to disable this family (default family)
tag_families |= image.ARTOOLKIT # comment out to disable this family


def family_name(tag):
    if(tag.family() == image.TAG16H5):
        return "TAG16H5"
    if(tag.family() == image.TAG25H7):
        return "TAG25H7"
    if(tag.family() == image.TAG25H9):
        return "TAG25H9"
    if(tag.family() == image.TAG36H10):
        return "TAG36H10"
    if(tag.family() == image.TAG36H11):
        return "TAG36H11"
    if(tag.family() == image.ARTOOLKIT):
        return "ARTOOLKIT"


led_count = 0
uart_count = 0
uart_flag = True
while(True):
    clock.tick()
    clk = utime.ticks_ms()

    img = sensor.snapshot()
    for tag in img.find_apriltags(families=tag_families): # defaults to TAG36H11 without "families".
        #img.draw_rectangle(tag.rect(), color = (255, 0, 0))
        #img.draw_cross(tag.cx(), tag.cy(), color = (0, 255, 0))
        print_args = (family_name(tag), tag.id(), (180 * tag.rotation()) / math.pi)
        print("Tag Family %s, Tag ID %d, rotation %f (degrees)" % print_args)
        uart.write(str(tag.id()))
        print(str(tag.id()))

    #uart_count = uart_count + 1

    #if uart_count < 10:
    #    uart.write("0")
    #    print(0)
    #if (uart_count < 20) and (uart_count >=10):
    #    uart.write("1")
    #    print(1)
    #if (uart_count < 30) and (uart_count >=20):
    #    print(2)
    #if uart_count >= 30:
    #    uart_count = 0

    led_count = led_count + 1
    if led_count >=4:
        ledBlue.on()
        led_count = 0
    else:
        ledBlue.off()

    while (clk + 100 > utime.ticks_ms()):
        pass

    #print(clock.fps())
