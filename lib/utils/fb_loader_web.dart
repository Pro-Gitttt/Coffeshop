import 'dart:js' as js;

bool isFbLoaded() {
  return js.context['fbLoaded'] == true;
}
