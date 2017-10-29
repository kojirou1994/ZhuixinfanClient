//
//  ZhuixinfanSource.swift
//  ZhuixinfanClient
//
//  Created by Kojirou on 2017/10/28.
//

import Foundation

struct ZhuixinfanSource {
    let sid: Int
    let text: String
    let ed2k: String
    let magnet: String
    let drive1: String?
    let drive2: String?
    
    init?(sid: Int, text: String, ed2k: String, magnet: String, drive1: String? = nil, drive2: String? = nil) {
        guard sid > 0, !text.isEmpty, /*!magnet.isEmpty,*/
              !text.contains("\""), !magnet.contains("\""), !ed2k.contains("\"") else {
            return nil
        }
        self.sid = sid
        self.text = text
        self.ed2k = ed2k.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        self.magnet = magnet.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        self.drive1 = drive1
        self.drive2 = drive2
    }
    
    var insertQuery: String {
        return """
        INSERT INTO viewresource
        (sid, text, ed2k, magnet, drive1, drive2)
        VALUES
        (\(sid), "\(text)", "\(ed2k)", "\(magnet)", "\(drive1 ?? "")", "\(drive2 ?? "")");
        """
    }
}
