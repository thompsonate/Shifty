//
//  PublicSuffix.swift
//  PublicSuffix
//
//  Created by Enrico Ghirardi on 28/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation

private let PSL_URL = "https://www.publicsuffix.org/list/public_suffix_list.dat"
private let PSL_RULES_NAME  = "etld"
private let PSL_RULES_FORMAT = "plist"
private let PSL_PLIST_NAME = PSL_RULES_NAME+"."+PSL_RULES_FORMAT
private var LOADED_UPDATED_PSL = false
private var LOADING_UPDATED_PSL = false
private var _ruleTree: [String: Any] = [:]

private class PublicSuffix {
    public static var ownBundle: Bundle {
        get {
            return Bundle(for: PublicSuffix.self)
        }
    }
}

private enum DownloadResult {
    case NetworkError
    case ResponseCodeError
    case ParsingError
    case UnknownError
}

private enum PSLError : Error {
    case AppSupportDir
}

private func directoryExistsAtPath(_ path: String) -> Bool {
    var isDirectory = ObjCBool(true)
    let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
}

private var applicationSupportDirectory: URL? {
    get {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)
        guard let appSupport =  urls.first else { return nil }
        let bundleId = Bundle.main.bundleIdentifier ?? "PSLSwift"
        return appSupport.appendingPathComponent(bundleId)
    }
}

private func buildETLDRuleTree(node: inout [String:Any], domainParts: inout [String]) {
    if domainParts.count == 0 {
        return
    }
    guard var lastDomainPart = domainParts.last else { return }
    domainParts.removeLast()
    
    var notDomain = false
    if lastDomainPart.hasPrefix("!") {
        notDomain = true
        let range = lastDomainPart.index(after: lastDomainPart.startIndex)..<lastDomainPart.endIndex
        lastDomainPart = String(lastDomainPart[range])
    }
    
    if (node[lastDomainPart] == nil) {
        var childNode = [String: Any]()
        if notDomain {
            childNode["!"] = [String: Any]()
        }
        node[lastDomainPart] = childNode
    }
    guard var childNode = node[lastDomainPart] as? [String: Any] else { return }

    if (!notDomain) && (domainParts.count > 0) {
        buildETLDRuleTree(node: &childNode, domainParts: &domainParts)
        node[lastDomainPart] = childNode
    }
}

private func downloadPSL(success: @escaping ([String]) -> Void, failed: @escaping (DownloadResult) -> Void) {
    let session = URLSession.shared
    let task = session.dataTask(with: URL(string: PSL_URL)!) { data, response, err in
        if let error = err {
            NSLog("Network error: \(error)")
            failed(.NetworkError)
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 200:
                if let dataString = String(data: data!, encoding: String.Encoding.utf8) {
                    let tlds = dataString.components(separatedBy: .newlines).map {
                        $0.trimmingCharacters(in: .whitespaces)
                        }.filter {
                            !$0.isEmpty && !$0.hasPrefix("//")
                    }
                    success(tlds)
                } else {
                    failed(.ParsingError)
                }
            default:
                NSLog("Response: %d %@", httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                failed(.ResponseCodeError)
            }
        }
    }
    task.resume()
}

extension URL {
    static public func updatePSL(success: @escaping () -> Void, failed: @escaping () -> Void) {
        LOADED_UPDATED_PSL = false
        LOADING_UPDATED_PSL = true
        downloadPSL(success: { (tlds) in
            var dic = [String: Any]()
            for tld in tlds {
                let encoded_tld = NSString(string: tld)._webkit_encodeHostName() as String
                var ruleComponents = tld.components(separatedBy: ".")
                buildETLDRuleTree(node: &dic, domainParts: &ruleComponents)
                if tld != encoded_tld {
                    var idnaRuleComponents = encoded_tld.components(separatedBy: ".")
                    buildETLDRuleTree(node: &dic, domainParts: &idnaRuleComponents)
                }
            }
            dic["*"] = [String: Any]()
            
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: dic, format: .xml, options: 0)
                guard let etld_path = applicationSupportDirectory else { throw PSLError.AppSupportDir }
                if !directoryExistsAtPath(etld_path.path) {
                    try FileManager.default.createDirectory(at: etld_path,
                                                            withIntermediateDirectories: true)
                }
                try data.write(to: etld_path.appendingPathComponent(PSL_PLIST_NAME), options: .atomic)
                _ruleTree = dic
                LOADING_UPDATED_PSL = false
                LOADED_UPDATED_PSL = true
                success()
            }  catch {
                LOADING_UPDATED_PSL = false
                failed()
            }
        }, failed: { (result) in
            switch result {
            case .NetworkError:
                NSLog("Network error")
            case .ResponseCodeError:
                NSLog("Response code error")
            case .ParsingError:
                NSLog("Parsing error")
            case .UnknownError:
                NSLog("Unknown error")
            }
            LOADING_UPDATED_PSL = false
            failed()
        })
    }
    
    private func loadRuleTree(url: URL) -> [String: Any] {
        do {
            let data = try Data(contentsOf:url)
            return try PropertyListSerialization.propertyList(from: data,
                                                                   options: [],
                                                                   format: nil)
                as! [String:Any]
            
        } catch {
            NSLog("PSL: Couldn't load rule tree")
            return [:]
        }
    }

    private var PSLruleTree: [String: Any] {
        get {
            // check if there's an updated PSL already loaded
            if LOADED_UPDATED_PSL && !_ruleTree.isEmpty{
                return _ruleTree
            }
            // check if there an updated PSL to load
            if !LOADING_UPDATED_PSL {
                if let etld_path = applicationSupportDirectory?
                    .appendingPathComponent(PSL_PLIST_NAME) {
                    if FileManager.default.fileExists(atPath: etld_path.path) {
                        _ruleTree = loadRuleTree(url: etld_path)
                        LOADED_UPDATED_PSL = true
                    }
                }
            }
            // check if there's an included PSL loaded
            if !_ruleTree.isEmpty {
                return _ruleTree
            }
            
            // load include PSL
            if let ruleTreeURL = PublicSuffix.ownBundle.url(forResource: PSL_RULES_NAME,
                                                            withExtension: PSL_RULES_FORMAT) {
                _ruleTree = loadRuleTree(url: ruleTreeURL)
            }
            return _ruleTree
        }
    }
    
    private func processRegisteredDomain(components: inout [String], ruleTree: [String: Any]) -> String? {
        if components.count == 0 {
            return nil
        }
        guard let lastComponent = components.last?.lowercased() else { return nil }
        components.removeLast()
        
        var result: String?
        if ruleTree[lastComponent] != nil {
            let subTree = ruleTree[lastComponent] as! [String: Any]
            if subTree["!"] != nil {
                return lastComponent
            } else {
                result = processRegisteredDomain(components: &components, ruleTree: subTree)
            }
        } else if ruleTree["*"] != nil {
            let subTree = ruleTree["*"] as! [String: Any]
            result = processRegisteredDomain(components: &components, ruleTree: subTree)
        } else {
            return lastComponent
        }
        
        guard let end_result = result else { return nil }
        if end_result.isEmpty {
            return nil
        } else {
            return "\(end_result).\(lastComponent)"
        }
    }
    
    public var registeredDomain: String? {
        get {
            if let self_host = self.host {
                if self_host.hasPrefix(".") || self_host.hasSuffix(".") {
                    return nil
                }
                var hostComponents: [String] = self_host.components(separatedBy: ".")
                if hostComponents.count < 2 {
                    return nil
                }
                return processRegisteredDomain(components: &hostComponents, ruleTree: PSLruleTree)
            }
            return nil
        }
    }
}
