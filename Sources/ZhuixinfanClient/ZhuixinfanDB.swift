//
//  ZhuixinfanDB.swift
//  ZhuixinfanClient
//
//  Created by Kojirou on 2018/2/22.
//

import Foundation
import MySQL
import LoggerAPI

class ZhuixinfanDB {
    
    let mysql: MySQL
    
    init() {
        mysql = MySQL()
        #if DEBUG
        let connected = mysql.connect(host: "10.0.0.47", user: "root", password: "root", db: "zhuixinfan")
        #else
        let connected = mysql.connect(host: "127.0.0.1", user: "root", password: "root", db: "zhuixinfan")
        #endif
        guard connected else {
            fatalError(mysql.errorMessage())
        }
    }
    
    deinit {
        mysql.close()
    }
    
    static let newestSid = 9216
    
    static let zxfMainPage = URL(string: "http://www.zhuixinfan.com/main.php")!
    
    func newestSidRemote() -> Int {
        do {
            let document = try XMLDocument(contentsOf: ZhuixinfanDB.zxfMainPage, options: .documentTidyHTML)
            for table in 2...8 {
                if let result = try document.nodes(forXPath: "//*[@id=\"wp\"]/table[\(table)]/tr[2]/td[2]/a[2]").first as? XMLElement,
                    let hrefNode = result.attribute(forName: "href"),
                    let href = hrefNode.stringValue,
                    let url = URLComponents(string: href),
                    let sidString = url.queryItems?.first(where: { (item) -> Bool in
                        item.name == "sid"
                    })?.value {
                    return Int(sidString) ?? ZhuixinfanDB.newestSid
                }
            }
            return ZhuixinfanDB.newestSid
        } catch {
            Log.error(error.localizedDescription)
            return ZhuixinfanDB.newestSid
        }
    }
    
    func newestSidLocal() -> Int {
        guard mysql.query(statement: "SELECT MAX(sid) FROM viewresource") else {
            Log.error(mysql.errorMessage())
            return 0
        }
        if let result = mysql.storeResults()?.next(), let sidString = result[0], let sid = Int(sidString) {
            return sid
        }
        return 0
    }
    
    func sidExists(_ sid: Int) -> Bool {
        guard mysql.query(statement: "select 1 from viewresource where sid = \(sid) limit 1") else {
            Log.error(mysql.errorMessage())
            return false
        }
        let result = mysql.storeResults()!
        return result.next()?[0] == "1"
    }
    
    func fetch(sid: Int) -> Bool {
        guard let link = URL(string: "http://www.zhuixinfan.com/main.php?mod=viewresource&sid=\(sid)") else {
            Log.error("Not a valid url for sid \(sid)")
            return false
        }
        
        do {
            let document  = try XMLDocument(contentsOf: link, options: XMLNode.Options.documentTidyHTML)
            let textResult = try document.nodes(forXPath: "//*[@id=\"pdtname\"]")
            let ed2kResult = try document.nodes(forXPath: "//*[@id=\"emule_url\"]")
            let magnetResult = try document.nodes(forXPath: "//*[@id=\"torrent_url\"]")
            guard let text = textResult.first?.stringValue,
                case let magnet = magnetResult.first?.stringValue ?? "",
                case let ed2k = ed2kResult.first?.stringValue ?? "",
                let newSource = ZhuixinfanSource(sid: sid, text: text, ed2k: ed2k, magnet: magnet) else {
                    Log.warning("Cannot get links from zhuixinfan site.")
                    return false
            }
            let result = mysql.query(statement: newSource.insertQuery)
            if result {
                Log.error("Insert to mysql success")
            } else {
                Log.error("Insert to mysql failed")
            }
            return result
        } catch {
            Log.error(error.localizedDescription)
            return false
        }
    }
    
    func generateRssFeed() -> XMLDocument {
        let root = XMLElement(name: "rss")
        root.setAttributesWith(["version": "2.0"])
        let channel = XMLElement(name: "channel")
        channel.addChild(XMLElement(name: "title", stringValue: "Zhuixinfan"))
        channel.addChild(XMLElement(name: "link", stringValue: "http://www.zhuixinfan.com/main.php"))
        channel.addChild(XMLElement(name: "description", stringValue: "Free japan dramas."))
        
        if mysql.query(statement: "SELECT text, magnet FROM viewresource ORDER BY sid DESC LIMIT 50") {
            mysql.storeResults()?.forEachRow(callback: { (row) in
                if let text = row[0], let magnet = row[1] {
                    let item = XMLElement(name: "item")
                    item.addChild(XMLElement(name: "title", stringValue: text))
                    let link = XMLElement(name: "link")
                    let linkCDATA = XMLNode(kind: .text, options: .nodeIsCDATA)
                    linkCDATA.stringValue = magnet
                    link.addChild(linkCDATA)
                    item.addChild(link)
                    item.addChild(XMLElement(name: "description", stringValue: text))
                    channel.addChild(item)
                }
            })
        }
        
        root.addChild(channel)
        let xml = XMLDocument(rootElement: root)
        xml.characterEncoding = "UTF-8"
        return xml
    }
}
