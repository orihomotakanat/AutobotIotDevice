require 'mqtt'
require 'i2c'
require 'fileutils'
require 'json'
require 'pp'
require 'date'
require 'yaml'

class AwsIoTDevice
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
    @topic = awsIoTconfig["topicConfig"]["userdata"]

    #i2c settings
    @device = I2C.create(path)
    @address = address

    @temperature = 0
    @humidity = 0
    @timeStamp = 0
  end

  #fetch Humidity & Temperature with i2c device
  def fetch_humidity_temperature
    s = @device.read(@address, 0x04)
    hum_h, hum_l, temp_h, temp_l = s.bytes.to_a

    status = (hum_h >> 6) & 0x03
    hum_h = hum_h & 0x3f
    hum = (hum_h << 8) | hum_l
    temp = ((temp_h << 8) | temp_l) / 4

    @temperature = temp * 1.007e-2 - 40.0
    @humidity = hum * 6.10e-3
    @timeStamp = Time.now.to_i

    deviceData = JSON.generate({"uuid" => @thing, "timeStamp" => @timeStamp, "data" => {"roomHumidity" => @humidity, "roomTemperature" => @temperature}})
    return deviceData
  end #def fetch_humidity_temperature end

  #Publish device data to AWSIoT
  def publishDeviceData
    payload = fetch_humidity_temperature
    MQTT::Client.connect(host:@host, port: @port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      client.publish(@topic, payload)
    end
  end #def publishDeviceData end
end #class AwsIoTDevice

#Following are processed codes
raspberryPi3 = AwsIoTDevice.new('/dev/i2c-1')

Process.daemon #Become daemon process

loop do
  puts raspberryPi3.fetch_humidity_temperature
  raspberryPi3.publishDeviceData
  sleep(120)#(180)
end
