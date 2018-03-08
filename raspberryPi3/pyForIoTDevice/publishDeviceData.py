from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient
import logging
import time
import argparse
import yaml
import json
import datetime
import calendar

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


with open('pyDeviceConfig.yml') as file:
    config = yaml.load(file)

host = config['deviceConfig']['host']
rootca = config['deviceConfig']['rootCaPath']
clientcert = config['deviceConfig']['certificatePath']
clientkey = config['deviceConfig']['privateKeyPath']
clientId = config['deviceConfig']['clientid']
topic = config['topicConfig']['test']

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

# test configure
humidity = "50"
temperature = "20"

# Publish to the same topic in a loop forever
while True:
    # timestamp
    now = datetime.datetime.utcnow()
    recordat = str(now.strftime("%Y-%m-%d"))
    timeStamp = str(calendar.timegm(now.utctimetuple()))

    # publish
    publishPayload = json.dumps({"recordat": recordat, "time_stamp": timeStamp, "uuid": clientId,  "room_humidity": humidity, "room_temperature": temperature})
    myAWSIoTMQTTClient.publishAsync(topic, publishPayload, 1, ackCallback=customPubackCallback)
    time.sleep(1)
