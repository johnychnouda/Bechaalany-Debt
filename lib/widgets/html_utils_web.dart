// Web-specific HTML utilities
import 'dart:html' as html;

class HTMLUtils {
  static html.Blob createBlob(List<int> bytes, String type) {
    return html.Blob([bytes], type);
  }
  
  static String createObjectUrl(html.Blob blob) {
    return html.Url.createObjectUrlFromBlob(blob);
  }
  
  static void revokeObjectUrl(String url) {
    html.Url.revokeObjectUrl(url);
  }
  
  static html.AnchorElement createAnchor(String href) {
    return html.AnchorElement(href: href);
  }
  
  static void openInNewTab(String url) {
    html.window.open(url, '_blank');
  }
}

