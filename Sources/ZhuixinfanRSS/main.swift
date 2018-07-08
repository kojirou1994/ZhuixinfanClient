import Foundation
import Kitura
import HeliumLogger
import LoggerAPI
import Jobs

#if DEBUG
HeliumLogger.use(.debug)
#else
HeliumLogger.use()
#endif

let db = ZhuixinfanDB()

#if DEBUG
let updateTimeInterval: TimeInterval = 30
#else
let updateTimeInterval: TimeInterval = 3600 * 2
#endif

#if DEBUG
Log.debug("DEBUG MODE")
#else
var working = false

Jobs.add(interval: .seconds(updateTimeInterval)) {
    if working {
        return
    } else {
        working.toggle()
        Log.info("Begin update")
        db.newestSidLocal(callback: { (newestSidLocal) in
            let newestSidLocal = newestSidLocal + 1
            let newestSidRemote = db.newestSidRemote()
            guard newestSidLocal <= newestSidRemote else {
                Log.info("Newest SID local: \(newestSidLocal), Newest SID remote: \(newestSidRemote)")
                return
            }
            Log.info("Start get links from \(newestSidLocal) to \(newestSidRemote)")
            for sid in newestSidLocal...newestSidRemote {
                if db.fetch(sid: sid) {
                    Log.info("sid \(sid) get link successed!")
                } else {
                    Log.info("sid \(sid) get link failed!")
                }
            }
            Log.info("Finish update")
            working.toggle()
        })
    }
}
#endif

let router = Router()

router.get("/zhuixinfan") { request, response, next in
    Log.debug("Receive request: \(request)")
    response.headers["content-type"] = "application/xml"
    db.generateRssFeed(cb: { (xml) in
        response.send(xml)
        next()
    })
}

Kitura.addHTTPServer(onPort: 8082, with: router)
Kitura.run()
