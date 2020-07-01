// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Cocoa

extension Notification.Name {
    static let refreshDeviceListInfos = Notification.Name("refreshDeviceListInfos")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        window = NSApplication.shared.windows.first

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func refreshDeviceListInfos(_ sender: AnyObject) {
        debugPrint("REFRESH!!!")
        NotificationCenter.default.post(Notification(name: .refreshDeviceListInfos))
    }
}
