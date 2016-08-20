/* @flow */
'use strict';

import React from 'react';
import ReactNative,  {
  View,
  Text,
  StyleSheet,
  TouchableHighlight,
  TouchableWithoutFeedback,
  TouchableOpacity,
  Animated,
  ScrollView,
  LayoutAnimation
} from 'react-native-macos';

import Icon from 'react-native-vector-icons/Octicons'
import Ionicon from 'react-native-vector-icons/Ionicons'

const Node = ({
  path,
  filename,
  isDir,
  isExpanded,
  isSelected,
  children,
  onPress
}) => {
  return (
    <View style={{marginLeft: 10}}>

      <TouchableOpacity style={[styles.node, isSelected ? styles.selectedNode : {}]} onPress={onPress} activeOpacity={0.7}>

        {isDir &&
          <Ionicon name={isExpanded ? 'ios-arrow-down' : 'ios-arrow-right'} size={10} style={{color: '#ccc', marginRight: 6}} />
        }
        <Icon name={isDir ? 'file-directory' : 'file-text'} size={15} style={{color: '#ccc', marginLeft: isDir ? 0 : 12, marginRight: 8}}/>
        <Text style={[styles.filename, isSelected ? styles.selectedFilename : {}]}>{filename}</Text>

      </TouchableOpacity>

      {children}

    </View>
  );
}

module.exports = React.createClass({

  render() {
    const { workingTree } = this.props;

    if (!workingTree || Object.keys(workingTree).length === 0) {
      return <View />
      //<View style={styles.container}><Text style={styles.message}>{'Press cmd+o\n to open directory'}</Text></View>
    }

    const currentProjectPath = Object.keys(workingTree)[0]
    const tree = this._buildSubtree(workingTree[currentProjectPath].children)

    return (
      <ScrollView style={styles.container} showsVerticalScrollIndicator={true}>
        <Node isDir={true} isExpanded={true} filename={this._getDirectoryName(currentProjectPath)}>
          {tree}
        </Node>
      </ScrollView>
    );
  },

  _buildSubtree(children: any): any {
    const { workingTree } = this.props;
    return children && children.map(nodePath =>
      <Node
        {...workingTree[nodePath]}
        key={nodePath}
        isSelected={this.props.selectedPath === nodePath}
        onPress={() =>
          workingTree[nodePath].isDir ? this.props.toggleDirectory(nodePath) : this.props.openFile(nodePath)
        }>
        {workingTree[nodePath].isExpanded ? this._buildSubtree(workingTree[nodePath].children) : null}
      </Node>
    )
  },

  _getDirectoryName(dir: string): string {
    return dir.split('/').slice(-1)[0]
  }
});

const styles = StyleSheet.create({
  container: {
    marginHorizontal: 0,
    marginTop: 25
  },
  node: {flexDirection: 'row', alignItems: 'center', paddingVertical: 4},
  selectedNode: {backgroundColor: '#444'},
  filename: {
    color: '#bbb',
    fontSize: 12,
  },
  selectedFilename: {
    color: '#ddd'
  },
  message: {
    color: '#aaa',
    fontSize: 12,
    textAlign: 'center'
  }
});
