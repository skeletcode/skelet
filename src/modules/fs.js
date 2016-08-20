const RCTDeviceEventEmitter = require('RCTDeviceEventEmitter');
import React from 'react-native-macos'
const { NativeModules } = React
const { FilesystemManager } = NativeModules

FilesystemManager.onSavePressed = (handler) => {
  RCTDeviceEventEmitter.addListener(
    'onFileSavePressed',
    () => {
      console.log('listener invoked')
      handler();
    }
  )
}


module.exports = FilesystemManager
