import React from 'react';
import ReactNative from 'react-native-macos'

const { View, StyleSheet, Text } = ReactNative

module.exports = React.createClass({
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.statusBarText}>Last action: {this.props.log[this.props.log.length - 1]}</Text>
      </View>
    );
  }
});

const styles = StyleSheet.create({
  container: {
    height: 24,
    justifyContent: 'center',
    marginLeft: 15
    //alignItems: 'flex-end'
  },
  statusBarText: {
    fontFamily: 'FiraCode-Retina',
    color: '#888',
    fontSize: 10
  }
})
