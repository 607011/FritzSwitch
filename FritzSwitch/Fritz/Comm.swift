// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Foundation
import SwiftyXMLParser

public func makeFritzboxResponse(to challenge: String, authenticatedBy password: String) -> String? {
    guard let utf16le = "\(challenge)-\(password)".data(using: .utf16LittleEndian) else { return nil }
    return MD5(utf16le).map { String(format: "%02hhx", $0) }.joined()
}

func checkCredentials(hostname: String, username: String, password: String, onSuccess: @escaping((_ sid: String) -> ()), onFailure: @escaping((_ error: String) -> ())) {
    guard let url = URL(string: "http://\(hostname)/login_sid.lua") else {
        onFailure("Illegal URL")
        return
    }
    do {
        let data = try String(contentsOf: url, encoding: .utf8)
        let xml = try XML.parse(data)
        guard let challenge = xml.SessionInfo.Challenge.text else {
            onFailure("Host hasn't sent a challenge")
            return
        }
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
    } catch XMLError.failToEncodeString {
        onFailure("Invalid XML response: failed to encode strin")
        return
    } catch XMLError.interruptedParseError(let error) {
        onFailure("Invalid XML response: \(error)")
        return
    } catch XMLError.accessError(let description){
        onFailure("Invalid XML response: \(description)")
        return
    } catch {
        onFailure("Cannot read from URL '\(url)'")
        return
    }
    onFailure("Invalid SID received")
}

func send(command switchCmd: String,
          to hostname: String,
          sid: String?,
          ain: String?,
          onSuccess: ((_ data: String) -> Void)? = nil,
          onFailure: ((_ error: String) -> Void)? = nil) {
    var urlString = "http://\(hostname)/webservices/homeautoswitch.lua?switchcmd=\(switchCmd)"
    if let sid = sid {
        urlString += "&sid=\(sid)"
    }
    if let ain = ain {
        urlString += "&ain=\(ain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
    }
    NSLog("GET %@", urlString)
    guard let url = URL(string: urlString) else {
        onFailure?("Illegal URL")
        return
    }
    do {
        let data = try String(contentsOf: url, encoding: .utf8)
        NSLog("Received: %@", data)
        onSuccess?(data)
    } catch {
        onFailure?("Cannot read from URL '\(url)'")
    }
}

func getDeviceListInfos(hostname: String, sid: String,
                        onSuccess: ((_ xml: XML.Accessor) -> Void)? = nil,
                        onFailure: ((_ error: String) -> Void)? = nil) {
    send(command: "getdevicelistinfos", to: hostname,
        sid: sid, ain: nil,
        onSuccess: { data in
            do {
                let xml = try XML.parse(data)
                onSuccess?(xml)
            } catch {
                onFailure?("Invalid XML: \(data)")
            }
    },
        onFailure: onFailure)
}

func toggleSwitch(hostname: String, ain: String, sid: String,
                  onSuccess: ((_ isOn: Bool, _ ain: String) -> Void)? = nil,
                  onFailure: ((_ error: String, _ ain: String) -> Void)? = nil) {
    send(command: "setswitchtoggle", to: hostname,
        sid: sid,
        ain: ain,
        onSuccess: { data in
            let response = data.trimmingCharacters(in: .whitespacesAndNewlines)
            onSuccess?(Int(response) == 1, ain) },
        onFailure: { error in onFailure?(error, ain)}
    )
}
