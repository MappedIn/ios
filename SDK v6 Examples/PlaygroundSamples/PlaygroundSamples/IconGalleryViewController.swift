import UIKit
import Mappedin

/// Lists icons grouped by `IconType`.
///
/// Each icon is fetched with `icons.fetchSvg(...)` and rendered into a small
/// `WKWebView` cell. Every available icon is shown so developers can browse the
/// full set; the `UICollectionView` recycles cells to stay smooth.
final class IconGalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let icons: Icons

    private struct IconSection {
        let title: String
        let icons: [MappedinIcon]
    }

    private var sections: [IconSection] = []
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

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 80, height: 72)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 16, right: 12)
        layout.headerReferenceSize = CGSize(width: view.bounds.width, height: 32)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(IconWebCell.self, forCellWithReuseIdentifier: IconWebCell.reuseId)
        collectionView.register(
            IconSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: IconSectionHeader.reuseId
        )
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Load sequentially so sections always appear in IconType order,
        // regardless of how quickly each getByType call resolves.
        loadTypesInOrder(IconType.allCases)
    }

    private func loadTypesInOrder(_ types: [IconType]) {
        guard let type = types.first else { return }
        let rest = Array(types.dropFirst())
        icons.getByType(type: type) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if case .success(let icons) = result {
                    self.sections.append(
                        IconSection(title: "\(type.rawValue) (\(icons.count))", icons: icons)
                    )
                    self.collectionView.reloadData()
                }
                self.loadTypesInOrder(rest)
            }
        }
    }

    // MARK: - UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int { sections.count }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        sections[section].icons.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IconWebCell.reuseId, for: indexPath) as! IconWebCell
        let icon = sections[indexPath.section].icons[indexPath.item]
        cell.label.text = icon.name
        cell.representedName = icon.name
        icons.fetchSvg(name: icon.name) { result in
            guard case .success(let svg) = result else { return }
            DispatchQueue.main.async {
                if cell.representedName == icon.name {
                    cell.webView.renderIconSvg(svg, color: "#333333")
                }
            }
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: IconSectionHeader.reuseId,
            for: indexPath
        ) as! IconSectionHeader
        header.label.text = sections[indexPath.section].title
        return header
    }
}
