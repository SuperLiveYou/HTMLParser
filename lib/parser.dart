import './lexical.dart';

/// html标签结构
class Tag {
  /// html标签的名称
  final String name;

  /// 只有当name=<Text>的时候才应该有值
  final String text;

  /// 标签中的内容
  Tag? content;

  /// 标签中的属性
  Map<String, String>? attributes;
  Tag({
    required this.name,
    this.content,
    this.attributes,
  }) : text = "";

  /// 文本值
  Tag.text({required this.text}) : name = "<Text>";
}

/// 语法分析
class Parser {
  Lexical lexical;

  /// 上一个单词
  late Token preToken;

  /// 当前单词
  late Token token;

  /// 启用严格模式，默认为false
  ///
  /// 严格模式中不会忽略语法错误，一旦遇到语法错误就会进入恐慌模式
  bool strictMode;

  /// 使用原值替代empty类型的值，默认为false
  ///
  /// 启用时在empty类型需要token.val时会优先使用token.baseVal的值
  bool innerEmptyText;

  /// 文本拦截器
  ///
  /// 每次解析到文本时准备压入字符串的时候都会调用，可以通过返回Token来达到更改解析内容的目的
  Token? Function(Token token)? textInterceptor;

  /// 标签拦截器
  ///
  /// 每次解析完Tag的时候都会调用，可以通过返回Tag来达到更改解析内容的目的
  Tag? Function(Tag tag)? tagInterceptor;
  Parser({
    required String code,
    this.strictMode = false,
    this.innerEmptyText = false,
    this.textInterceptor,
    this.tagInterceptor,
  }) : lexical = Lexical(code: code) {
    token = lexical.nextToken();
  }

  /// 恐慌模式
  void _panic() {}

  /// 获取token.value
  String _getTokenValue(Token token) {
    if ((innerEmptyText && token.type == TokenTypes.empty) ||
        token.type == TokenTypes.string) {
      return token.baseVal ?? token.val;
    }
    return token.val;
  }

  /// 获取下一个token
  Token _getNextToken() {
    preToken = token;
    token = lexical.nextToken();
    return token;
  }

  /// 检查token的类型和值是不是正确的
  ///
  /// [skipEmpty]用于跳过empty类型，一旦遇到就会略过并向下寻找（不会调用_getNextToken覆盖记录）
  bool _checkToken(
      {required TokenTypes type, String? value, bool skipEmpty = false}) {
    if (skipEmpty) {
      // 因为词法分析器的特性，连续出现的empty类型将被合并成一个Token，所以检查到可以直接忽略empty
      if (token.type == TokenTypes.empty) {
        token = lexical.nextToken();
      }
    }
    if (token.type == type) {
      if (value == null) {
        return true;
      } else if (token.val == value) {
        return true;
      }
    }
    return false;
  }

  /// 匹配属性
  Map<String, String>? _matchAttributes() {}
  String _matchText() {
    String text = "";
    while (!(_checkToken(type: TokenTypes.operator, value: "<") ||
        _checkToken(type: TokenTypes.operator, value: "</") ||
        _checkToken(type: TokenTypes.end))) {
      Token? result =
          (textInterceptor != null) ? textInterceptor!(token) : null;
      if (result == null) {
        text += _getTokenValue(token);
      } else {
        text += _getTokenValue(result);
      }

      _getNextToken();
    }
    return text;
  }

  /// 匹配tag
  Tag _matchTag() {
    if (_checkToken(type: TokenTypes.operator, value: "<")) {}
    return Tag.text(text: _matchText());
  }

  Tag start() {
    return _matchTag();
  }
}
