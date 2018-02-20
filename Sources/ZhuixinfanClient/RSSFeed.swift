//
//  RSSFeed.swift
//  ZhuixinfanClient
//
//  Created by Kojirou on 2017/11/6.
//

import Foundation

func generateXML(sources: [(String, String)]) -> String {
    
    func generateItem(source: (String, String)) -> XMLNode {
        let item = XMLElement(name: "item")
        item.addChild(XMLElement(name: "title", stringValue: source.0))
        item.addChild(XMLElement(name: "link", stringValue: "<![CDATA[\(source.1)]]>"))
        item.addChild(XMLElement(name: "description", stringValue: source.0))
        return item
    }
    
    let root = XMLElement(name: "rss")
    root.setAttributesWith(["version": "2.0"])
    let channel = XMLElement(name: "channel")
    channel.addChild(XMLElement(name: "title", stringValue: "Zhuixinfan"))
    channel.addChild(XMLElement(name: "link", stringValue: "http://www.zhuixinfan.com/main.php"))
    channel.addChild(XMLElement(name: "description", stringValue: "Free japan dramas."))
    root.addChild(channel)
    let xml = XMLDocument(rootElement: root)
    xml.characterEncoding = "UTF-8"
    return xml.xmlString(options: .nodePrettyPrint)
}
