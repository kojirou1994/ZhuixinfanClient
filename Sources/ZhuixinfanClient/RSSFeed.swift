//
//  RSSFeed.swift
//  ZhuixinfanClient
//
//  Created by Kojirou on 2017/11/6.
//

import Foundation

func generateXML(sources: [(String, String)]) -> String {
    
    func generateItem(source: (String, String)) -> String {
        return """
            <item>
            <title>\(source.0)</title>
            <link>\(source.1.removingPercentEncoding!)</link>
            <description>\(source.0)</description>
            </item>
        """
//        <enclosure type="application/x-bittorrent" url="\(source.1)"/>
    }
    
    return """
    <?xml version="1.0" encoding="UTF-8" ?>
    <rss version="2.0">

    <channel>
    <title>Zhuixinfan</title>
    <link>http://www.zhuixinfan.com/main.php</link>
    <description>Free japan dramas.</description>
    \(sources.map(generateItem).joined(separator: "\n"))
    </channel>

    </rss>
    """
}
