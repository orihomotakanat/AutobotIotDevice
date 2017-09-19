require 'mqtt'
require 'i2c'
require 'fileutils'
require 'json'
require 'pp'
require 'date'
require 'yaml'

class SwitchIoTDevice_OFF
  attr_accessor :signal, :shadowStatus
  def initialize(path, address = 0x27)
    #AWSIoT Read yaml - Common settings
    awsIoTconfig = YAML.load_file("rbDeviceConfig.yml")
    @host = awsIoTconfig["deviceConfig"]["host"]
    @port = awsIoTconfig["deviceConfig"]["port"]
    @certificate_path = awsIoTconfig["deviceConfig"]["certificatePath"]
    @private_key_path = awsIoTconfig["deviceConfig"]["privateKeyPath"]
    @root_ca_path = awsIoTconfig["deviceConfig"]["rootCaPath"]
    @thing = awsIoTconfig["deviceConfig"]["thing"]

    #Independent settings
    @topic = awsIoTconfig["topicConfig"]["controlOff"]
    @updateShadowTopic = awsIoTconfig["topicConfig"]["analysis"]
    @shadowStatus = 0

    #i2c settings
    @device = I2C.create(path)
    @address = address

    #signal
    @signal = signal
  end

  #wait publish from other device
  def waitOnPublish
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      puts "waiting publish from other device"
      client.subscribe(@topic) #thingName/control/off
      client.get #wait ios-app's publish
    end #MQTT end
  end

  #send signal to Air confitionar
  def sendSignal
    signal = system("bto_advanced_USBIR_cmd -d #{@signal}")
    if signal
      puts "sended signal to device"
    end
  end #def sendSignal end

  #shadowUpdate on = 1, off = 0
  def updateShadow
    MQTT::Client.connect(host:@host, port: @port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      client.publish(@updateShadowTopic, @shadowStatus)
    end
  end
end #class AwsIoTDevice

#Following are processed codes
raspberryPi3 = SwitchIoTDevice_OFF.new('/dev/i2c-1')

#Process.daemon(nochdir = true, noclose = nil)

loop do
  raspberryPi3.waitOnPublish
  raspberryPi3.signal = File.read("turnOff_btoAdvanced.txt")
  raspberryPi3.sendSignal

  raspberryPi3.shadowStatus = 0 #Turn OFF
  raspberryPi3.updateShadow
  sleep(2)
  raspberryPi3.updateShadow #re-send
end
