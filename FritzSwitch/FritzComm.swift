// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Foundation
import SwiftyXMLParser

func checkCredentials(hostname: String, username: String, password: String, onSuccess: @escaping((_ sid: String) -> ()), onFailure: @escaping((_ error: String) -> ())) {
    guard let url = URL(string: "http://\(hostname)/login_sid.lua") else {
        onFailure("Illegal URL")
        return
    }
    NSLog("URL = \(url)")
    do {
        let data = try String(contentsOf: url, encoding: .utf8)
        let xml = try XML.parse(data)
        guard let challenge = xml.SessionInfo.Challenge.text else {
            onFailure("Host hasn't sent a challenge")
            return
        }
        NSLog("Challenge = \(challenge)")
        guard let response = makeFritzboxResponse(to: challenge, authenticatedBy: password) else {
            onFailure("Cannot encode challenge+password")
            return
        }
        guard let url = URL(string: "http://\(hostname)/login_sid.lua?username=\(username)&response=\(challenge)-\(response)") else {
            onFailure("Illegal URL")
            return
        }
        let data2 = try String(contentsOf: url)
        let xml2 = try! XML.parse(data2)
        if let sid = xml2.SessionInfo.SID.text {
            onSuccess(sid)
            return
        }
    } catch {
        onFailure("Cannot read from URL '\(url)' or invalid XML response")
        return
    }
    onFailure("Invalid SID received")
}

func sendCommand(hostname: String, switchCmd: String, sid: String?, ain: String?, onSuccess: @escaping((_ data: String) -> ()), onFailure: @escaping((_ error: String) -> ())) {
    var urlString = "http://\(hostname)/webservices/homeautoswitch.lua?switchcmd=\(switchCmd)"
    if let sid = sid {
        urlString += "&sid=\(sid)"
    }
    if let ain = ain {
        urlString += "&ain=\(ain)"
    }
    guard let url = URL(string: urlString) else {
        onFailure("Illegal URL")
        return
    }
    do {
        let data = try String(contentsOf: url, encoding: .utf8)
        NSLog(data)
        onSuccess(data)
    } catch {
        onFailure("Cannot read from URL '\(url)'")
    }
}

func getDeviceListInfos(hostname: String, sid: String, onSuccess: @escaping((_ xml: XML.Accessor) -> ()), onFailure: @escaping((_ error: String) -> ())) {
    sendCommand(
        hostname: hostname,
        switchCmd: "getdevicelistinfos",
        sid: sid,
        ain: nil,
        onSuccess: { data in
            do {
                let xml = try XML.parse(data)
                onSuccess(xml)
            } catch {
                onFailure("Invalid XML: \(data)")
            }
    },
        onFailure: onFailure)
}
