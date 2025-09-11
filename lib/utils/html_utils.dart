// Platform-specific imports
import 'html_utils_stub.dart'
    if (dart.library.html) 'html_utils_web.dart';

// Re-export the appropriate implementation
export 'html_utils_stub.dart'
    if (dart.library.html) 'html_utils_web.dart';
