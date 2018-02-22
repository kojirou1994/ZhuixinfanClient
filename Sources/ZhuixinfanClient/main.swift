import MySQL
import Scrape
import Foundation
import HTTP
import HeliumLogger
import LoggerAPI

#if DEBUG
HeliumLogger.use(.debug)
#else
HeliumLogger.use()
#endif

class ZhuixinfanDB {
    
    let mysql: MySQL
    static let mysqlQueue = DispatchQueue(label: "mysql")
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
    
    func newestSidRemote() -> Int? {
        guard let link = URL(string: "http://www.zhuixinfan.com/main.php"),
            let document = HTMLDocument(url: link, encoding: .utf8) else {
                return nil
        }
        guard let result = document.search(byXPath: "//*[@id=\"wp\"]/table[2]/tr[2]/td[2]/a[2]").first?["href"],
            let url = URLComponents(string: result),
            let sid = url.queryItems?.first(where: { (item) -> Bool in
                item.name == "sid"
            })?.value else {
                return nil
        }
        return Int(sid)
    }
    
    func newestSidLocal() -> Int? {
        guard mysql.query(statement: "SELECT MAX(sid) FROM viewresource") else {
            Log.error(mysql.errorMessage())
            return nil
        }
        if let result = mysql.storeResults()?.next(), let sidString = result[0], let sid = Int(sidString) {
            return sid
        } else {
            return nil
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
    
    func fetchNewestSources() -> [(String, String)]? {
        return ZhuixinfanDB.mysqlQueue.sync { () -> [(String, String)]? in
            guard mysql.query(statement: "SELECT text, magnet FROM viewresource ORDER BY sid DESC LIMIT 50") else {
                Log.error(mysql.errorMessage())
                return nil
            }
            
            var sources = [(String, String)]()
            mysql.storeResults()?.forEachRow(callback: { (row) in
                if let text = row[0], let magnet = row[1] {
                    sources.append((text, magnet))
                }
            })
            return sources.count > 0 ? sources : nil
        }
    }
}

let db = ZhuixinfanDB()

func update(timer: Timer? = nil) {
    guard let newestSidLocal = db.newestSidLocal(), let newestSidRemote = db.newestSidRemote(),
          newestSidLocal < newestSidRemote else {
        return
    }
    for sid in newestSidLocal...newestSidRemote {
        autoreleasepool { () -> () in
            if db.sidExists(sid) {
                return
            }
            if db.fetch(sid: sid) {
                Log.info("sid \(sid) get link successed!")
            } else {
                Log.info("sid \(sid) get link failed!")
            }
        }
    }
}

if #available(OSX 10.12, *) {
//    update()
    _ = Timer.scheduledTimer(withTimeInterval: 3600 * 2, repeats: true, block: update)
} else {
    // Fallback on earlier versions
    fatalError("Requirement: System Version >= 10.12")
}

func rss(request: HTTPRequest, response: HTTPResponseWriter ) -> HTTPBodyProcessing {
    Log.debug("Receive request: \(request)")
    guard let pathComponents = URLComponents(string: request.target) else {
        // Invalid path
        response.writeHeader(status: .badRequest)
        response.done()
        return .discardBody
    }
    guard pathComponents.path == "/zhuixinfan" else {
        // Undefined path
        response.writeHeader(status: .badGateway)
        response.done()
        return .discardBody
    }
    if let sources = db.fetchNewestSources() {
        response.writeHeader(status: .ok)
        response.writeBody(generateXML(sources: sources))
    } else {
        response.writeHeader(status: .badGateway)
    }
    response.done()
    return .discardBody
}

let server = HTTPServer()
try server.start(port: 8082, handler: rss)

RunLoop.main.run()
