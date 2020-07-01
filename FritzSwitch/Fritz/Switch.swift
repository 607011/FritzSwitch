// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Foundation

struct FunctionBit: OptionSet {
    let rawValue: Int
    static let hanFunDevice = FunctionBit(rawValue: 1 << 0)
    static let lightLamp = FunctionBit(rawValue: 1 << 2)
    static let alarmSensor = FunctionBit(rawValue: 1 << 4)
    static let avmButton = FunctionBit(rawValue: 1 << 5)
    static let thermostate = FunctionBit(rawValue: 1 << 6)
    static let powermeter = FunctionBit(rawValue: 1 << 7)
    static let temperatureSensor = FunctionBit(rawValue: 1 << 8)
    static let outletSwitch = FunctionBit(rawValue: 1 << 9)
    static let avmDectRepeater = FunctionBit(rawValue: 1 << 10)
    static let microphone = FunctionBit(rawValue: 1 << 11)
    static let hanFunUnit = FunctionBit(rawValue: 1 << 13)
    static let switchableActor = FunctionBit(rawValue: 1 << 15)
    static let dimmableDevice = FunctionBit(rawValue: 1 << 16)
    static let colorAdjustableLamp = FunctionBit(rawValue: 1 << 17)
    func contained(in value: Int) -> Bool {
        return value & rawValue == rawValue
    }
}

class Switch {
    enum Mode: String {
        case auto
        case manuell // yes, indeed, not "manual" ;-)
    }

    var name: String?
    var functions: Int = 0x0
    var identifier: String?
    var lock: String?
    var deviceLock: String?
    var isOn: Bool = false
    var celsius: Double?
    var power: Double?
    var energy: Double?
    var voltage: Double?
    var present: String?
    var mode: Mode?
    var manufacturer: String?
    var productname: String?
    var fwversion: String?
}

extension Switch: CustomDebugStringConvertible {
    var debugDescription: String {
        return "\(String(describing: name)) \(String(describing: identifier)) \(String(describing: manufacturer)) \(String(describing: productname)) isOn=\(isOn)" // swiftlint:disable:this line_length
    }
}
