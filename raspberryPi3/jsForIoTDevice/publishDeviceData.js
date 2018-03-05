var awsIot = require('aws-iot-device-sdk');
var awsIoTconfig = require('config');


var device = awsIot.device({
    region: awsIoTconfig.deviceConfig.region,
    keyPath: awsIoTconfig.deviceConfig.privateKeyPath,
    certPath: awsIoTconfig.deviceConfig.certificatePath,
    caPath: awsIoTconfig.deviceConfig.rootCaPath,
    clientId: awsIoTconfig.deviceConfig.thing,
    host: awsIoTconfig.deviceConfig.host
});

var topic = awsIoTconfig.topicConfig.userdata

device.on('connect', function() {
    console.log('connect');
    setInterval( function() {
        device.publish(topic, "--temperature&humidity--");
    }, 1);
});
