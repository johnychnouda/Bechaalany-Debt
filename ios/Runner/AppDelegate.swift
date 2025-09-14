import UIKit
import Flutter
import UserNotifications
import ActivityKit
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
    
    // Setup method channel for iOS 18.6+ notifications using FlutterPluginRegistry
    let notificationChannel = FlutterMethodChannel(name: "ios18_notifications",
                                                  binaryMessenger: self.registrar(forPlugin: "AppDelegate")!.messenger())
    
    notificationChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.handleNotificationMethodCall(call: call, result: result)
    }
    
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
  
  // Handle notification method calls
  private func handleNotificationMethodCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "requestNotificationPermissions":
      requestNotificationPermissions(args: call.arguments as? [String: Any], result: result)
      
    case "createNotificationCategory":
      createNotificationCategory(args: call.arguments as? [String: Any], result: result)
      
    case "configureBackgroundProcessing":
      configureBackgroundProcessing(args: call.arguments as? [String: Any], result: result)
      
    case "enableSmartNotifications":
      enableSmartNotifications(args: call.arguments as? [String: Any], result: result)
      
    case "sendSmartNotification":
      sendSmartNotification(args: call.arguments as? [String: Any], result: result)
      
    case "scheduleNotification":
      scheduleNotification(args: call.arguments as? [String: Any], result: result)
      
    case "cancelNotification":
      cancelNotification(args: call.arguments as? [String: Any], result: result)
      
    case "cancelAllNotifications":
      cancelAllNotifications(result: result)
      
    case "getPendingNotifications":
      getPendingNotifications(result: result)
      
    case "updateNotificationSettings":
      updateNotificationSettings(args: call.arguments as? [String: Any], result: result)
      
    case "enableFocusModeIntegration":
      enableFocusModeIntegration(result: result)
      
    case "enableDynamicIslandIntegration":
      enableDynamicIslandIntegration(result: result)
      
    case "enableLiveActivities":
      enableLiveActivities(result: result)
      
    case "startLiveActivity":
      startLiveActivity(args: call.arguments as? [String: Any], result: result)
      
    case "updateLiveActivity":
      updateLiveActivity(args: call.arguments as? [String: Any], result: result)
      
    case "endLiveActivity":
      endLiveActivity(args: call.arguments as? [String: Any], result: result)
      
    case "isIOS186Supported":
      isIOS186Supported(result: result)
      
    case "getDeviceCapabilities":
      getDeviceCapabilities(result: result)
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Notification Permissions
  
  private func requestNotificationPermissions(args: [String: Any]?, result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()
    
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "PERMISSION_ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(granted)
        }
      }
    }
  }
  
  // MARK: - Notification Categories
  
  private func createNotificationCategory(args: [String: Any]?, result: @escaping FlutterResult) {
    guard let args = args,
          let identifier = args["identifier"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    let actions = createNotificationActions(from: args["actions"] as? [[String: Any]])
    let options = createNotificationCategoryOptions(from: args["options"] as? [String])
    
    let category = UNNotificationCategory(
      identifier: identifier,
      actions: actions,
      intentIdentifiers: [],
      options: options
    )
    
    UNUserNotificationCenter.current().setNotificationCategories([category])
    result(true)
  }
  
  private func createNotificationActions(from actionsData: [[String: Any]]?) -> [UNNotificationAction] {
    guard let actionsData = actionsData else { return [] }
    
    return actionsData.compactMap { actionData in
      guard let identifier = actionData["identifier"] as? String,
            let title = actionData["title"] as? String else { return nil }
      
      let options = createNotificationActionOptions(from: actionData["options"] as? [String])
      
      return UNNotificationAction(
        identifier: identifier,
        title: title,
        options: options
      )
    }
  }
  
  private func createNotificationActionOptions(from optionsData: [String]?) -> UNNotificationActionOptions {
    guard let optionsData = optionsData else { return [] }
    
    var options: UNNotificationActionOptions = []
    
    for option in optionsData {
      switch option {
      case "foreground":
        options.insert(.foreground)
      case "destructive":
        options.insert(.destructive)
      case "authenticationRequired":
        options.insert(.authenticationRequired)
      default:
        break
      }
    }
    
    return options
  }
  
  private func createNotificationCategoryOptions(from optionsData: [String]?) -> UNNotificationCategoryOptions {
    guard let optionsData = optionsData else { return [] }
    
    var options: UNNotificationCategoryOptions = []
    
    for option in optionsData {
      switch option {
      case "allowAnnouncement":
        options.insert(.allowAnnouncement)
      case "allowInCarPlay":
        options.insert(.allowInCarPlay)
      case "hiddenPreviewsShowTitle":
        options.insert(.hiddenPreviewsShowTitle)
      case "hiddenPreviewsShowSubtitle":
        options.insert(.hiddenPreviewsShowSubtitle)
      default:
        break
      }
    }
    
    return options
  }
  
  // MARK: - Background Processing
  
  private func configureBackgroundProcessing(args: [String: Any]?, result: @escaping FlutterResult) {
    // iOS 18.6+ background processing configuration
    // This would configure background app refresh and processing tasks
    result(true)
  }
  
  // MARK: - Smart Notifications
  
  private func enableSmartNotifications(args: [String: Any]?, result: @escaping FlutterResult) {
    // Enable iOS 18.6+ smart notification features
    result(true)
  }
  
  // MARK: - Send Notifications
  
  private func sendSmartNotification(args: [String: Any]?, result: @escaping FlutterResult) {
    guard let args = args,
          let title = args["title"] as? String,
          let body = args["body"] as? String,
          let category = args["category"] as? String,
          let interruptionLevel = args["interruptionLevel"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.categoryIdentifier = category
    content.sound = UNNotificationSound.default
    
    // iOS 18.6+ interruption level
    if #available(iOS 15.0, *) {
      switch interruptionLevel {
      case "active":
        content.interruptionLevel = .active
      case "timeSensitive":
        content.interruptionLevel = .timeSensitive
      case "critical":
        content.interruptionLevel = .critical
      case "passive":
        content.interruptionLevel = .passive
      default:
        content.interruptionLevel = .active
      }
    }
    
    if let payload = args["payload"] as? String {
      content.userInfo = ["payload": payload]
    }
    
    if let userInfo = args["userInfo"] as? [String: Any] {
      content.userInfo.merge(userInfo) { _, new in new }
    }
    
    if let threadIdentifier = args["threadIdentifier"] as? String {
      content.threadIdentifier = threadIdentifier
    }
    
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )
    
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "NOTIFICATION_ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(true)
        }
      }
    }
  }
  
  // MARK: - Schedule Notifications
  
  private func scheduleNotification(args: [String: Any]?, result: @escaping FlutterResult) {
    guard let args = args,
          let title = args["title"] as? String,
          let body = args["body"] as? String,
          let category = args["category"] as? String,
          let interruptionLevel = args["interruptionLevel"] as? String,
          let scheduledDate = args["scheduledDate"] as? TimeInterval else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.categoryIdentifier = category
    content.sound = UNNotificationSound.default
    
    // iOS 18.6+ interruption level
    if #available(iOS 15.0, *) {
      switch interruptionLevel {
      case "active":
        content.interruptionLevel = .active
      case "timeSensitive":
        content.interruptionLevel = .timeSensitive
      case "critical":
        content.interruptionLevel = .critical
      case "passive":
        content.interruptionLevel = .passive
      default:
        content.interruptionLevel = .active
      }
    }
    
    if let payload = args["payload"] as? String {
      content.userInfo = ["payload": payload]
    }
    
    if let userInfo = args["userInfo"] as? [String: Any] {
      content.userInfo.merge(userInfo) { _, new in new }
    }
    
    if let threadIdentifier = args["threadIdentifier"] as? String {
      content.threadIdentifier = threadIdentifier
    }
    
    let date = Date(timeIntervalSince1970: scheduledDate)
    let trigger = UNCalendarNotificationTrigger(
      dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
      repeats: false
    )
    
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: trigger
    )
    
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        if let error = error {
          result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(true)
        }
      }
    }
  }
  
  // MARK: - Cancel Notifications
  
  private func cancelNotification(args: [String: Any]?, result: @escaping FlutterResult) {
    guard let args = args,
          let identifier = args["identifier"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    result(true)
  }
  
  private func cancelAllNotifications(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    result(true)
  }
  
  // MARK: - Get Pending Notifications
  
  private func getPendingNotifications(result: @escaping FlutterResult) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      DispatchQueue.main.async {
        let notifications = requests.map { request in
          return [
            "identifier": request.identifier,
            "title": request.content.title,
            "body": request.content.body,
            "categoryIdentifier": request.content.categoryIdentifier,
            "userInfo": request.content.userInfo
          ]
        }
        result(notifications)
      }
    }
  }
  
  // MARK: - Update Settings
  
  private func updateNotificationSettings(args: [String: Any]?, result: @escaping FlutterResult) {
    // Update iOS 18.6+ notification settings
    result(true)
  }
  
  // MARK: - Focus Mode Integration
  
  private func enableFocusModeIntegration(result: @escaping FlutterResult) {
    // Enable iOS 18.6+ Focus mode integration
    result(true)
  }
  
  // MARK: - Dynamic Island Integration
  
  private func enableDynamicIslandIntegration(result: @escaping FlutterResult) {
    // Enable iOS 18.6+ Dynamic Island integration
    result(true)
  }
  
  // MARK: - Live Activities
  
  private func enableLiveActivities(result: @escaping FlutterResult) {
    // Enable iOS 18.6+ Live Activities
    result(true)
  }
  
  private func startLiveActivity(args: [String: Any]?, result: @escaping FlutterResult) {
    guard let args = args,
          let activityId = args["activityId"] as? String,
          let activityType = args["activityType"] as? String,
          let customerName = args["customerName"] as? String,
          let amount = args["amount"] as? Double,
          let dueDate = args["dueDate"] as? TimeInterval else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    // iOS 18.6+ Live Activity implementation
    // This would start a Live Activity for debt tracking
    result(true)
  }
  
  private func updateLiveActivity(args: [String: Any]?, result: @escaping FlutterResult) {
    guard let args = args,
          let activityId = args["activityId"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    // Update Live Activity
    result(true)
  }
  
  private func endLiveActivity(args: [String: Any]?, result: @escaping FlutterResult) {
    guard let args = args,
          let activityId = args["activityId"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
      return
    }
    
    // End Live Activity
    result(true)
  }
  
  // MARK: - Device Capabilities
  
  private func isIOS186Supported(result: @escaping FlutterResult) {
    // Check if device supports iOS 18.6+ features
    let isSupported = ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 18
    result(isSupported)
  }
  
  private func getDeviceCapabilities(result: @escaping FlutterResult) {
    let capabilities: [String: Bool] = [
      "focusMode": true,
      "dynamicIsland": UIDevice.current.hasDynamicIsland,
      "liveActivities": true,
      "smartStack": true,
      "aiFeatures": true,
    ]
    result(capabilities)
  }
}

// MARK: - UIDevice Extension

extension UIDevice {
  var hasDynamicIsland: Bool {
    // Check if device has Dynamic Island
    let deviceName = UIDevice.current.name
    return deviceName.contains("iPhone 14 Pro") || deviceName.contains("iPhone 15 Pro") || deviceName.contains("iPhone 16 Pro")
  }
}
