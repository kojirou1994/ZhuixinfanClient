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
        let link = XMLElement(name: "link")
        let linkCDATA = XMLNode(kind: .text, options: .nodeIsCDATA)
        linkCDATA.stringValue = source.1
        link.addChild(linkCDATA)
        item.addChild(link)
        item.addChild(XMLElement(name: "description", stringValue: source.0))
        return item
    }
    
    let root = XMLElement(name: "rss")
    root.setAttributesWith(["version": "2.0"])
    let channel = XMLElement(name: "channel")
    channel.addChild(XMLElement(name: "title", stringValue: "Zhuixinfan"))
    channel.addChild(XMLElement(name: "link", stringValue: "http://www.zhuixinfan.com/main.php"))
    channel.addChild(XMLElement(name: "description", stringValue: "Free japan dramas."))
    for source in sources {
        channel.addChild(generateItem(source: source))
    }
    root.addChild(channel)
    let xml = XMLDocument(rootElement: root)
    xml.characterEncoding = "UTF-8"
    return xml.xmlString(options: .nodePrettyPrint)
}
