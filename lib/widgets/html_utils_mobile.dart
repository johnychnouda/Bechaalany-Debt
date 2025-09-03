// Mobile-specific HTML utilities (stub implementation)
class HTMLUtils {
  static StubBlob createBlob(List<int> bytes, String type) {
    return StubBlob(bytes, type);
  }
  
  static String createObjectUrl(StubBlob blob) {
    return '';
  }
  
  static void revokeObjectUrl(String url) {
    // No-op on mobile
  }
  
  static StubAnchorElement createAnchor(String href) {
    return StubAnchorElement(href: href);
  }
  
  static void openInNewTab(String url) {
    // No-op on mobile
  }
}

class StubBlob {
  final List<int> bytes;
  final String type;
  
  StubBlob(this.bytes, this.type);
}

class StubAnchorElement {
  final String? href;
  
  StubAnchorElement({String? href}) : href = href;
  
  void setAttribute(String name, String value) {
    // No-op on mobile
  }
  
  void click() {
    // No-op on mobile
  }
}

