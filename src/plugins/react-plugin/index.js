import * as babylon from "babylon";
import traverse from "babel-traverse";
import * as t from "babel-types";
//const babel = require('babel-standalone')
// const presetReact = require('babel-preset-react')
// const preset2015 = require('babel-preset-es2015')
import React from 'react-native-macos'

const components = [];
const highlights = [];

type NSFontAttribute = 'NSForegroundColorAttributeName' | 'background' | 'underline';
type Node = {
  range: Array<number>,
  content: string,
  attribute: Dictionary<NSFontAttribute, string>
}

function highlightCode () {
  return {
    enter(path) {
      if (t.isStringLiteral(path.node)) {
        //console.log(path.node)
        // const node = {
        //   component: <Token style={{color: 'green'}} key={path.node.loc.start.line + '_' + path.node.loc.start.column}>
        //     {path.node.extra.raw}
        //   </Token>,
        //   loc: path.node.loc
        // }
        // components.push(node);

        highlights.push({
          range: [path.node.start, path.node.end - path.node.start],
          content: path.node.extra.raw,
          attributes: {
            'NSForegroundColorAttributeName' : React.processColor('#809459')
          }
        })
        return;
      }
      if (t.isIdentifier(path.node)) {

        // if (path.node.typeAnnotation) {
        //   path.node.loc.end.column = path.node.loc.start.column + path.node.name.length;
        //   //console.log(path.node)
        // }
        // const node = {
        //   component: <Token style={{color: '#222'}} key={path.node.loc.start.line + '_' + path.node.loc.start.column}>{path.node.name}</Token>,
        //   loc: path.node.loc
        // }
        // if (components.filter(c => c.loc.start.line === path.node.loc.start.line && c.loc.start.column === path.node.loc.start.column).length === 0) {
        //     components.push(node);
        // }
        highlights.push({
          range: [path.node.start, path.node.end - path.node.start],
          content: path.node.name,
          attributes: {
            'NSForegroundColorAttributeName' : React.processColor('#395F5F')
          }
        })
        return;
      }
      if (t.isJSXIdentifier(path.node)) {
        highlights.push({
          range: [path.node.start, path.node.end - path.node.start],
          content: path.node.name,
          attributes: {
            'NSForegroundColorAttributeName' : React.processColor('#395F5F')
          }
        })
        return;
      }
    }
  };
}

function extractComments(comments: Array<string>) {

  return comments.map(comment => {
    return {
      range: [comment.start, comment.end - comment.start],
      content: comment.value,
      attributes: {
        'NSForegroundColorAttributeName' : React.processColor('#bbb')
      }
    }
  })
}

// TODO: get AST, not text
// so middleware become real
export default function middleware(code: string): any {
  if (!code) {
    return []
  }
  highlights = []
  const s = new Date();
  const ast = babylon.parse(code, {
    sourceType: "module",
    plugins: [
      "jsx",
      "asyncFunctions",
      "flow",
      "classConstructorCall",
      "doExpressions",
      "trailingFunctionCommas",
      "objectRestSpread",
      "decorators",
      "classProperties",
      "exportExtensions",
      "exponentiationOperator",
      "asyncGenerators",
      "functionBind",
      "functionSent",
    ],
    comments: true
  });
  traverse(ast, highlightCode());
  // TODO: write in status bar
  console.log('babylon: parsed in', new Date() - s, 'ms');
  return highlights.concat(extractComments(ast.comments));
}
