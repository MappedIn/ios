import UIKit
import Mappedin

/// Shows that icon SVGs use `fill="currentColor"` and recolor instantly without re-fetching.
///
/// Tapping a swatch updates the `currentColor` applied to every rendered icon.
final class ColorPickerViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let icons: Icons
    private let sampleSize = 40
    private let swatches = ["#333333", "#ff5733", "#2266ff", "#1faa59", "#a855f7", "#e91e63"]

    private var iconList: [MappedinIcon] = []
    private var svgCache: [String: String] = [:]
    private var currentColor = "#333333"
    private var collectionView: UICollectionView!

    init(icons: Icons) {
        self.icons = icons
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let explanation = UILabel()
        explanation.translatesAutoresizingMaskIntoConstraints = false
        explanation.text = "Icons use fill=\"currentColor\" and inherit the container color. Tap a swatch to recolor."
        explanation.font = .systemFont(ofSize: 13)
        explanation.textColor = .secondaryLabel
        explanation.numberOfLines = 0

        let swatchStack = UIStackView()
        swatchStack.translatesAutoresizingMaskIntoConstraints = false
        swatchStack.axis = .horizontal
        swatchStack.distribution = .fillEqually
        swatchStack.spacing = 8
        for (index, hex) in swatches.enumerated() {
            let button = UIButton(type: .system)
            button.backgroundColor = UIColor(hex: hex)
            button.layer.cornerRadius = 6
            button.tag = index
            button.heightAnchor.constraint(equalToConstant: 36).isActive = true
            button.addTarget(self, action: #selector(swatchTapped(_:)), for: .touchUpInside)
            swatchStack.addArrangedSubview(button)
        }

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 70, height: 56)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 16, right: 12)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(IconWebCell.self, forCellWithReuseIdentifier: IconWebCell.reuseId)

        view.addSubview(explanation)
        view.addSubview(swatchStack)
        view.addSubview(collectionView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            explanation.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            explanation.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            explanation.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),

            swatchStack.topAnchor.constraint(equalTo: explanation.bottomAnchor, constant: 12),
            swatchStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            swatchStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),

            collectionView.topAnchor.constraint(equalTo: swatchStack.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        icons.getByType(type: .categories) { [weak self] result in
            guard let self = self, case .success(let all) = result else { return }
            DispatchQueue.main.async {
                self.iconList = Array(all.prefix(self.sampleSize))
                self.collectionView.reloadData()
            }
        }
    }

    @objc private func swatchTapped(_ sender: UIButton) {
        currentColor = swatches[sender.tag]
        collectionView.reloadData()
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        iconList.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IconWebCell.reuseId, for: indexPath) as! IconWebCell
        let icon = iconList[indexPath.item]
        cell.representedName = icon.name

        if let cached = svgCache[icon.name] {
            cell.webView.renderIconSvg(cached, color: currentColor)
            return cell
        }

        icons.fetchSvg(name: icon.name) { [weak self] result in
            guard let self = self, case .success(let svg) = result else { return }
            self.svgCache[icon.name] = svg
            DispatchQueue.main.async {
                if cell.representedName == icon.name {
                    cell.webView.renderIconSvg(svg, color: self.currentColor)
                }
            }
        }
        return cell
    }
}

// MARK: - UIColor hex helper

extension UIColor {
    /// Creates a color from a "#rrggbb" hex string. Falls back to gray on parse failure.
    convenience init(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = CGFloat((value & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((value & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(value & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
