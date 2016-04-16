/**
 * @providesModule EditableText
 * @flow
 */
'use strict';

import React from 'react';
const ReactNative = require('react-native-desktop');

const {
  PropTypes,
  StyleSheet,
  ScrollView,
  Text,
  requireNativeComponent,
  TouchableWithoutFeedback,
} = ReactNative;

const SkeletTextView = requireNativeComponent('SKTextView', null);

const styles = StyleSheet.create({
  default: {
    flex: 1,
    padding: 0,
  },
});

class CodeArea extends React.Component {
  props: {
    text: string,
    style: any,
    highlights: Array<any>
  };

  render() {
    return (
        <SkeletTextView
          {...this.props}
          highlightLineColor={'rgba(66, 58, 58, 0.02)'}
          style={[styles.default, this.props.style]}
        />

    );
  }
}

// EditableText.childContextTypes = {
//     isInAParentText: React.PropTypes.bool
// }

module.exports = CodeArea;
