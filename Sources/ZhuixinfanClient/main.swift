import MySQL
import Scrape
import Foundation

let mysql = MySQL()

let connected = mysql.connect(host: "127.0.0.1", user: "root", password: "root", db: "zhuixinfan")
guard connected else {
    fatalError(mysql.errorMessage())
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
        print(mysql.errorMessage())
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
        print(mysql.errorMessage())
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

func update(timer: Timer? = nil) {
    guard let newestSidLocal = newestSidLocal(), let newestSidRemote = newestSidRemote(),
          newestSidLocal < newestSidRemote else {
        return
    }
    for sid in newestSidLocal...newestSidRemote {
        autoreleasepool { () -> () in
            if sidExists(sid) {
                return
            }
            if fetch(sid: sid) {
                print("sid \(sid) get link successed!")
            } else {
                print("sid \(sid) get link failed!")
            }
        }
    }
}

if #available(OSX 10.12, *) {
    update()
    _ = Timer.scheduledTimer(withTimeInterval: 3600 * 24, repeats: true, block: update)
} else {
    // Fallback on earlier versions
    fatalError("Requirement: System Version >= 10.12")
}

RunLoop.main.run()
