// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Cocoa

class MainViewController: NSViewController {
    @IBOutlet weak var loginViewContainer: NSView!
    @IBOutlet weak var mainViewContainer: NSView!

    private var fritzboxHostname: String?
    private var fritzboxUsername: String?
    private var fritzboxPassword: String?
    private var sid: String?
    private var sidIssued: Date = Date.distantPast

    override func viewDidLoad() {
        super.viewDidLoad()
        fritzboxHostname = UserDefaults.standard.string(forKey: Key.fritzboxHostname.rawValue)
        fritzboxUsername = UserDefaults.standard.string(forKey: Key.fritzboxUsername.rawValue)
        fritzboxPassword = UserDefaults.standard.string(forKey: Key.fritzboxPassword.rawValue)
        sid = UserDefaults.standard.string(forKey: Key.sid.rawValue)
        sidIssued = dateFormatter.date(
            from: UserDefaults.standard.string(forKey: Key.sidIssued.rawValue) ?? "") ?? Date.distantPast
        NSLog("host = \(fritzboxHostname ?? ""), user = \(fritzboxUsername ?? ""), pass = \(fritzboxPassword ?? ""), sid = \(sid ?? ""), sidIssued = \(String(describing: sidIssued))") // swiftlint:disable:this line_length
        UserDefaults.standard.addObserver(self, forKeyPath: Key.sid.rawValue, options: .new, context: nil)
    }

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: Key.sid.rawValue, context: nil)
    }

    fileprivate func showLogin() {
        loginViewContainer.isHidden = false
        mainViewContainer.isHidden = true
    }

    fileprivate func showMain() {
        loginViewContainer.isHidden = true
        mainViewContainer.isHidden = false
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        print(Date().timeIntervalSince(sidIssued))
        if Date().timeIntervalSince(sidIssued) > Constant.maxSIDAge {
            showLogin()
        } else {
            showMain()
        }
    }

    override func observeValue(forKeyPath keyPath: String?,  // swiftlint:disable:this block_based_kvo
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        NSLog("Key '\(String(describing: keyPath))' changed.")
        if keyPath == Key.sid.rawValue {
            sid = change?[.newKey] as? String
            if sid != nil && sid != Constant.noSID {
                showMain()
            }
        }
    }
}
