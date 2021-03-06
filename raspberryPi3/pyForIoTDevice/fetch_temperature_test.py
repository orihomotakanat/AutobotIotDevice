import time
import smbus

def fetchTemperature(): # For HIH6130sensor
    i2c = smbus.SMBus(1)
    buf = i2c.read_i2c_block_data(0x27, 0, 4)

    status = buf[0] >> 6 & 0x03 # get status

    # Digital output
    humidity_digit = (buf[0] & 0x3F) * 256 + buf[1]
    temperature_digit = buf[2] * 64 + (buf[3] >> 2)

    # Convert output
    humidity = round(humidity_digit / 16383.0 * 100, 8)
    temperature = round(temperature_digit / 16383.0 * 165 - 40, 8)

    return temperature, humidity

try:
    while True:
        output = fetchTemperature()
        print(output)
        time.sleep(1)
except KeyboardInterrupt:
    pass
