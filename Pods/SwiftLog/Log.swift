//////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Log.swift
//
//  Created by Dalton Cherry on 12/23/14.
//  Copyright (c) 2014 Vluxe. All rights reserved.
//
//  Simple logging class.
//////////////////////////////////////////////////////////////////////////////////////////////////

import Foundation

///The log class containing all the needed methods
open class Log {
    
    ///The max size a log file can be in Kilobytes. Default is 1024 (1 MB)
    open var maxFileSize: UInt64 = 1024
    
    ///The max number of log file that will be stored. Once this point is reached, the oldest file is deleted.
    open var maxFileCount = 4
    
    ///The directory in which the log files will be written
    open var directory = Log.defaultDirectory() {
        didSet {
            #if os(macOS)
                if directory.hasPrefix("~") {
                    let homeDir = URL(fileURLWithPath: NSHomeDirectory()).path
                    let index = directory.index(after: directory.startIndex)
                    let filePath = directory[index...]
                    directory = "\(homeDir)\(filePath)"
                }
            #endif
            
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: directory) {
                do {
                    try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    NSLog("Couldn't create directory at \(directory)")
                }
            }
        }
    }
    
    //The name of the log files.
    open var name = "logfile"
    
    ///logging singleton
    open class var logger: Log {
        
        struct Static {
            static let instance: Log = Log()
        }
        return Static.instance
    }
    //the date formatter
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .medium
        return formatter
    }
    
    ///write content to the current log file.
    open func write(_ text: String) {
        let path = "\(directory)/\(logName(0))"
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) {
            do {
                try "".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            } catch _ {
            }
        }
        if let fileHandle = FileHandle(forWritingAtPath: path) {
            let dateStr = dateFormatter.string(from: Date())
            let writeText = "[\(dateStr)]: \(text)\n"
            fileHandle.seekToEndOfFile()
            fileHandle.write(writeText.data(using: String.Encoding.utf8)!)
            fileHandle.closeFile()
            print(writeText, terminator: "")
            cleanup()
        }
    }
    ///do the checks and cleanup
    func cleanup() {
        let path = "\(directory)/\(logName(0))"
        let size = fileSize(path)
        let maxSize: UInt64 = maxFileSize*1024
        if size > 0 && size >= maxSize && maxSize > 0 && maxFileCount > 0 {
            rename(0)
            //delete the oldest file
            let deletePath = "\(directory)/\(logName(maxFileCount))"
            let fileManager = FileManager.default
            do {
                try fileManager.removeItem(atPath: deletePath)
            } catch _ {
            }
        }
    }
    
    ///check the size of a file
    func fileSize(_ path: String) -> UInt64 {
        let fileManager = FileManager.default
        let attrs: NSDictionary? = try? fileManager.attributesOfItem(atPath: path) as NSDictionary
        if let dict = attrs {
            return dict.fileSize()
        }
        return 0
    }
    
    ///Recursive method call to rename log files
    func rename(_ index: Int) {
        let fileManager = FileManager.default
        let path = "\(directory)/\(logName(index))"
        let newPath = "\(directory)/\(logName(index+1))"
        if fileManager.fileExists(atPath: newPath) {
            rename(index+1)
        }
        do {
            try fileManager.moveItem(atPath: path, toPath: newPath)
        } catch _ {
        }
    }
    
    ///gets the log name
    func logName(_ num :Int) -> String {
        return "\(name)-\(num).log"
    }
    
    ///get the default log directory
    class func defaultDirectory() -> String {
        var path = ""
        let fileManager = FileManager.default
        #if os(iOS)
            let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            path = "\(paths[0])/Logs"
        #elseif os(macOS)
            let urls = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)
            if let url = urls.last {
                path = "\(url.path)/Logs"
            }
        #endif
        if !fileManager.fileExists(atPath: path) && path != ""  {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
            } catch _ {
            }
        }
        return path
    }
    
}

///a free function to make writing to the log much nicer
public func logw(_ text: String) {
    Log.logger.write(text)
}
