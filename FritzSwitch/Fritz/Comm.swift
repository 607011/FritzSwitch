// Copyright © 2020 Oliver Lau <oliver@ersatzworld.net>

import Foundation
import SwiftyXMLParser

enum FritzError: Error {
    case unknownError
    case emptyResponse
    case invalidURL
    case challengeMissing
    case challengeResponseEncodingFailed
    case readFromURLFailed
    case invalidSIDReceived
    case invalidXML(errorDescription: String?)

    var localizedDescription: String {
        switch self {
        case .unknownError: return "Unknown"
        case .emptyResponse: return "Empty response"
        case .invalidURL: return "Invalid URL"
        case .challengeMissing: return "No challenge received"
        case .challengeResponseEncodingFailed: return "Encoding of challenge+password failed"
        case .readFromURLFailed: return "Cannot read from URL"
        case .invalidSIDReceived: return "Invalid SID received"
        case .invalidXML: return "Invalid XML received"
        }
    }
}

public func makeFritzboxResponse(to challenge: String, authenticatedBy password: String) -> String? {
    guard let utf16le = "\(challenge)-\(password)".data(using: .utf16LittleEndian) else { return nil }
    return MD5(utf16le).map { String(format: "%02hhx", $0) }.joined()
}

func getSID(hostname: String,
            username: String?,
            password: String,
            onSuccess: @escaping((_ sid: String) -> Void),
            onFailure: @escaping((_ error: FritzError) -> Void)) {
    guard let url = URL(string: "http://\(hostname)/login_sid.lua") else {
        onFailure(.invalidURL)
        return
    }
    do {
        let data = try String(contentsOf: url, encoding: .utf8)
        if data.isEmpty {
            onFailure(.emptyResponse)
            return
        }
        let xml = try XML.parse(data)
        guard let challenge = xml.SessionInfo.Challenge.text else {
            onFailure(.challengeMissing)
            return
        }
        guard let response = makeFritzboxResponse(to: challenge, authenticatedBy: password) else {
            onFailure(.challengeResponseEncodingFailed)
            return
        }
        guard let url = URL(string: "http://\(hostname)/login_sid.lua" +
            "?username=\(username ?? "")&response=\(challenge)-\(response)") else {
                onFailure(.invalidURL)
            return
        }
        let data2 = try String(contentsOf: url)
        if data.isEmpty {
            onFailure(.emptyResponse)
            return
        }
        let xml2 = try XML.parse(data2)
        if let sid = xml2.SessionInfo.SID.text {
            onSuccess(sid)
            return
        }
    } catch XMLError.failToEncodeString {
        onFailure(.invalidXML(errorDescription: nil))
        return
    } catch XMLError.interruptedParseError {
        onFailure(.invalidXML(errorDescription: nil))
        return
    } catch XMLError.accessError(let description) {
        onFailure(.invalidXML(errorDescription: description))
        return
    } catch {
        onFailure(.invalidXML(errorDescription: nil))
        return
    }
    onFailure(.unknownError)
}

func send(command switchCmd: String,
          to hostname: String,
          sid: String?,
          ain: String?,
          onSuccess: ((_ data: String) -> Void)? = nil,
          onFailure: ((_ error: FritzError) -> Void)? = nil) {
    var urlString = "http://\(hostname)/webservices/homeautoswitch.lua?switchcmd=\(switchCmd)"
    if let sid = sid {
        urlString += "&sid=\(sid)"
    }
    if let ain = ain {
        urlString += "&ain=\(ain.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
    }
    NSLog("GET %@", urlString)
    guard let url = URL(string: urlString) else {
        onFailure?(.invalidURL)
        return
    }
    do {
        let data = try String(contentsOf: url, encoding: .utf8)
        if data.isEmpty {
            onFailure?(.emptyResponse)
            return
        }
        NSLog("Received: %@", data)
        onSuccess?(data)
    } catch {
        onFailure?(.readFromURLFailed)
    }
}

func getDeviceListInfos(from hostname: String,
                        sid: String,
                        onSuccess: ((_ xml: XML.Accessor) -> Void)? = nil,
                        onFailure: ((_ error: FritzError) -> Void)? = nil) {
    send(command: "getdevicelistinfos", to: hostname,
        sid: sid, ain: nil,
        onSuccess: { data in
            do {
                let xml = try XML.parse(data)
                onSuccess?(xml)
            } catch {
                onFailure?(.invalidXML(errorDescription: "Received: \(data)"))
            }
    },
        onFailure: onFailure)
}

func toggleSwitch(hostname: String, ain: String, sid: String,
                  onSuccess: ((_ isOn: Bool, _ ain: String) -> Void)? = nil,
                  onFailure: ((_ error: FritzError, _ ain: String) -> Void)? = nil) {
    send(command: "setswitchtoggle", to: hostname,
        sid: sid,
        ain: ain,
        onSuccess: { data in
            let response = data.trimmingCharacters(in: .whitespacesAndNewlines)
            onSuccess?(Int(response) == 1, ain) },
        onFailure: { error in onFailure?(error, ain)}
    )
}
