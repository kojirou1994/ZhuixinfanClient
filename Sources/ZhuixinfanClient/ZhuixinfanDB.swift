//
//  ZhuixinfanDB.swift
//  ZhuixinfanClient
//
//  Created by Kojirou on 2018/2/22.
//

import Foundation
import Scrape
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
    
    static let newestSid = 9216
    
    func newestSidRemote() -> Int {
        guard let link = URL(string: "http://www.zhuixinfan.com/main.php"),
            let document = HTMLDocument(url: link, encoding: .utf8) else {
                Log.error("Cannot open/parse zhuixinfan website.")
                return ZhuixinfanDB.newestSid
        }
        guard let result = document.search(byXPath: "//*[@id=\"wp\"]/table[2]/tr[2]/td[2]/a[2]").first?["href"],
            let url = URLComponents(string: result),
            let sid = url.queryItems?.first(where: { (item) -> Bool in
                item.name == "sid"
            })?.value else {
                Log.warning("No newest sid on zhuixinfan website.")
                return ZhuixinfanDB.newestSid
        }
        return Int(sid) ?? ZhuixinfanDB.newestSid
    }
    
    func newestSidLocal() -> Int? {
        guard mysql.query(statement: "SELECT MAX(sid) FROM viewresource") else {
            Log.error(mysql.errorMessage())
            return nil
        }
        if let result = mysql.storeResults()?.next(), let sidString = result[0], let sid = Int(sidString) {
            Log.error(sidString + "is not a valid local Sid.")
            return sid
        } else {
            return 0
        }
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
        guard let link = URL(string: "http://www.zhuixinfan.com/main.php?mod=viewresource&sid=\(sid)"),
            let document = HTMLDocument(url: link, encoding: .utf8) else {
                return false
        }
        let textResult = document.search(byXPath: "//*[@id=\"pdtname\"]")
        let ed2kResult = document.search(byXPath: "//*[@id=\"emule_url\"]")
        let magnetResult = document.search(byXPath: "//*[@id=\"torrent_url\"]")
        guard let text = textResult.first?.text,
            case let magnet = magnetResult.first?.text ?? "",
            case let ed2k = ed2kResult.first?.text ?? "",
            let newSource = ZhuixinfanSource(sid: sid, text: text, ed2k: ed2k, magnet: magnet) else {
                return false
        }
        return mysql.query(statement: newSource.insertQuery)
    }
    
    func generateRssFeed() -> Foundation.XMLDocument {
        
        func generateItem(source: (String, String)) -> Foundation.XMLNode {
            let item = XMLElement(name: "item")
            item.addChild(XMLElement(name: "title", stringValue: source.0))
            let link = XMLElement(name: "link")
            let linkCDATA = XMLNode(kind: .text, options: .nodeIsCDATA)
            linkCDATA.stringValue = source.1
            link.addChild(linkCDATA)
            item.addChild(link)
            item.addChild(XMLElement(name: "description", stringValue: source.0))
            return item
        }
        
        guard mysql.query(statement: "SELECT text, magnet FROM viewresource ORDER BY sid DESC LIMIT 50") else {
            Log.error(mysql.errorMessage())
            let root = XMLElement(name: "rss")
            root.setAttributesWith(["version": "2.0"])
            let channel = XMLElement(name: "channel")
            channel.addChild(XMLElement(name: "title", stringValue: "Zhuixinfan"))
            channel.addChild(XMLElement(name: "link", stringValue: "http://www.zhuixinfan.com/main.php"))
            channel.addChild(XMLElement(name: "description", stringValue: "Free japan dramas."))
            root.addChild(channel)
            let xml = XMLDocument(rootElement: root)
            xml.characterEncoding = "UTF-8"
            return xml
        }
        
        var sources = [(String, String)]()
        mysql.storeResults()?.forEachRow(callback: { (row) in
            if let text = row[0], let magnet = row[1] {
                sources.append((text, magnet))
            }
        })
        
        let root = XMLElement(name: "rss")
        root.setAttributesWith(["version": "2.0"])
        let channel = XMLElement(name: "channel")
        channel.addChild(XMLElement(name: "title", stringValue: "Zhuixinfan"))
        channel.addChild(XMLElement(name: "link", stringValue: "http://www.zhuixinfan.com/main.php"))
        channel.addChild(XMLElement(name: "description", stringValue: "Free japan dramas."))
        for source in sources {
            channel.addChild(generateItem(source: source))
        }
        root.addChild(channel)
        let xml = XMLDocument(rootElement: root)
        xml.characterEncoding = "UTF-8"
        return xml
    }
}
