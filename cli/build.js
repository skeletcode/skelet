const execSync = require('child_process').execSync
const path = require('path')
const fs = require('fs')

const PROJECT_PATH = 'macos/skelet.xcodeproj'
const PLIST_PATH = 'macos/skelet/Info.plist'
const BUILD_DIR_NAME = 'build'

const buildDir = path.join(process.cwd(), BUILD_DIR_NAME)

const deleteFolderRecursive = function(path) {
  if( fs.existsSync(path) ) {
    fs.readdirSync(path).forEach(function(file,index){
      var curPath = path + "/" + file;
      if(fs.lstatSync(curPath).isDirectory()) { // recurse
        deleteFolderRecursive(curPath);
      } else { // delete file
        fs.unlinkSync(curPath);
      }
    });
    fs.rmdirSync(path);
  }
};

const mkdirSync = function (path) {
  try {
    deleteFolderRecursive(path)
    fs.mkdirSync(path);
  } catch(e) {
    if ( e.code != 'EEXIST' ) throw e;
  }
}

mkdirSync(buildDir)

const steps = [
  (`xcodebuild \
    -scheme skelet \
    -project ${PROJECT_PATH} \
    -archivePath ${path.join(buildDir, 'skelet.xcarchive')} \
    archive`),
  (`xcodebuild \
    -exportFormat APP \
    -exportArchive \
    -archivePath ${path.join(buildDir, 'skelet.xcarchive')} \
    -exportPath ${path.join(buildDir, 'Skelet')}`),
];
steps.forEach(step => execSync(step, { stdio: [0, 1, 2] }));
