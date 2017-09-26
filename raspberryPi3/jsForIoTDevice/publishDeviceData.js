var awsIot = require('aws-iot-device-sdk');
var awsIoTconfig = require('config');



/*
var device = awsIot.device({
    region: 'ap-northeast-1',
    keyPath: 'priv.pem.key',
    certPath: 'cer.pem.crt',
    caPath: 'rootCA.crt',
    clientId: 'xxx',
    host: 'a1arvj4dhixpps.iot.ap-northeast-1.amazonaws.com'
});
*/
console.log(awsIoTconfig.deviceConfig.host);

/*
device.on('connect', function() {
    console.log('connect');
    setInterval( function() {
        device.publish('tomtanDevice/temperature', "Publish msg to clientID:testA");
        //device.publish('Raspi/tomtanDevice', "Publish msg to clientID:testA");
    }, 1);
});
*/
