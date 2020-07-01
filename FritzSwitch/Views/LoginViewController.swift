// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import CoreFoundation
import AppKit

class LoginViewController: NSViewController {
    @IBOutlet weak var fritzboxHostnameTextField: NSTextField!
    @IBOutlet weak var fritzboxUsernameTextField: NSTextField!
    @IBOutlet weak var fritzboxPasswordTextField: NSSecureTextField!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var loginButton: NSButton!
    @IBOutlet weak var statusLabel: NSTextField!

    private var sid: String? {
        didSet {
            UserDefaults.standard.set(sid, forKey: Key.sid.rawValue)
        }
    }
    private var sidIssued: Date? {
        didSet {
            UserDefaults.standard.set(dateFormatter.string(from: sidIssued ?? Date.distantPast),
                                      forKey: Key.sidIssued.rawValue)
        }
    }

    fileprivate func enableUI() {
        loginButton.isEnabled = true
        fritzboxHostnameTextField.isEnabled = true
        fritzboxUsernameTextField.isEnabled = true
        fritzboxPasswordTextField.isEnabled = true
        spinner.stopAnimation(self)
        spinner.isHidden = true
    }

    fileprivate func disableUI() {
        loginButton.isEnabled = false
        fritzboxHostnameTextField.isEnabled = false
        fritzboxUsernameTextField.isEnabled = false
        fritzboxPasswordTextField.isEnabled = false
        spinner.startAnimation(self)
        spinner.isHidden = false
    }

    @IBAction func loginButtonPressed(_ sender: Any) {
        let hostname = fritzboxHostnameTextField.stringValue
        let username = fritzboxUsernameTextField.stringValue
        let password = fritzboxPasswordTextField.stringValue
        disableUI()
        DispatchQueue.main.async {
            getSID(
                hostname: hostname,
                username: username,
                password: password,
                onSuccess: { newSID in
                    self.enableUI()
                    self.sid = newSID
                    self.sidIssued = Date()
                    self.statusLabel.textColor = .labelColor
                    self.statusLabel.stringValue = newSID
            },
                onFailure: { error in
                    self.enableUI()
                    self.statusLabel.textColor = .systemRed
                    self.statusLabel.stringValue = error.localizedDescription
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefaults.standard.object(forKey: Key.sid.rawValue) != nil {
            sid = UserDefaults.standard.string(forKey: Key.sid.rawValue) ?? Constant.noSID
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

}
