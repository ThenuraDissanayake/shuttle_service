import Flutter
import UIKit
import FirebaseCore
import GoogleMaps
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)
        GMSServices.provideAPIKey("AIzaSyDWNJpIdz6mVsChzNOG1c_E5x6JOUC1krs")
        
        // Request notification permissions
        UNUserNotificationCenter.current().delegate = self
        
        Messaging.messaging().delegate = self
        
        // Request authorization for notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle device token registration
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
}

// Conform to MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "")")
    }
}