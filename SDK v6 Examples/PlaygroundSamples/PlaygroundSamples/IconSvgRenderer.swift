import UIKit
import WebKit

/// Shared helpers for rendering Mappedin icon SVGs in the Icons demos.
///
/// Mappedin icon SVGs use `fill="currentColor"`, so the icon color is controlled
/// by the CSS `color` of the container. Rendering each SVG in a small `WKWebView`
/// faithfully mirrors the web examples and supports instant recoloring.
extension WKWebView {
    /// Renders a Mappedin icon SVG string, tinted with `currentColor`.
    ///
    /// - Parameters:
    ///   - svg: The raw SVG markup returned by `mapView.icons.fetchSvg(...)`
    ///   - color: A CSS color string (e.g. "#2266ff") applied via `currentColor`
    func renderIconSvg(_ svg: String, color: String) {
        isOpaque = false
        backgroundColor = .clear
        scrollView.backgroundColor = .clear
        scrollView.isScrollEnabled = false
        let html = """
        <!DOCTYPE html>
        <html>
          <head><meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"></head>
          <body style="margin:0;padding:0;height:100vh;display:flex;align-items:center;justify-content:center;color:\(color);">
            <div style="width:70%;height:70%;display:flex;align-items:center;justify-content:center;">\(svg)</div>
          </body>
        </html>
        """
        loadHTMLString(html, baseURL: nil)
    }
}

/// Collection view cell that renders a single icon SVG in a `WKWebView`.
final class IconWebCell: UICollectionViewCell {
    static let reuseId = "IconWebCell"

    let webView = WKWebView()
    let label = UILabel()

    /// The icon name currently represented by this cell, used to guard against
    /// stale async renders after the cell is recycled.
    var representedName: String?

    override init(frame: CGRect) {
        super.init(frame: frame)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isUserInteractionEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 9)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2

        contentView.addSubview(webView)
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: contentView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            webView.heightAnchor.constraint(equalToConstant: 48),

            label.topAnchor.constraint(equalTo: webView.bottomAnchor, constant: 2),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            label.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Simple section header showing a title above a group of icons.
final class IconSectionHeader: UICollectionReusableView {
    static let reuseId = "IconSectionHeader"

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 15)
        label.textColor = .label
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
