//
//  ZhuixinfanSource.swift
//  ZhuixinfanClient
//
//  Created by Kojirou on 2017/10/28.
//

import Foundation
import SwiftKueryORM

extension CharacterSet {
    public func contains(_ member: Character) -> Bool {
        let us = member.unicodeScalars
        if us.count == 1 {
            return contains(us.first!)
        } else {
            return false
        }
    }
}
func cleanText(_ str: String) -> String {
    var out = ""
    for char in str {
        if !(CharacterSet.whitespacesAndNewlines.contains(char) || CharacterSet.controlCharacters.contains(char)) {
            out.append(char)
        }
    }
    return out
}

struct ZhuixinfanResource: Codable {
    
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
        if ed2k.hasPrefix("magnet"), magnet.hasPrefix("ed2k") {
            self.ed2k = cleanText(magnet)
            self.magnet = cleanText(ed2k)
        } else {
            self.ed2k = cleanText(ed2k)
            self.magnet = cleanText(magnet)
        }
        self.drive1 = drive1
        self.drive2 = drive2
    }
    
}

extension ZhuixinfanResource: Model {
    
    static var tableName: String {
        return "resource"
    }
    
    static var idColumnName: String {
        return "sid"
    }
    
}
