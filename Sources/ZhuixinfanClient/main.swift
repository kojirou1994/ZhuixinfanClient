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

let db = ZhuixinfanDB()

func update(timer: Timer? = nil) {
    guard let newestSidLocal = db.newestSidLocal(), case let newestSidRemote = db.newestSidRemote(),
          newestSidLocal < newestSidRemote else {
        return
    }
    for sid in newestSidLocal...newestSidRemote {
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


#if os(macOS)
if #available(OSX 10.12, *) {
    update()
    _ = Timer.scheduledTimer(withTimeInterval: 3600 * 2, repeats: true, block: update)
} else {
    // Fallback on earlier versions
    fatalError("Requirement: System Version >= 10.12")
}
#else
update()
_ = Timer.scheduledTimer(withTimeInterval: 3600 * 2, repeats: true, block: update)
#endif

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
    response.writeHeader(status: .ok)
    response.writeBody(db.generateRssFeed().xmlString)
    response.done()
    return .discardBody
}

let server = HTTPServer()
try server.start(port: 8082, handler: rss)

RunLoop.main.run()
