# Autobot code for your iotDevice

## RaspberryPi3 settings
1. Check serial number of your raspberryPi

```
$ cat /proc/cpuinfo | grep Serial | awk '{print $3}'
```

## Ruby code for IoT device (rbForIoTDevice/)

**Attention!!**  
aws-iot-device-sdk for Ruby has not been published by AWS. Therefore, we use 3rd party library; "mqtt".
If you use this language, you have to run `$ gem install mqtt`.
