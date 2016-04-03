/* @flow */

import React from 'react-native-desktop'
import CodeArea from './CodeArea'
import Token from './Token'
import ReactMiddleware from './react-plugin'
import Tabs from './Tabs'
import WeNeedToGoDeeper from './WeNeedToGoDeeper'
import fs from './fs'

const {
  AppRegistry,
  StyleSheet,
  Text,
  TextInput,
  View,
  TouchableOpacity
} = React

const Group = Token
const TABS = ['index.osx.js', 'CodeArea.js', 'Token.js', 'Tabs.js']
const DEMO_PATH = '/Users/potomushto/projects/skelet/index.osx.js'

const SkeletApp = React.createClass({
  getInitialState() {
    return {
      code: '',
      raw: '',
      notSaved: false
    }
  },
  componentDidMount: async function() {
    const code = await fs.openFile(DEMO_PATH)
    this.setState({code, raw: code})
    //this.processCode(code)
    fs.onSavePressed(() => {
      try {
        fs.saveFile(DEMO_PATH, this.state.raw) //// TODO: just pass a textstorage link
      } catch (e) {

      }
    })
  },
  render() {
    return (
      <View style={styles.container}>
        <Tabs tabs={TABS} selectedTab={TABS[0]} notSaved={this.state.notSaved} onSelect={() => console.log('change File')}/>
        <View style={styles.innerContainer}>
          <CodeArea scrollStyle={styles.welcome} style={styles.input} onChange={this.onCodeChange}>
            <Group style={{fontSize: 10, fontFamily: 'FiraCode-Retina', color: '#888'}}>
              {this.state.raw}
            </Group>
          </CodeArea>
          { /*<WeNeedToGoDeeper /> */ }
        </View>
      </View>
    )
  },
  onCodeChange(e) {
    this.setState({
      notSaved: true,
      raw: e.nativeEvent.text
    })
    try {
      this.processCode(e.nativeEvent.text)
    }
    catch (e) {
      console.log(e);
    }

  },
  processCode(code: string) {
    //console.log(code)
    const start = new Date();
    const tokensToHighlight = ReactMiddleware(code)
    const lines = code.split('\n')

    const multiLineSlice = (s: string, start, end) => {
      if (start.line === end.line - 1) {
        return s + lines[start.line].slice(start.column, end.column);
      } else {
        return s +
          multiLineSlice(lines[start.line].slice(start.column, lines[start.line].length) + '\n',
            {line: start.line + 1, column: 0}, end)

      }

    }
    const tokensToRender = tokensToHighlight.reduce((state, t) => {
      if (state.line < (t.loc.start.line - 1) || (state.line === (t.loc.start.line - 1) && state.column < t.loc.start.column)) {
        // console.log(multiLineSlice('', {column: state.column, line: state.line}, t.loc.start))
        //console.log(t.loc.end, lines[t.loc.end.line].length)
        return {
          column: t.loc.end.column,
          line: t.loc.end.line - 1,
          tokens: state.tokens.concat([multiLineSlice('', {column: state.column, line: state.line}, t.loc.start), t.component])
        }
        //return state
      } else {
        // skip
        return state;
      }
    }, {
      column: 0,
      line: 0,
      tokens: []
    })

    if (tokensToRender.line < lines.length) {
      tokensToRender.tokens = tokensToRender.tokens.concat(
        [multiLineSlice('', {
          column: tokensToRender.column,
          line: tokensToRender.line
        },
        {
          line: lines.length,
          column: 0
        })]);
    }

    this.setState({code: tokensToRender.tokens})
    console.log('highlighted in', new Date() - start, 'ms');
  }
})


const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5FCFF',
  },
  innerContainer: {
    flexDirection: 'row'
  },
  rightArea: {
    flex: 1,
  },
  welcome: {
    backgroundColor: 'white',
    width: 300,
    height: 800, // TODO: dynamically
  },
  input: {
    flex: 1,
    margin: 10,
    height: 2200, // TODO: dynamically
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('skelet', () => SkeletApp);
