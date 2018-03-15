import MySQL
import Foundation
import Vapor
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

Jobs.add(interval: .seconds(updateTimeInterval)) {
    Log.info("Begin update")
    let newestSidLocal = db.newestSidLocal()
    let newestSidRemote = db.newestSidRemote()
    guard newestSidLocal < newestSidRemote else {
        return
    }
    for sid in newestSidLocal...newestSidRemote {
        if db.sidExists(sid) {
            // do nothing
        } else if db.fetch(sid: sid) {
            Log.info("sid \(sid) get link successed!")
        } else {
            Log.info("sid \(sid) get link failed!")
        }
    }
    Log.info("End update")
}

let drop = try Droplet.init()

drop.get("zhuixinfan") { (req) -> ResponseRepresentable in
    Log.debug("Receive request: \(req)")
    return db.generateRssFeed()
}

try drop.run()
