import 'package:html_parser/html.dart';
import 'package:belatuk_json_serializer/belatuk_json_serializer.dart'
    as jsonSerializer;

void main(List<String> arguments) async {
  var test = Parser(
    code: """div 
        
        
        
        id="js-global-screen-reader-notice" class="sr-only" aria-live="polite"></div>""",
  );
  print(jsonSerializer.serialize(test.start()));

  //print((await XApi.getForum(id: 30))[0]);
}
