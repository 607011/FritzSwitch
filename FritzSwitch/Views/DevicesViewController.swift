// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Cocoa
import Foundation
import SwiftyXMLParser

class DevicesViewController: NSViewController {
    @IBOutlet weak var switchCollectionView: NSCollectionView!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var statusLabel: NSTextField!

    private let euroPerKWh: Double = 0.29
    private let refreshInterval: TimeInterval = 30.0
    private var sid: String? {
        didSet {
            UserDefaults.standard.set(sid, forKey: Key.sid.rawValue)
            hideSpinner()
        }
    }
    private var sidIssued: Date = Date.distantPast {
        didSet {
            UserDefaults.standard.set(dateFormatter.string(from: sidIssued), forKey: Key.sidIssued.rawValue)
        }
    }
    private var hostname: String?
    private var username: String?
    private var password: String?
    private var timer: Timer?
    private var switches: [Switch] = [] {
        didSet {
            switchCollectionView.reloadData()
            hideSpinner()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        hideSpinner()
        timer = Timer.scheduledTimer(timeInterval: refreshInterval,
                                     target: self,
                                     selector: #selector(refresh),
                                     userInfo: nil,
                                     repeats: true)
        timer?.fire()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh),
                                               name: .refreshDeviceListInfos,
                                               object: nil)
        statusLabel.stringValue = ""
    }

    override func viewWillDisappear() {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self, name: .refreshDeviceListInfos, object: nil)
    }

    fileprivate func showSpinner() {
        spinner.isHidden = false
        spinner.startAnimation(self)
        statusLabel.stringValue = ""
    }

    fileprivate func hideSpinner() {
        spinner.isHidden = true
        spinner.stopAnimation(self)
    }

    @objc
    fileprivate func refresh() {
        sid = UserDefaults.standard.string(forKey: Key.sid.rawValue)
        sidIssued = dateFormatter.date(
            from: UserDefaults.standard.string(forKey: Key.sidIssued.rawValue) ?? "") ?? Date.distantPast
        hostname = UserDefaults.standard.string(forKey: Key.fritzboxHostname.rawValue) ?? Constant.noSID
        username = UserDefaults.standard.string(forKey: Key.fritzboxUsername.rawValue)
        password = UserDefaults.standard.string(forKey: Key.fritzboxPassword.rawValue)
        loadDeviceListInfos()
    }

    @objc
    fileprivate func switchClicked(_ sender: NSButton) {
        if let hostname = hostname,
            let sid = sid,
            let ain = switches[sender.tag].identifier {
            showSpinner()
            DispatchQueue.main.async {
                toggleSwitch(
                    hostname: hostname,
                    ain: ain,
                    sid: sid,
                    onSuccess: { (isOn, ain) in
                        if let idx = self.switches.firstIndex(where: { $0.identifier == ain }),
                            idx < self.switches.count {
                            self.switches[idx].isOn = isOn
                            self.switchCollectionView.reloadData()
                            self.hideSpinner()
                        }
                }, onFailure: { (error, ain) in
                    self.hideSpinner()
                    self.statusLabel.stringValue = "ERROR: \(error.localizedDescription) (ain=\(ain))"
                })
            }
        }
    }

    fileprivate func deviceListLoaded(xml: XML.Accessor) {
        var foundSwitches: [Switch] = []
        for device in xml.devicelist.device {
            let sw = Switch() //  // swiftlint:disable:this identifier_name
            sw.functions = Int(device.attributes["functionbitmask"] ?? "") ?? 0
            sw.productname = device.attributes["productname"]
            sw.manufacturer = device.attributes["manufacturer"]
            sw.fwversion = device.attributes["fwversion"]
            sw.identifier = device.attributes["identifier"]
            sw.name = device["name"].text
            if FunctionBit.temperatureSensor.contained(in: sw.functions) {
                if let celsius = Double(device["temperature"]["celsius"].text ?? "") {
                    sw.celsius = 0.1 * celsius
                }
            }
            if FunctionBit.powermeter.contained(in: sw.functions) {
                if let power = Double(device["powermeter"]["power"].text ?? "") {
                    sw.power = 1e-3 * power
                }
                if let energy = Double(device["powermeter"]["energy"].text ?? "") {
                    sw.energy = 1e-3 * energy
                }
                if let voltage = Double(device["powermeter"]["voltage"].text ?? "") {
                    sw.voltage = 1e-3 * voltage
                }
            }
            if FunctionBit.outletSwitch.contained(in: sw.functions) {
                sw.isOn = Int(device["switch"]["state"].text ?? "") == 1
                foundSwitches.append(sw)
            }
        }
        self.switches = foundSwitches.sorted(by: { $0.name ?? "" < $1.name ?? "" })
    }

    func refreshSID() {
        DispatchQueue.main.async {
            guard let hostname = self.hostname else { return }
            guard let password = self.password else { return }
            getSID(
                hostname: hostname,
                username: self.username,
                password: password,
                onSuccess: { newSID in
                    self.sid = newSID
                    self.sidIssued = Date()
                    self.loadDeviceListInfos()
            }, onFailure: { error in
                self.statusLabel.stringValue = "ERROR checking credentials: \(error.localizedDescription)"
                self.sid = nil
                self.sidIssued = Date.distantPast
            })
        }
    }

    func loadDeviceListInfos() {
        guard let hostname = hostname else { return }
        guard let sid = sid else { return }
        //        NSLog("DevicesViewController.loadDeviceListInfos() now = \(Date()), " +
        //            "sidIssued = \(sidIssued), dt = \(Date().timeIntervalSince(sidIssued))")
        if Date().timeIntervalSince(sidIssued) < Constant.maxSIDAge {
            showSpinner()
            DispatchQueue.main.async {
                getDeviceListInfos(
                    from: hostname,
                    sid: sid,
                    onSuccess: self.deviceListLoaded,
                    onFailure: { error in
                        self.hideSpinner()
                        switch error {
                        case .emptyResponse:
                            self.statusLabel.stringValue = "Empty response from Fritzbox, trying to fetch a new SID …"
                            self.showSpinner()
                            self.refreshSID()
                        default:
                            self.statusLabel.stringValue = "ERROR fetching device list infos: " +
                                error.localizedDescription
                        }
                })
            }
        } else {
            showSpinner()
            refreshSID()
        }
    }
}

extension DevicesViewController: NSCollectionViewDataSource, NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return switches.count
    }

    func collectionView(_ collectionView: NSCollectionView,
                        itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if let item = collectionView.makeItem(
            withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SwitchCollectionViewItem"),
            for: indexPath) as? SwitchCollectionViewItem {
            let sw = switches[indexPath.item] // swiftlint:disable:this identifier_name
            item.deviceNameLabel.stringValue = sw.name ?? NSLocalizedString("<unknown>", comment: "unknown")
            item.deviceStateButton.state = sw.isOn ? .on : .off
            item.deviceStateButton.target = self
            item.deviceStateButton.action = #selector(switchClicked)
            item.deviceStateButton.tag = indexPath.item
            item.deviceStateButton.image?.isTemplate = true
            item.deviceStateButton.bezelStyle = .inline
            item.deviceStateButton.isBordered = false
            item.deviceStateButton.contentTintColor = sw.isOn
                ? NSColor(named: "PowerOn")
                : NSColor(named: "PowerOff")
            if let manufacturer = sw.manufacturer,
                let productname = sw.productname {
                item.productNameLabel.stringValue = "\(manufacturer) \(productname)"
            } else {
                item.productNameLabel.stringValue = ""
            }
            if let celsius = sw.celsius {
                item.temperatureLabel.stringValue = String(format: "%.1f °C", celsius)
            } else {
                item.temperatureLabel.stringValue = ""
            }
            var powermeterData: [String] = []
            if let energy = sw.energy {
                powermeterData.append(String(format: "%.1f kWh (%.2f €)", energy, energy * euroPerKWh))
            }
            if let power = sw.power {
                powermeterData.append(String(format: "%.1f W", power))
            }
            if let voltage = sw.voltage {
                powermeterData.append(String(format: "%.1f V", voltage))
            }
            item.energyLabel.stringValue = powermeterData.isEmpty
                ? ""
                : powermeterData.joined(separator: " / ")
            return item
        }
        return SwitchCollectionViewItem()
    }
}
