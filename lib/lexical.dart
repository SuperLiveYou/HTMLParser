import 'dart:io';

/// 令牌类型
enum TokenTypes {
  /// 解析错误
  error,

  /// 字符串，被"或者'包裹起来的文字
  string,

  /// 值，最常见的类型
  value,

  /// 特殊字符，必须要用&xx;的格式表示
  symbol,

  /// 操作符，仅限< /> = !
  operator,

  /// 空字符，在html里，所有的连续空字符（\t,\n,' '）会被解析为一个空格' '
  empty,

  /// 解析结束
  end,
}

/// 令牌结构体，用于储存每个被词法分析检查到的值相关的所有数据
class Token {
  final int pos;

  /// 所在的行数
  final int line;

  /// 具体值
  final String val;

  /// 具体类型
  final TokenTypes type;

  /// 没被裁剪过的值
  String? baseVal;

  /// 空字符，在html里，所有的连续空字符（\t,\n,' '）会被解析为一个空格' '
  Token.emptyType({
    required this.baseVal,
    required this.pos,
    required this.line,
  })  : type = TokenTypes.empty,
        val = " ";

  /// 字符串，被"包裹起来的文字
  Token.stringType({
    required this.val,
    required String capChar,
    required this.pos,
    required this.line,
  })  : type = TokenTypes.string,
        baseVal = "$capChar$val$capChar";

  /// 值，最常见的类型
  Token.valueType({
    required this.val,
    required this.pos,
    required this.line,
  }) : type = TokenTypes.value;

  /// 特殊字符，必须要用&xx;的格式表示
  Token.symbolType({
    required this.val,
    required this.pos,
    required this.line,
  })  : type = TokenTypes.symbol,
        baseVal = "&$val;";

  /// 操作符，仅限< />和=
  Token.operatorType({
    required this.val,
    required this.pos,
    required this.line,
  }) : type = TokenTypes.operator;

  /// 解析错误
  Token.errorType({
    required this.val,
    required this.pos,
    required this.line,
  }) : type = TokenTypes.error;

  /// 解析结束
  Token.endType({
    required this.pos,
    required this.line,
  })  : type = TokenTypes.end,
        val = "";
}

/// 词法分析
class Lexical {
  /// 起始行
  int _startLine = 0;
  int _startPos = 0;

  /// 储存代码的字符串
  final String code;

  /// 当前解析到的字符位置
  int len = 0;

  /// 当前解析到的行
  int line = 1;

  /// 开始解析的位置
  int pos = 1;

  /// 从字符串中读取
  Lexical.formString(this.code);

  /// 从给出的路径中读取
  Lexical.formFile(String path) : code = File(path).readAsStringSync();

  /// 检查索引是否到底了
  ///
  /// [nextIndex]用于确定是否检查下一个索引，默认检查当前索引
  bool _isEnd({bool nextIndex = false}) {
    return (nextIndex ? len + 1 : len) >= code.length;
  }

  /// 获取索引字符
  ///
  /// [addIndex]用于确定是否在得到字符后增加索引，
  /// 而[viewNext]用于确定是查看当前索引的字符还是下一个索引的字符
  String _getChar({bool addIndex = false, bool viewNext = false}) {
    // 如何在查看下一个索引的字符，并且下个字符位置到底了或者已经到底了
    if ((viewNext && _isEnd(nextIndex: true)) || _isEnd()) {
      // 返回空字符串
      return "";
    }
    String result = viewNext ? code[len + 1] : code[len];

    if (addIndex) {
      if (!_isEnd()) {
        if (code[len] == "\n") {
          line++;
          pos = 0;
        }
        pos++;
      }
      len++;
    }
    return result;
  }

  /// 捕获连续空字符
  Token? _emptyCapture() {
    bool hasEmpty = false;
    String baseVal = "";
    for (String char = _getChar();;
        char = _getChar(viewNext: true, addIndex: true)) {
      if (char == " " || char == "\t" || char == "\n") {
        baseVal += char;
        if (!hasEmpty) {
          hasEmpty = true;
        }
      } else {
        // 只有当它没有捕获成功的时候才会返回null
        if (!hasEmpty) {
          return null;
        }
        // 如果遇到结尾符，索引+1
        if (char == "") {
          _getChar(addIndex: true);
        }
        break;
      }
    }
    return Token.emptyType(baseVal: baseVal, pos: _startPos, line: _startLine);
  }

  /// 捕获以&xxx;为格式的特殊符号
  Token? _symbolCapture() {
    int currLen = len + 1;
    String val = "";

    for (String char = code[currLen];; char = code[currLen]) {
      // 不能有空格
      if (char == " " || char == "\t" || char == "\n" || char == "") {
        return null;
      } else {
        if (char == ";") {
          // 如果是"&;"这样的直接停止匹配
          if (val.isEmpty) {
            return null;
          } else {
            break;
          }
        }
        // 据我所知，里面的字符串不会超过十个字符，所以超过就停止匹配
        if (val.length >= 10) return null;
        val += char;
      }

      // 超过长度取消匹配
      if (currLen + 1 >= code.length) return null;
      currLen++;
    }
    len = currLen + 1;
    return Token.symbolType(val: val, pos: _startPos, line: _startLine);
  }

  /// 捕获字符串，"或者'内的内容
  ///
  /// [capChar]用于确定需要捕获结尾的符号
  Token _stringCapture({required String capChar}) {
    String val = "";
    _getChar(addIndex: true);
    // 用于无法匹配时忽略匹配字符
    int backLen = len;
    int backStartPos = _startPos;
    int backLine = _startLine;
    for (String char = _getChar();;
        char = _getChar(viewNext: true, addIndex: true)) {
      // 如果遇到换行或者结尾符，匹配失败
      if (char == "\n" || char == "") {
        len = backLen;
        _startLine = backLine;
        _startPos = backStartPos;
        return Token.valueType(val: capChar, pos: _startPos, line: _startLine);
      } else if (char == capChar) {
        _getChar(addIndex: true);
        break;
      } else {
        val += char;
      }
    }
    return Token.stringType(
        val: val, pos: _startPos, capChar: capChar, line: _startLine);
  }

  /// 捕获值
  Token? _valueCapture() {
    String val = "";
    loop:
    for (String char = _getChar();;
        char = _getChar(viewNext: true, addIndex: true)) {
      switch (char) {
        case " ":
        case "\t":
        case "\n":
        case "":
        // 忽略所有能被匹配到的非value类型
        case "<":
        case ">":
        case "=":
        case "!":
        case "/":
        // 因为&有可能因为无法解析导致跳转到value分支解析，所以捕获
        //case "&":
        case "\"":
        case "'":
          _getChar(addIndex: true);
          break loop;
      }
      val += char;
    }

    if (val.isEmpty) return null;
    return Token.valueType(val: val, pos: _startPos, line: _startLine);
  }

  /// 一次返回一个解析出的令牌
  Token getToken() {
    _startLine = line;
    _startPos = pos;
    // 是否结束，结束就直接返回
    if (_isEnd()) {
      return Token.endType(pos: _startPos, line: _startLine);
    }
    Token? emptyCap = _emptyCapture();
    if (emptyCap != null) return emptyCap;
    switch (_getChar()) {
      // 解析operator
      case "<":
        if (_getChar(addIndex: true, viewNext: true) == "/") {
          _getChar(addIndex: true);
          return Token.operatorType(
              val: "</", pos: _startPos, line: _startLine);
        } else {
          return Token.operatorType(val: "<", pos: _startPos, line: _startLine);
        }
      case "=":
      case "!":
      case ">":
        return Token.operatorType(
            val: _getChar(addIndex: true), pos: _startPos, line: _startLine);
      case "/":
        // 跳过'/'
        if (_getChar(addIndex: true, viewNext: true) == ">") {
          _getChar(addIndex: true);
          return Token.operatorType(
              val: "/>", pos: _startPos, line: _startLine);
        } else {
          return Token.valueType(val: "/", pos: _startPos, line: _startLine);
        }

      // 解析symbol
      case "&":
        Token? symbolCap = _symbolCapture();
        if (symbolCap != null) {
          return symbolCap;
        } else {
          // 跳转到value分支进行解析
          continue value;
        }
      // 解析string
      case "\"":
      case "'":
        return _stringCapture(capChar: _getChar());
      // value分支
      value:
      default:
        Token? valueCap = _valueCapture();
        if (valueCap == null) {
          break;
        } else {
          return valueCap;
        }
    }
    return Token.endType(pos: _startPos, line: _startLine);
  }
}
