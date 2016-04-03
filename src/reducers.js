/* @flow */
import * as types from './actionTypes'

const EMPTY_STRING = ''
const EMPTY_TAB = {
  emptyTab: true,
  name: 'untitled',
  isSelected: true,
  path: 'untitled'
}

type State = {
  workingTree: any,
  theme: any,
  tabs: Array<any>,
  log: Array<string>
}

const initialState: State = {
  workingTree: {},
  theme: {},
  tabs: [EMPTY_TAB],
  log: []
}

export default function reducer(state: State = initialState, action: any): State {

  // record actions here
  // TODO: replace with something more practical
  if (['REDUX_STORAGE_SAVE', '__ignore'].indexOf(action.type) === -1) {
    state = {...state, log: state.log.concat([action.type])}
  }

  switch (action.type) {
    case types.LOADED_DIRECTORY:

      return {
        ...state,
        workingTree: {
          ...state.workingTree,
          [action.tree.path] : {
            ...action.tree,
            ...state.workingTree[action.tree.path],
            children: action.tree.children.map(c => c.path)
          },
          ...action.tree.children.reduce((nodesMap, node, i) => {
            nodesMap[node.path] = node;
            return nodesMap;
          }, {})
        }
      }

    case types.TOGGLE_DIRECTORY:
      return {
        ...state,
        workingTree: {
          ...state.workingTree,
          [action.directory]: {
            ...state.workingTree[action.directory],
            isExpanded: !state.workingTree[action.directory].isExpanded
          }
        },
        selectedPath: action.directory
      }

    case types.OPEN_FILE:
      if (state.tabs.filter(tab => tab.path === action.path).length) {
        return {
          ...state,
          selectedPath: action.path,
          tabs: state.tabs.map(tab => {
            tab.isSelected = tab.path === action.path
            return tab
          })
        };
      } else {
        return {
          ...state,
          selectedPath: action.path,
          tabs: state.tabs.map(tab => {
            tab.isSelected = false
            return tab
          }).concat([{
              name: getNameFromPath(action.path),
              path: action.path,
              isNotSaved: false,
              isSelected: true,
              content: EMPTY_STRING
            }
          ])
        }
      }


    case types.OPEN_FILE_SUCCESS:
      return {
        ...state,
        tabs: state.tabs.map(tab => {
          if (tab.path === action.path) {
            tab.content = action.content
          }
          return tab
        })
      };

    case types.SELECT_TAB:

      return {
        ...state,
        tabs: state.tabs.map(tab => {
          tab.isSelected = tab.path == action.path
          return tab
        })
      };

    case types.REACT_PLUGIN_CONTENT:
      return {
        ...state,
        tabs: state.tabs.map(tab => {
          if (tab.path === action.path) {
            tab.highlights = action.highlights
          }
          return tab
        })
      }
    default:
      return state;
  }
}

function getNameFromPath(path) {
  return path.split('/').slice(-1)[0]
}

function selectWorkingTree(tab) {

}
