import UIKit

class DetailViewController: UIViewController {

    var newsTitle: String?
    var newsDescription: String?
    var newsLink: String?
    var newsImageUrl: String?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var newsImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = newsTitle
        descriptionTextView.text = newsDescription?.htmlToPlainText()

        // Görsel yükle
        if let imageUrl = newsImageUrl, let url = URL(string: imageUrl) {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.newsImageView.image = UIImage(data: data)
                    }
                }
            }
        }
    }

    @IBAction func openLinkTapped(_ sender: UIButton) {
        if let link = newsLink, let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
    }
}
