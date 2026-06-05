import UIKit
import Mappedin

/// Mirrors the web "Prefetch Demo" example: exercises the prefetch APIs, cache
/// checks (`isCached`), cached-vs-uncached fetch timing, and `clearCache`.
final class PrefetchDemoViewController: UIViewController, UICollectionViewDataSource {
    private let icons: Icons
    private let names = ["information", "elevator-up", "book"]
    private let maxResults = 20

    private var results: [MappedinIcon] = []
    private var collectionView: UICollectionView!
    private let statusLabel = UILabel()

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

        let buttonStack = UIStackView()
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .vertical
        buttonStack.spacing = 6
        buttonStack.addArrangedSubview(makeButton("Prefetch by names", #selector(prefetchNames)))
        buttonStack.addArrangedSubview(makeButton("Prefetch by type (Small)", #selector(prefetchType)))
        buttonStack.addArrangedSubview(makeButton("Prefetch by subtype (Amenities)", #selector(prefetchSubtype)))
        buttonStack.addArrangedSubview(makeButton("Prefetch by category (Food and drink)", #selector(prefetchCategory)))
        buttonStack.addArrangedSubview(makeButton("Cached vs uncached fetch", #selector(compareFetch)))
        buttonStack.addArrangedSubview(makeButton("Clear cache", #selector(clearCacheTapped)))

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Tap a button to begin."
        statusLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 70, height: 72)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 8, left: 12, bottom: 16, right: 12)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.register(IconWebCell.self, forCellWithReuseIdentifier: IconWebCell.reuseId)

        view.addSubview(buttonStack)
        view.addSubview(statusLabel)
        view.addSubview(collectionView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            buttonStack.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            buttonStack.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),

            statusLabel.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            statusLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),

            collectionView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func makeButton(_ title: String, _ action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func setStatus(_ text: String) {
        DispatchQueue.main.async { self.statusLabel.text = text }
    }

    private func show(_ icons: [MappedinIcon]) {
        DispatchQueue.main.async {
            self.results = Array(icons.prefix(self.maxResults))
            self.collectionView.reloadData()
        }
    }

    // MARK: - Actions

    @objc private func prefetchNames() {
        setStatus("Prefetching \(names.joined(separator: ", ")) ...")
        icons.prefetch(names: names) { [weak self] _ in
            guard let self = self else { return }
            self.icons.isCached(name: self.names[0]) { cachedResult in
                let cached = (try? cachedResult.get()) ?? false
                self.setStatus("Prefetched \(self.names.count) icons. isCached(\"\(self.names[0])\") = \(cached)")
            }
            self.collectByNames(self.names)
        }
    }

    private func collectByNames(_ names: [String]) {
        var collected: [MappedinIcon] = []
        let group = DispatchGroup()
        for name in names {
            group.enter()
            icons.getByName(name: name) { result in
                if case .success(let icon) = result { collected.append(icon) }
                group.leave()
            }
        }
        group.notify(queue: .main) { self.show(collected) }
    }

    @objc private func prefetchType() {
        setStatus("Prefetching all Small icons ...")
        icons.prefetchByType(type: .small) { [weak self] _ in
            self?.icons.getByType(type: .small) { result in
                let icons = (try? result.get()) ?? []
                self?.setStatus("Prefetched \(icons.count) Small icons (showing first \(self?.maxResults ?? 0)).")
                self?.show(icons)
            }
        }
    }

    @objc private func prefetchSubtype() {
        setStatus("Prefetching Amenities icons ...")
        icons.prefetchBySubtype(subtype: .amenities) { [weak self] _ in
            self?.icons.getBySubtype(subtype: .amenities) { result in
                let icons = (try? result.get()) ?? []
                self?.setStatus("Prefetched \(icons.count) Amenities icons (showing first \(self?.maxResults ?? 0)).")
                self?.show(icons)
            }
        }
    }

    @objc private func prefetchCategory() {
        setStatus("Prefetching Food and drink icons ...")
        icons.prefetchByCategory(category: .foodAndDrink) { [weak self] _ in
            self?.icons.getByCategory(category: .foodAndDrink) { result in
                let icons = (try? result.get()) ?? []
                self?.setStatus("Prefetched \(icons.count) Food and drink icons (showing first \(self?.maxResults ?? 0)).")
                self?.show(icons)
            }
        }
    }

    @objc private func compareFetch() {
        let name = names[0]
        setStatus("Clearing cache then timing fetches for \"\(name)\" ...")
        icons.clearCache { [weak self] _ in
            guard let self = self else { return }
            let uncachedStart = Date()
            self.icons.fetchSvg(name: name) { _ in
                let uncachedMs = Date().timeIntervalSince(uncachedStart) * 1000
                let cachedStart = Date()
                self.icons.fetchSvg(name: name) { _ in
                    let cachedMs = Date().timeIntervalSince(cachedStart) * 1000
                    self.setStatus(String(format: "Uncached: %.1f ms, cached: %.1f ms", uncachedMs, cachedMs))
                    self.icons.getByName(name: name) { result in
                        if case .success(let icon) = result { self.show([icon]) }
                    }
                }
            }
        }
    }

    @objc private func clearCacheTapped() {
        icons.clearCache { [weak self] _ in
            self?.setStatus("Cache cleared.")
            self?.show([])
        }
    }

    // MARK: - UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        results.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IconWebCell.reuseId, for: indexPath) as! IconWebCell
        let icon = results[indexPath.item]
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
}
