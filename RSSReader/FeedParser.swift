import Foundation

class FeedParser: NSObject, XMLParserDelegate {
    private var items: [RSSFeedItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentDescription = ""
    private var completionHandler: (([RSSFeedItem]) -> Void)?

    func parseFeed(url: URL, completion: @escaping ([RSSFeedItem]) -> Void) {
        self.completionHandler = completion

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion([])
                return
            }

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        }.resume()
    }

    func parseMultipleFeeds(urls: [String], completion: @escaping ([RSSFeedItem]) -> Void) {
        let group = DispatchGroup()
        var allItems: [RSSFeedItem] = []

        for urlString in urls {
            if let url = URL(string: urlString) {
                group.enter()
                parseFeed(url: url) { items in
                    allItems += items
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            completion(allItems.sorted { $0.title > $1.title })
        }
    }

    // MARK: - XMLParserDelegate
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            currentTitle = ""
            currentLink = ""
            currentDescription = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
        case "title": currentTitle += string
        case "link": currentLink += string
        case "description": currentDescription += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            var imageUrl: String? = nil

            // RSS açıklamasında img varsa onu al
            if let range = currentDescription.range(of: "img src=\"") {
                let start = currentDescription[range.upperBound...]
                if let endRange = start.range(of: "\"") {
                    imageUrl = String(start[..<endRange.lowerBound])
                }
            }

            let item = RSSFeedItem(
                title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                description: currentDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                imageUrl: imageUrl
            )
            items.append(item)
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        completionHandler?(items)
    }
}
