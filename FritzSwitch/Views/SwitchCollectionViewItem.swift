// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Cocoa

class SwitchCollectionViewItem: NSCollectionViewItem {
    @IBOutlet weak var deviceNameLabel: NSTextField!
    @IBOutlet weak var deviceStateButton: NSButton!
    @IBOutlet weak var productNameLabel: NSTextField!
    @IBOutlet weak var energyLabel: NSTextField!
    @IBOutlet weak var temperatureLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
