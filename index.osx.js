/* @flow */
import React from 'react-native-desktop';
const { View, Dimensions, AppRegistry } = React;

import { createStore, applyMiddleware} from 'redux';
import { Provider } from 'react-redux';

// redux middleware for async actions
import thunk from 'redux-thunk';

// redux middleware for loggin via console.log
import createLogger from 'redux-logger';

// redux middleware for storage the state into disk
import storage, { decorators } from 'redux-storage';
import createEngine from './src/modules/redux-storage-engine';
import debounce from 'redux-storage-decorator-debounce'

import reducer from './src/reducers';
import AppContainer from './src/containers/App';

// delay saving state to disk for 10 seconds
const engine = debounce(createEngine('skelet'), 5000);

// configure logger
const loggerOptions = {
  duration: true,
  predicate: (getState, action) => action.type !== '__ignore'
}

const wrappedReducer = storage.reducer(reducer);
const storageMiddleware = storage.createMiddleware(engine, ['__ignore']);

const middleware = process.env.NODE_ENV === 'production' ?
  [ thunk, storageMiddleware ] :
  [ thunk, storageMiddleware, createLogger(loggerOptions) ];

const createStoreWithMiddleware = applyMiddleware(...middleware)(createStore);
const store = createStoreWithMiddleware(wrappedReducer);


class SkeletApp extends React.Component{
  componentWillMount() {
    const load = storage.createLoader(engine);
    //load(store);
  }

  render() {
    return (
      <Provider store={store}>
        <AppContainer />
      </Provider>
    )
  }
};

AppRegistry.registerComponent('skelet', () => SkeletApp);
