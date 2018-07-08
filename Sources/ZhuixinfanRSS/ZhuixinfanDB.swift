//
//  ZhuixinfanDB.swift
//  ZhuixinfanClient
//
//  Created by Kojirou on 2018/2/22.
//

import Foundation
import SwiftKuery
import SwiftKueryORM
import SwiftKueryPostgreSQL
import LoggerAPI

class ZhuixinfanDB {
    
    let server: ConnectionPool
    
    init() {
        server = PostgreSQLConnection.createPool(host: "localhost", port: 5432, options: [.databaseName("zhuixinfan")], poolOptions: ConnectionPoolOptions(initialCapacity: 10, maxCapacity: 50, timeout: 10000))
        Database.default = Database.init(server)
        do {
            try ZhuixinfanResource.createTableSync()
        } catch {
            print(error)
        }
        fetchQueue = OperationQueue.init()
        fetchQueue.maxConcurrentOperationCount = 8
    }
    
    deinit {
        server.disconnect()
    }
    
    static let newestSid = 9539
    
    static let zxfMainPage = URL(string: "http://www.zhuixinfan.com/main.php")!
    
    func newestSidRemote() -> Int {
        return autoreleasepool { () -> Int in
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
    }
    
    func newestSidLocal(callback: @escaping (Int) -> ()) {
        let table = try! ZhuixinfanResource.getTable()
        
        let query = Select.init(max(RawField.init("sid")), from: table)

        server.getConnection()?.execute(query: query, onCompletion: { (result) in

            if let rows = result.asRows, let row = rows.first, let sid = row.values.first, let sidValue = sid as? Int64 {
                callback(Int(sidValue))
            } else {
                callback(0)
                Log.info(result.asError!.localizedDescription)
            }

        })

    }
    
    func sidExists(_ sid: Int) -> Bool {
        
        struct QuerySid: QueryParams {
            let sid: Int
        }
        var res = false
        let cond = NSCondition()
        cond.lock()
        var taskFinished = false
        ZhuixinfanResource.find(id: sid) { (source, error) in
            cond.lock()
            if let _ = source {
                res = true
            } else {
                print(error?.description ?? "No Error Info.")
            }
            taskFinished = true
            cond.signal()
            cond.unlock()
        }
        while taskFinished == false {
            cond.wait()
        }
        cond.unlock()
        
        return res

    }
    
    let fetchQueue: OperationQueue
    
    func fetch(sid: Int) {
        let link = URL(string: "http://www.zhuixinfan.com/main.php?mod=viewresource&sid=\(sid)")!
        fetchQueue.addOperation {
            do {
                let document  = try XMLDocument(contentsOf: link, options: XMLNode.Options.documentTidyHTML)
                let textResult = try document.nodes(forXPath: "//*[@id=\"pdtname\"]")
                let ed2kResult = try document.nodes(forXPath: "//*[@id=\"emule_url\"]")
                let magnetResult = try document.nodes(forXPath: "//*[@id=\"torrent_url\"]")
                let drive1Result = try document.nodes(forXPath: "//*[@id=\"wp\"]/div[2]/div/div[2]/div[2]/a[3]")
                let drive2Result = try document.nodes(forXPath: "//*[@id=\"wp\"]/div[2]/div/div[2]/div[2]/a[4]")
                guard let text = textResult.first?.stringValue,
                    case let magnet = magnetResult.first?.stringValue ?? "",
                    case let ed2k = ed2kResult.first?.stringValue ?? "",
                    case let drive1Node = drive1Result.first as? XMLElement,
                    case let drive1 = drive1Node?.attribute(forName: "href")?.stringValue,
                    case let drive2Node = drive2Result.first as? XMLElement,
                    case let drive2 = drive2Node?.attribute(forName: "href")?.stringValue,
                    let newSource = ZhuixinfanResource(sid: sid, text: text, ed2k: ed2k, magnet: magnet, drive1: drive1, drive2: drive2) else {
                        return
                }

                newSource.save({ (source, error) in
                    if error == nil {
                        Log.info("sid \(sid) get link successed!")
                    } else {
                        Log.info("sid \(sid) get link failed!")
                        dump(error!)
                    }

                })

            } catch {
                Log.error(error.localizedDescription)
                Log.info("sid \(sid) get link failed!")
            }
        }
    }
    
    func generateRssFeed(cb: @escaping (String) -> ()) {
        let query = Select.init(from: try! ZhuixinfanResource.getTable())
                        .order(by: OrderBy.DESC(RawField.init("sid")))
                        .limit(to: 50)
        ZhuixinfanResource.executeQuery(query: query) { (resources, error) in
            guard let resources = resources, error == nil else {
                Log.error(error?.description ?? "NO ERROR INFO")
                cb("")
                return
            }
            autoreleasepool(invoking: {
                let root = XMLElement(name: "rss")
                root.setAttributesWith(["version": "2.0"])
                let channel = XMLElement(name: "channel")
                channel.addChild(XMLElement(name: "title", stringValue: "Zhuixinfan"))
                channel.addChild(XMLElement(name: "link", stringValue: "http://www.zhuixinfan.com/main.php"))
                channel.addChild(XMLElement(name: "description", stringValue: "Free japan dramas."))
                
                resources.forEach({ (resource) in
                    let item = XMLElement(name: "item")
                    item.addChild(XMLElement(name: "title", stringValue: resource.text))
                    let link = XMLElement(name: "link")
                    let linkCDATA = XMLNode(kind: .text, options: .nodeIsCDATA)
                    linkCDATA.stringValue = resource.magnet
                    link.addChild(linkCDATA)
                    item.addChild(link)
                    item.addChild(XMLElement(name: "description", stringValue: resource.text))
                    channel.addChild(item)
                })
                
                root.addChild(channel)
                let xml = XMLDocument(rootElement: root)
                xml.characterEncoding = "UTF-8"
                cb(xml.xmlString)
            })

        }
        
    }

}
