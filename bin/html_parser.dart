import 'package:html_parser/html.dart';

void main(List<String> arguments) async {
  var test = Lexical.formString("""
    <div id="js-global-screen-reader-notice" class="sr-only" aria-live="polite"></div>
""");
  for (;;) {
    Token token = test.getToken();
    if (token.type == TokenTypes.end) break;
    print(
        "line=${token.line} pos=${token.pos} type=${token.type} value=${token.baseVal ?? token.val}");
  }

  //print((await XApi.getForum(id: 30))[0]);
}
