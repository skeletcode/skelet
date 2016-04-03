/* @flow */
import * as types from './actionTypes'
import fs from './modules/fs'
import { showError } from './modules/dialogs'

import ReactPlugin from './plugins/react-plugin'

type Action = any;

async function loadDirectoryFromFs(dispatch, directoryPath: string): Action {
  try {
    const children = await fs.readDir(directoryPath)

    dispatch({
      type: types.LOADED_DIRECTORY,
      tree: {
        path: directoryPath[directoryPath.length - 1] === '/' ? directoryPath.slice(0, -1) : directoryPath,
        isDir: true,
        children: children.filter(c => c.isDir).concat(children.filter(c => !c.isDir))
      }
    })
    //
    // TODO: batch prefetch on the native side?
    // children.filter(c => c.isDir).forEach(dir => loadDirectoryFromFs(dispatch, dir.path))
    //
  } catch (e) {
    showError(e);
  }
}

export function loadDirectory(directory: string): Action {
  return async (dispatch) => {
    dispatch({type: types.LOAD_DIRECTORY})
    return await loadDirectoryFromFs(dispatch, directory);
  }
}

export function toggleDirectory(directory: string): Action {
  return async (dispatch, getState) => {
    dispatch({type: types.TOGGLE_DIRECTORY, directory})
    if (getState().workingTree[directory].isExpanded) {
      return await loadDirectoryFromFs(dispatch, directory);
    }
  }
}

export function openFile(path: string): Action {
  return async (dispatch, getState) => {
    dispatch({type: types.OPEN_FILE, path})
    try {
      const content = await fs.openFile(path)
      dispatch({type: types.OPEN_FILE_SUCCESS, path, content})
      dispatch(highlightSyntax(path, content))
    } catch (e) {
      showError(e)
    }
  }
}

export function selectTab(path: string): Action {
  return {
    type: types.SELECT_TAB,
    path
  }
}

export function highlightSyntax(path:string, code: string): Action {
  try {
    const highlights = ReactPlugin(code);
    return {type: types.REACT_PLUGIN_CONTENT, path, highlights};
  }
  // because we can't get an AST each time
  catch (ex) {
    console.log(ex)
    return {type: '__ignore'};
  }
}

export function codeChanged(path: string, code: string): Action {
  return highlightSyntax(path, code)
}

function setupHotkeys() {
  // fs.onSavePressed(() => {
  //   try {
  //     fs.saveFile(DEMO_PATH, this.state.raw) // TODO: use a raw TextStorage
  //   } catch (e) {
  //
  //   }
  // })
}
