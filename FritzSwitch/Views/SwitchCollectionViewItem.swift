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
//        self.view.layer?.backgroundColor = CGColor(red: 0.2, green: 0.6, blue: 0.8, alpha: 1.0)
    }
    
}
