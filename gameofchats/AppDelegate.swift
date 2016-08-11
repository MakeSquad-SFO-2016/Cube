
import UIKit
import Firebase
import FirebaseMessaging
import FirebaseAuth



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
      
      let settings: UIUserNotificationSettings =
         UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
      application.registerUserNotificationSettings(settings)
      application.registerForRemoteNotifications()
      FIRApp.configure()
      
      window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.makeKeyAndVisible()
        
        window?.rootViewController = UINavigationController(rootViewController: MessagesController())
        
        return true
    }
   func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
      if notificationSettings.types != .None {
         application.registerForRemoteNotifications()
      }
   }
   
   func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
      let tokenChars = UnsafePointer<CChar>(deviceToken.bytes)
      var tokenString = ""
      
      for i in 0..<deviceToken.length {
         tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
      }
      
      //Tricky line
      FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.Unknown)
      print("Device Token:", tokenString)
   }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
   func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject],
                    fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification
      
      // Print message ID.
      print("Message ID: \(userInfo["gcm.message_id"]!)")
      
      // Print full message.
      print("%@", userInfo)
   }
   
   
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
//   func push(application: UIApplication, didReceiveRemoteNotification Message: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
//      // Let FCM know about the message for analytics etc.
//      FIRMessaging.messaging().appDidReceiveMessage(Message)
//      // handle your message
//   }

  
   


}

