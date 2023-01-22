import './lexical.dart';

/// html标签结构
class Label {
  /// 标签中的内容
  final Label content;

  /// 标签中的属性
  Map<Token, Token> attributes;

  Label({required this.content, required this.attributes});
}

// html属性结构
class Attribute {
  String name;
  String value;
  Attribute({
    required this.name,
    required this.value,
  });
}

class Parser {
  Parser();
}
