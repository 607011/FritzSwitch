// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Cocoa
import Foundation
import SwiftyXMLParser

class DevicesViewController: NSViewController {
    @IBOutlet weak var switchCollectionView: NSCollectionView!

    private let euroPerKWh: Double = 0.29
    private let refreshInterval: TimeInterval = 30.0
    private var sid: String?
    private var sidIssued: Date?
    private var hostname: String?
    private var timer: Timer?
    private var switches: [Switch] = [] {
        didSet {
            switchCollectionView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        view.wantsLayer = true
        view.layer?.backgroundColor = CGColor.black
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        timer = Timer.scheduledTimer(timeInterval: refreshInterval, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        timer?.fire()
    }

    override func viewWillDisappear() {
        timer?.invalidate()
    }

    fileprivate func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 330.0, height: 120.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        flowLayout.minimumInteritemSpacing = 10.0
        flowLayout.minimumLineSpacing = 10.0
        switchCollectionView.collectionViewLayout = flowLayout
        switchCollectionView.layer?.backgroundColor = CGColor.clear
    }

    @objc
    fileprivate func refresh() {
        sid = UserDefaults.standard.string(forKey: Key.sid.rawValue)
        sidIssued = dateFormatter.date(from: UserDefaults.standard.string(forKey: Key.sidIssued.rawValue) ?? "") ?? Date.distantPast
        hostname = UserDefaults.standard.string(forKey: Key.fritzboxHostname.rawValue) ?? NoSID
        loadDeviceListInfos()
    }

    @objc
    fileprivate func switchClicked(_ sender: NSButton) {
        if let hostname = hostname,
            let sid = sid,
            let ain = switches[sender.tag].identifier {
            DispatchQueue.main.async {
                toggleSwitch(
                    hostname: hostname,
                    ain: ain,
                    sid: sid,
                    onSuccess: { (isOn, ain) in
                        if let idx = self.switches.firstIndex(where: { $0.identifier == ain }), idx < self.switches.count {
                            self.switches[idx].isOn = isOn
                            self.switchCollectionView.reloadData()
                        }
                },
                    onFailure: { (error, ain) in debugPrint(error, ain) })
            }
        }
    }

    fileprivate func loadDeviceListInfos() {
        guard let hostname = hostname else { return }
        guard let sid = sid else { return }
        getDeviceListInfos(
            hostname: hostname,
            sid: sid,
            onSuccess: { xml in
                var foundSwitches: [Switch] = []
                for device in xml.devicelist.device {
                    let sw = Switch()
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
                self.switches = foundSwitches
        },
            onFailure: { error in
                NSLog("ERROR: %@", error)
        })
    }
}

extension DevicesViewController: NSCollectionViewDataSource, NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return switches.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SwitchCollectionViewItem"), for: indexPath) as? SwitchCollectionViewItem {
            let sw = switches[indexPath.item]
            item.deviceNameLabel.stringValue = sw.name ?? NSLocalizedString("<unknown>", comment: "unknown")
            item.deviceStateButton.state = sw.isOn ? .on : .off
            item.deviceStateButton.target = self
            item.deviceStateButton.action = #selector(switchClicked)
            item.deviceStateButton.tag = indexPath.item
            item.deviceStateButton.image?.isTemplate = true
            item.deviceStateButton.bezelStyle = .inline
            item.deviceStateButton.isBordered = false
            item.deviceStateButton.contentTintColor = sw.isOn ? NSColor(named: "PowerOn") : NSColor(named: "PowerOff")
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
