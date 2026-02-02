import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 🔑 PASTE YOUR GOOGLE MAPS API KEY BELOW (replace the placeholder)
    GMSServices.provideAPIKey(AIzaSyCXDutfJxPiziGezC4GXLIsOQKaTWU5Vca)
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}