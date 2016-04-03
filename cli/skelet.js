#!/usr/bin/env node
/*
 * TODO:
 * validate arguments
 * show help
 * run different modes
 **/
const skeletArgs = process.argv.slice(2)

const exec = require('child_process').exec

const fs = require('fs')
const path = require('path')

const pathToBinary = path.join(
  path.dirname(fs.realpathSync(process.argv[1])),
  '..',
  'build',
  'Skelet.app')

try {
    fs.accessSync(pathToBinary, fs.F_OK);
    exec('open ' + pathToBinary, skeletArgs,  (error, stdout, stderr) => {
      if (error) {
        throw error;
      }
    })

} catch (e) {
    console.error('Skelet.app not found:', e)
}

process.exit(0);
