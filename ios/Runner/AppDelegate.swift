import UIKit
import Flutter
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // Google Sign-In configuration
    // Use hardcoded client ID from GoogleService-Info.plist for now
    let clientId = "908856160324-rifpo3dibqilhhee82mfcchc9t8rd500.apps.googleusercontent.com"
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Google Sign-In URL handling
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
  }
}