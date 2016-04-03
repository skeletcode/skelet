/**
 * @providesModule Token
 * @flow
 */
'use strict';

const React = require('react-native-desktop');

const {
  PropTypes,
  StyleSheet,
  requireNativeComponent,
  TouchableWithoutFeedback,
} = React;

var createReactNativeComponentClass =
  require('createReactNativeComponentClass');
var merge = require('merge');
var ReactNativeViewAttributes = require('ReactNativeViewAttributes');

var viewConfig = {
  validAttributes: merge(ReactNativeViewAttributes.UIView, {
    isHighlighted: true,
    numberOfLines: true,
    allowFontScaling: true,
  }),
  uiViewClassName: 'SkeletShadowText',
};

const SkeletToken = createReactNativeComponentClass(viewConfig);//requireNativeComponent('SkeletToken', null);

class Token extends React.Component {
  render() {
    return (
      <SkeletToken props={this.props} />
    );
  }
  getChildContext() {
    return {isInAParentText: true};
  }
}

module.exports = SkeletToken;
