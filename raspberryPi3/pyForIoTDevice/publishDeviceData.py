from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient
import logging
import time
import argparse
import yaml
import json
import datetime
import calendar
import smbus

# General message notification callback
def customOnMessage(message):
    print("Received a new message: ")
    print(message.payload)
    print("from topic: ")
    print(message.topic)
    print("--------------\n\n")


# Suback callback
def customSubackCallback(mid, data):
    print("Received SUBACK packet id: ")
    print(mid)
    print("Granted QoS: ")
    print(data)
    print("++++++++++++++\n\n")


# Puback callback
def customPubackCallback(mid):
    print("Received PUBACK packet id: ")
    print(mid)
    print("++++++++++++++\n\n")

# Fetch temperature & humidity
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

# Read configure
with open('pyDeviceConfig.yml') as file:
    config = yaml.load(file)

host = config['deviceConfig']['host']
rootca = config['deviceConfig']['rootCaPath']
clientcert = config['deviceConfig']['certificatePath']
clientkey = config['deviceConfig']['privateKeyPath']
clientId = config['deviceConfig']['clientId']
topic = config['topicConfig']['testtopic']

# For confirmation of each path
print("Endpoint: " + host + "\n" \
        "RootCA path: " + rootca + "\n" \
        "clientcert path: " + clientcert + "\n" \
        "clientkey path: " + clientkey + "\n" \
        "clientId: " + clientId + "\n" \
        "topic: " + topic + "\n")


# Configure logging
logger = logging.getLogger("AWSIoTPythonSDK.core")
logger.setLevel(logging.DEBUG)
streamHandler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
streamHandler.setFormatter(formatter)
logger.addHandler(streamHandler)


# Init AWSIoTMQTTClient (Not use websocket)
myAWSIoTMQTTClient = None
myAWSIoTMQTTClient = AWSIoTMQTTClient(clientId)
myAWSIoTMQTTClient.configureEndpoint(host, 8883)
myAWSIoTMQTTClient.configureCredentials(rootca, clientkey, clientcert)

# AWSIoTMQTTClient connection configuration
myAWSIoTMQTTClient.configureAutoReconnectBackoffTime(1, 32, 20)
myAWSIoTMQTTClient.configureOfflinePublishQueueing(-1)  # Infinite offline Publish queueing
myAWSIoTMQTTClient.configureDrainingFrequency(2)  # Draining: 2 Hz
myAWSIoTMQTTClient.configureConnectDisconnectTimeout(10)  # 10 sec
myAWSIoTMQTTClient.configureMQTTOperationTimeout(5)  # 5 sec
myAWSIoTMQTTClient.onMessage = customOnMessage

# Connect and subscribe to AWS IoT
myAWSIoTMQTTClient.connect()
# Note that we are not putting a message callback here. We are using the general message notification callback.
myAWSIoTMQTTClient.subscribeAsync(topic, 1, ackCallback=customSubackCallback)
time.sleep(2)

# Publish to the same topic in a loop forever
while True:
    # timestamp
    now = datetime.datetime.utcnow()
    recordat = str(now.strftime("%Y-%m-%d"))
    timeStamp = str(calendar.timegm(now.utctimetuple()))

    # publish
    output = fetchTemperature() # output[0] = temperature, output[1] = humidity
    publishPayload = json.dumps({"recordat": recordat, "time_stamp": timeStamp, "uuid": clientId,  "room_humidity": output[1], "room_temperature": output[0]})
    myAWSIoTMQTTClient.publishAsync(topic, publishPayload, 1, ackCallback=customPubackCallback)
    time.sleep(1)
