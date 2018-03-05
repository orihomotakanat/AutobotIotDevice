var awsIot = require('aws-iot-device-sdk');
var awsIoTconfig = require('config');


var device = awsIot.device({
    region: awsIoTconfig.deviceConfig.region,
    keyPath: awsIoTconfig.deviceConfig.privateKeyPath,
    certPath: awsIoTconfig.deviceConfig.certificatePath,
    caPath: awsIoTconfig.deviceConfig.rootCaPath,
    clientId: awsIoTconfig.deviceConfig.thing,
    host: awsIoTconfig.deviceConfig.host
    debug: true
});

var topic = awsIoTconfig.topicConfig.userdata

device.on('connect', function() {
    console.log('connect');
    setInterval( function() {
        device.publish(topic, JSON.stringify({ message: "Hello World"}));
    }, 1000); //per 1sec
});
