import UIKit
import Mappedin

/// A single screen in the Reusable MapView demo. Each instance reparents the
/// shared map's WebView into its own container and asks the host to focus the
/// camera on this screen's space. The map itself is never created or destroyed
/// here; it is owned by `ReusableMapViewDemoViewController` and shared across
/// screens.
final class ReusableMapScreenViewController: UIViewController {
    private weak var host: ReusableMapViewDemoViewController?
    private let screenIndex: Int
    private let screenTitle: String

    private let mapContainer = UIView()
    private let descriptionLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    init(host: ReusableMapViewDemoViewController, screenIndex: Int, screenTitle: String) {
        self.host = host
        self.screenIndex = screenIndex
        self.screenTitle = screenTitle
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = screenTitle
        view.backgroundColor = .systemBackground

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .secondaryLabel
        view.addSubview(descriptionLabel)

        mapContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapContainer)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        mapContainer.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            descriptionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            descriptionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),

            mapContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapContainer.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 12),
            mapContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: mapContainer.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: mapContainer.centerYAnchor),
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Move the single shared map into this screen and focus it.
        host?.attachMap(to: mapContainer)
        updateForState()
        host?.focus(forScreen: screenIndex)
    }

    /// Called by the host whenever the shared map's load state changes.
    func mapStateDidChange() {
        updateForState()
        host?.focus(forScreen: screenIndex)
    }

    private func updateForState() {
        if host?.loadFailed == true {
            loadingIndicator.stopAnimating()
            descriptionLabel.text = "The shared map failed to load."
        } else if host?.isMapReady == true {
            loadingIndicator.stopAnimating()
            let target = host?.focusTargetName(for: screenIndex) ?? "this venue"
            descriptionLabel.text = "Reusing the shared map, focused on: \(target)"
        } else {
            loadingIndicator.startAnimating()
            descriptionLabel.text = "Loading the shared map once. It will be reused on every screen."
        }
    }
}
