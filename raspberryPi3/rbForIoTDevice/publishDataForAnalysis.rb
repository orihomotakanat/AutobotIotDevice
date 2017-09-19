require 'mqtt'
require 'i2c'
require 'fileutils'
require 'json'
require 'pp'
require 'date'
require 'yaml'

class AwsIoTRuleToKinesis
  attr_accessor :shadow #pseudo-deviceShadow
  def initialize(path, address = 0x27, shadow = 0)
    #AWSIoT Read yaml - Common settings
    awsIoTconfig = YAML.load_file("rbDeviceConfig.yml")
    @host = awsIoTconfig["deviceConfig"]["host"]
    @port = awsIoTconfig["deviceConfig"]["port"]
    @certificate_path = awsIoTconfig["deviceConfig"]["certificatePath"]
    @private_key_path = awsIoTconfig["deviceConfig"]["privateKeyPath"]
    @root_ca_path = awsIoTconfig["deviceConfig"]["rootCaPath"]
    @thing = awsIoTconfig["deviceConfig"]["thing"]
    @certid = awsIoTconfig["deviceConfig"]["certID"]

    #Independent settings
    @topic = awsIoTconfig["topicConfig"]["analysis"]

    #i2c settings
    @device = I2C.create(path)
    @address = address

    @shadow = shadow #TunrnedOnAircon -> 1, TurnedOffAircon -> 0
    @temperature = 0
    @humidity = 0
    @timeStamp = 0
  end

  #fetch Humidity & Temperature with i2c device
  def fetchDeviceData
    s = @device.read(@address, 0x04)
    hum_h, hum_l, temp_h, temp_l = s.bytes.to_a

    status = (hum_h >> 6) & 0x03
    hum_h = hum_h & 0x3f
    hum = (hum_h << 8) | hum_l
    temp = ((temp_h << 8) | temp_l) / 4

    @temperature = temp * 1.007e-2 - 40.0
    @humidity = hum * 6.10e-3
    @timeStamp = Time.now.to_i

    #** setした温度に達したら自動的にshadow -> 0になる機能は削除 **
    tuple = JSON.generate({"uuid" => @thing, "certid" => @certid, "timeFromDevice" => @timeStamp, "roomTemperature" => @temperature, "roomHumidity" => @humidity, "shadow" => @shadow})
    return tuple
  end #def fetch_humidity_temperature end

  #shadowStatusGetter
  def shadowStatus
    MQTT::Client.connect(host:@host, port:@port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      client.subscribe(@topic) #subscribe message of airconmode
      topic, @shadow = client.get
      #puts topic #published topic thingName/analysis
      puts @shadow #published message
    end #MQTT end
  end #def shadowStatus end

  #Publish device data to AWSIoT
  def publishToKinesis
    payload = fetchDeviceData
    MQTT::Client.connect(host:@host, port: @port, ssl: true, cert_file:@certificate_path, key_file:@private_key_path, ca_file: @root_ca_path) do |client|
      client.publish(@topic, payload)
    end
  end #def publishDeviceData end
end #class AwsIoTDevice

#Following are processed codes
raspberryPi3 = AwsIoTRuleToKinesis.new('/dev/i2c-1')

#Process.daemon(nochdir = true, noclose = nil) #Become daemon process

loop do
  begin
  Timeout.timeout(3) do #wait 3 sec and if timeouts -> call rescue
      raspberryPi3.shadowStatus
      puts "Received shadow status" + raspberryPi3.shadowStatus
  end
  rescue Timeout::Error
    puts "fetch device" + raspberryPi3.fetchDeviceData
  end
  #raspberryPi3.publishToKinesis
end
