//
//  FeedListViewController.swift
//  Newsly
//
//  📲 Newsly: Akıllı ve şık bir RSS okuyucu.
//  En güncel haberleri BBC, NYTimes ve Guardian'dan çekerek,
//  başlık, özet ve görsellerle birlikte sade bir arayüzde sunar.
//

import UIKit

class FeedListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!

    var feedItems: [RSSFeedItem] = []
    let parser = FeedParser()
    let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        // Yenileme desteği
        refreshControl.addTarget(self, action: #selector(refreshFeed), for: .valueChanged)
        tableView.refreshControl = refreshControl

        fetchAllFeeds()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = feedItems[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedCell", for: indexPath)

        if let logoImageView = cell.viewWithTag(1) as? UIImageView,
           let titleLabel = cell.viewWithTag(2) as? UILabel {
            
            titleLabel.text = item.title

            // Kaynağa göre logo ata
            if item.link.contains("bbc") {
                logoImageView.image = UIImage(named: "bbc")
            } else if item.link.contains("nytimes") {
                logoImageView.image = UIImage(named: "nyt")
            } else if item.link.contains("guardian") {
                logoImageView.image = UIImage(named: "guardian")
            } else {
                logoImageView.image = nil
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = feedItems[indexPath.row]

        // Sayfadaki görseli çek
        fetchImageFromPage(item.link) { imageUrl in
            DispatchQueue.main.async {
                if let detailVC = self.storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController {
                    detailVC.newsTitle = item.title
                    detailVC.newsDescription = item.description
                    detailVC.newsLink = item.link
                    detailVC.newsImageUrl = imageUrl ?? item.imageUrl // varsa HTML'den, yoksa RSS içinden al
                    self.navigationController?.pushViewController(detailVC, animated: true)
                }
            }
        }
    }

    @objc func refreshFeed() {
        fetchAllFeeds()
    }

    func fetchAllFeeds() {
        let urls = [
            "https://feeds.bbci.co.uk/news/world/rss.xml",
            "https://rss.nytimes.com/services/xml/rss/nyt/HomePage.xml",
            "https://www.theguardian.com/world/rss"
        ]

        parser.parseMultipleFeeds(urls: urls) { items in
            var seenTitles = Set<String>()
            let uniqueItems = items.filter { seenTitles.insert($0.title).inserted }
            self.feedItems = uniqueItems
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }

    // Sayfadan og:image veya twitter:image çek
    func fetchImageFromPage(_ urlString: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }

            if let ogImage = self.extractMetaTag(from: html, property: "og:image") {
                completion(ogImage)
                return
            }

            if let twitterImage = self.extractMetaTag(from: html, property: "twitter:image") {
                completion(twitterImage)
                return
            }

            completion(nil)
        }.resume()
    }

    func extractMetaTag(from html: String, property: String) -> String? {
        let pattern = "<meta[^>]+(property|name)=[\"']\(property)[\"'][^>]+content=[\"']([^\"']+)[\"']"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(html.startIndex..., in: html)
            if let match = regex.firstMatch(in: html, options: [], range: range),
               let contentRange = Range(match.range(at: 2), in: html) {
                return String(html[contentRange])
            }
        }
        return nil
    }
}
