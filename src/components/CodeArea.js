/**
 * @providesModule EditableText
 * @flow
 */
'use strict';

const React = require('react-native-desktop');

const {
  PropTypes,
  StyleSheet,
  ScrollView,
  Text,
  requireNativeComponent,
  TouchableWithoutFeedback,
} = React;

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
