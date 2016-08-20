/* @flow */

import React from 'react'
import ReactNative from 'react-native-macos'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import * as Actions from '../actions';
import CodeArea from '../components/CodeArea'
import Tabs from '../components/Tabs'
import StatusBar from '../components/StatusBar'
import ReactMiddleware from '../plugins/react-plugin'
import setupMenubar from '../modules/menubar'
import TreeView from '../components/TreeView'

const {
  AppRegistry,
  StyleSheet,
  Text,
  TextInput,
  View,
  Linking,
  TouchableOpacity
} = ReactNative

/*
 * TODO: pass it from process, something like:
 * $ skelet .
 */
//const ENTRY_DIRECTORY = '/Users/potomushto/projects/skelet'

const App = React.createClass({

  componentWillMount() {
    /*
     * setup menubar
     */
    setupMenubar(this.props);
    /*
     * Load directory from the command line
     **/
    // console.log(process.argv)
    // if (process.argv && process.argv[0] && process.argv[0][0] !== '-') {
    //   this.props.loadDirectory(process.argv[0])
    // }
  },

  render() {

    const { props } = this;

    return (
      <View style={styles.container}>
        {this.props.workingTree && Object.keys(this.props.workingTree).length > 0 &&
          <View style={styles.leftPanel}>
            <TreeView {...props} />
          </View>
        }
        <View style={styles.innerContainer}>
          <Tabs {...props} />
          {
            this.props.tabs.map((tab, i) => {
            return <CodeArea
              key={i}
              onChange={(e) => this.props.codeChanged(this.props.tabs.filter(c => c.isSelected)[0].path, e.nativeEvent.text)}
              style={[styles.codeArea, tab.isSelected ? {} : { position: 'absolute' }]}
              text={tab.content}
              highlights={tab.highlights}
            />
          })}
          <StatusBar log={this.props.log} />
        </View>
      </View>
    )
  },
})

function mapStateToProps(state) {
  return state;
}

function mapDispatchToProps(dispatch) {
  return bindActionCreators(Actions, dispatch)
}

export default connect(mapStateToProps, mapDispatchToProps)(App);


const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    flex: 1
  },
  innerContainer: {
    flex: 1,
  },
  leftPanel: {
    width: 200,
    backgroundColor: '#423A3A'
  },
  rightArea: {
    flex: 1,
  },
  codeArea: {
    backgroundColor: '#fff',
    fontSize: 12,
    color: '#352F2F',
    fontFamily: 'FiraCode-Retina'
  },
});
