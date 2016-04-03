import React from 'react-native-desktop'

const { MenuManager, NativeModules } = React;

export default function (actions) {

  MenuManager.addSubmenu('File',
  [
      {
        title: 'New File',
        key: 'n',
        callback: () => actions.newTab()
      },
      {
        title: 'Open Directory',
        key: 'O',
        callback: () => NativeModules.DialogManager
          .chooseDirectory()
          .then(directory => actions.loadDirectory(directory.replace('file://', '')))
      },
      {
        title: 'Save',
        key: 's',
        callback: () => actions.saveTab()
      }
  ]);
  MenuManager.addSubmenu('Edit',
  [
      {
        title: 'Undo',
        key: 'z',
        firstResponder: 'undo'
      },
      {
        title: 'Redo',
        key: 'Z',
        firstResponder: 'redo',
        separator: true
      },
      {
        title: 'Cut',
        key: 'x',
        firstResponder: 'cut:',
      },
      {
        title: 'Copy',
        key: 'c',
        firstResponder: 'copy:',
      },
      {
        title: 'Paste',
        key: 'v',
        firstResponder: 'paste:',
      },
      {
        title: 'Select All',
        key: 'a',
        firstResponder: 'selectAll:',
      },
      {
        title: 'Select Line',
        key: 'A',
        firstResponder: 'selectLines:',
        separator: true
      },
  ]);
}
