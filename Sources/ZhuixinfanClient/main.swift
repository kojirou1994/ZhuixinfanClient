import MySQL
import Foundation
import Vapor
import HeliumLogger
import LoggerAPI

#if DEBUG
HeliumLogger.use(.debug)
#else
HeliumLogger.use()
#endif

let db = ZhuixinfanDB()

func update(timer: Timer? = nil) {
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

#if DEBUG
let updateTimeInterval: TimeInterval = 30
#else
let updateTimeInterval: TimeInterval = 3600 * 2
#endif

#if os(macOS)
if #available(OSX 10.12, *) {
    update()
    _ = Timer.scheduledTimer(withTimeInterval: updateTimeInterval, repeats: true, block: update)
} else {
    // Fallback on earlier versions
    fatalError("Requirement: System Version >= 10.12")
}
#else
update()
_ = Timer.scheduledTimer(withTimeInterval: updateTimeInterval, repeats: true, block: update)
#endif

let drop = try Droplet.init()

drop.get("zhuixinfan") { (req) -> ResponseRepresentable in
    Log.debug("Receive request: \(req)")
    return db.generateRssFeed()
}

try drop.run()
