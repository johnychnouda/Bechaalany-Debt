import 'dart:html' as html;

class HtmlUtilsWeb {
  static void setTitle(String title) {
    html.document.title = title;
  }

  static String getTitle() {
    return html.document.title;
  }

  static void setMetaDescription(String description) {
    final metaDescription = html.document.querySelector('meta[name="description"]') as html.MetaElement?;
    if (metaDescription != null) {
      metaDescription.content = description;
    } else {
      final meta = html.MetaElement()
        ..name = 'description'
        ..content = description;
      html.document.head?.append(meta);
    }
  }

  static void addScript(String src) {
    final script = html.ScriptElement()
      ..src = src
      ..type = 'text/javascript';
    html.document.head?.append(script);
  }

  static void addStyle(String css) {
    final style = html.StyleElement()
      ..text = css;
    html.document.head?.append(style);
  }
}
