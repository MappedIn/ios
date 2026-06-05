import UIKit
import Mappedin

/// Hosts the Icons examples (Gallery, Color Picker, Prefetch, Enterprise
/// Category Icons) under a `UISegmentedControl`, mirroring the web SDK examples.
///
/// A single hidden `MapView` hosts the Mappedin bridge for the first three
/// (map-independent) examples, which share this MapView's `icons` API. The
/// Enterprise Category Icons example renders a real map and owns its own
/// `MapView`.
final class IconsDemoViewController: UIViewController {
    /// Shared bridge host. The Icons extension does not require a loaded map.
    private let mapView = MapView()

    private lazy var segmentedControl = UISegmentedControl(items: ["Gallery", "Color Picker", "Prefetch", "Enterprise"])
    private let containerView = UIView()
    private var exampleControllers: [UIViewController] = []
    private var currentChild: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Icons"
        view.backgroundColor = .systemBackground

        exampleControllers = [
            IconGalleryViewController(icons: mapView.icons),
            ColorPickerViewController(icons: mapView.icons),
            PrefetchDemoViewController(icons: mapView.icons),
            EnterpriseCategoryIconsViewController(),
        ]

        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        containerView.translatesAutoresizingMaskIntoConstraints = false

        // Hidden bridge WebView (1pt) so the bridge loads and the Icons
        // extension can register, without showing a map.
        let bridgeView = mapView.view
        bridgeView.translatesAutoresizingMaskIntoConstraints = false
        bridgeView.isHidden = true

        view.addSubview(segmentedControl)
        view.addSubview(containerView)
        view.addSubview(bridgeView)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            segmentedControl.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            segmentedControl.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),

            containerView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bridgeView.widthAnchor.constraint(equalToConstant: 1),
            bridgeView.heightAnchor.constraint(equalToConstant: 1),
            bridgeView.topAnchor.constraint(equalTo: view.topAnchor),
            bridgeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        ])

        showChild(at: 0)
    }

    @objc private func segmentChanged() {
        showChild(at: segmentedControl.selectedSegmentIndex)
    }

    private func showChild(at index: Int) {
        guard index >= 0, index < exampleControllers.count else { return }

        currentChild?.willMove(toParent: nil)
        currentChild?.view.removeFromSuperview()
        currentChild?.removeFromParent()

        let child = exampleControllers[index]
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(child.view)
        NSLayoutConstraint.activate([
            child.view.topAnchor.constraint(equalTo: containerView.topAnchor),
            child.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            child.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            child.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
        child.didMove(toParent: self)
        currentChild = child
    }
}
