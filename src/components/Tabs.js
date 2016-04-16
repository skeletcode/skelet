/* @flow */
'use strict';

import React from 'react'
import ReactNative,  {
  View,
  Text,
  StyleSheet,
  TouchableHighlight,
  TouchableOpacity,
  TouchableWithoutFeedback,
  Animated,
  LayoutAnimation
} from 'react-native-desktop';

type TabState = {
  hovered: boolean
}

class Tab extends React.Component {

  state: TabState;

  constructor() {
    super();
    this.state = {
      hovered: false
    };
  }

  componentWillUpdate() {
    LayoutAnimation.configureNext({
      duration: 100,
      update: {
        type: LayoutAnimation.Types.linear,
      },
    });
  }

  render() {
    const {name, isSelected, path, onSelect, isNotSaved} = this.props;
    const additionalStyles = isSelected ? styles.active : (this.state.hovered ? styles.notActiveButHovered : styles.notActive);
    return (
      <TouchableOpacity
        style={[styles.tabWrapper, additionalStyles]}
        onMouseEnter={() => this.setState({hovered: true})}
        onMouseLeave={() => this.setState({hovered: false})}
        activeOpacity={0.7}
        onPress={() => onSelect(path)}>
          <View style={[styles.closeButton, {opacity: this.state.hovered ? 1 : 0}]}>
            <Text style={[styles.tabTitleClose]}>{'×'}</Text>
          </View>
          <Text style={[styles.tabTitle, isSelected ? {} : styles.nonActiveTitle]}>{name + (isNotSaved ? '*' : '')}</Text>
      </TouchableOpacity>
    );
  }
}

module.exports = React.createClass({
  render() {
    const tabs = this.props.tabs.map((t, i) => {
      return <Tab
        key={i}
        {...t}
        onSelect={this.props.selectTab} />
    });

    return (
      <View style={styles.tabs}>
        {tabs}
      </View>
    );
  }
});

const styles = StyleSheet.create({
  tabWrapper: {
    flex: 1,
    borderColor: '#bbb',
    borderLeftWidth: 0,
    borderRightWidth: 1,
    borderTopWidth: 0.5,
    borderBottomWidth: 0.5,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  tabs: {
    justifyContent: 'flex-start',
    height: 24,
    backgroundColor: 'white',
    alignItems: 'stretch',
    flexDirection: 'row'
  },
  tabTitle: {
    color: 'black',
    fontSize: 11
  },
  closeButton: {
    position: 'absolute',
    left: 5,
    top: -2, // temporary workaround
    height: 24,
    justifyContent: 'center',
    alignItems: 'center'
  },
  tabTitleClose: {
    fontSize: 20,
    padding: 0,
    margin: 0,
    fontWeight: '200'
  },
  active: {
    borderBottomWidth: 0,
    borderColor: 'white'
  },
  notActive: {
    backgroundColor: '#ddd',
  },
  notActiveButHovered: {
    backgroundColor: 'red'
  },
  nonActiveTitle: {
    color: '#777'
  }
});
