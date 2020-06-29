// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Cocoa
import Foundation
import SwiftyXMLParser

class Switch {
    var name: String?
    var identifier: String?
    var lock: String?
    var deviceLock: String?
    var isOn: Bool = false
    var celsius: Double?
    var power: Double?
    var energy: Double?
    var voltage: Double?
    var present: String?
    var mode: String?
    var manufacturer: String?
    var productname: String?
    var fwversion: String?
}

extension Switch: CustomDebugStringConvertible {
    var debugDescription: String {
        return "\(String(describing: name)) \(String(describing: identifier)) \(String(describing: manufacturer)) \(String(describing: productname)) isOn=\(isOn)"
    }
}

class DevicesViewController: NSViewController {
    @IBOutlet weak var switchCollectionView: NSCollectionView!

    private var sid: String?
    private var hostname: String?
    private var switches: [Switch] = [] {
        didSet {
            switchCollectionView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        sid = UserDefaults.standard.string(forKey: Key.sid.rawValue)
        hostname = UserDefaults.standard.string(forKey: Key.fritzboxHostname.rawValue) ?? NoSID
        loadDeviceListInfos()
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
                    if device.switch.error == nil {
                        let sw = Switch()
                        sw.name = device["name"].text
                        sw.identifier = device.attributes["identifier"]
                        sw.isOn = Int(device["switch"].state.text ?? "") == 1
                        if let celsius = Double(device["temperature"]["celsius"].text ?? "") {
                            sw.celsius = 0.1 * celsius
                        }
                        if let power = Double(device["powermeter"]["power"].text ?? "") {
                            sw.power = 1e-3 * power
                        }
                        if let energy = Double(device["powermeter"]["energy"].text ?? "") {
                            sw.energy = energy
                        }
                        if let voltage = Double(device["powermeter"]["voltage"].text ?? "") {
                            sw.voltage = 1e-3 * voltage
                        }
                        sw.productname = device.attributes["productname"]
                        sw.manufacturer = device.attributes["manufacturer"]
                        sw.fwversion = device.attributes["fwversion"]
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
            item.deviceNameLabel.stringValue = sw.name ?? ""
            item.deviceStateButton.state = sw.isOn ? .on : .off
            if let manufacturer = sw.manufacturer,
                let productname = sw.productname {
                item.productNameLabel.stringValue = "\(manufacturer) \(productname)"
            }
            if let celsius = sw.celsius {
                item.temperatureLabel.stringValue = "\(celsius.rounded(toPlaces: 1)) °C"
            }
            var powermeterData: [String] = []
            if let energy = sw.energy {
                powermeterData.append("\(energy.rounded(toPlaces: 2)) Wh")
            }
            if let power = sw.power {
                powermeterData.append("\(power.rounded(toPlaces: 2)) W")
            }
            if let voltage = sw.voltage {
                powermeterData.append("\(voltage.rounded(toPlaces: 2)) V")
            }
            item.energyLabel.stringValue = powermeterData.isEmpty
                ? ""
                : powermeterData.joined(separator: " / ")
            return item
        }
        return NSCollectionViewItem()
    }
}

extension DevicesViewController : NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: 320, height: 111)
    }
}
