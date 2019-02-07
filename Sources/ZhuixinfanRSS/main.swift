import Foundation
import Kitura
import HeliumLogger
import LoggerAPI

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

let updateQueue = DispatchQueue.init(label: "ZhuixinfanRSS")

func update() {
    Log.info("Begin update")
    db.newestSidLocal(callback: { (newestSidLocal) in
        let newestSidLocal = newestSidLocal + 1
        let newestSidRemote = db.newestSidRemote()
        guard newestSidLocal <= newestSidRemote else {
            Log.info("Newest SID local: \(newestSidLocal-1), Newest SID remote: \(newestSidRemote)")
            updateQueue.asyncAfter(deadline: DispatchTime.now() + updateTimeInterval, execute: update)
            return
        }
        Log.info("Start get links from \(newestSidLocal) to \(newestSidRemote)")
        for sid in newestSidLocal...newestSidRemote {
            db.fetch(sid: sid)
        }
        db.fetchQueue.waitUntilAllOperationsAreFinished()
        Log.info("Finish update")
        updateQueue.asyncAfter(deadline: DispatchTime.now() + updateTimeInterval, execute: update)
    })
}
updateQueue.async(execute: update)

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
