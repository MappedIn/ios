import UIKit
import Mappedin
import Foundation

/// Demonstrates the Events extension for loading and displaying CMS events.
///
/// This demo loads events from the mappedin-demo-mall venue and displays
/// them as a scrollable list of cards with images, names, dates, and descriptions.
final class EventsDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let imageCache = NSCache<NSString, UIImage>()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Events"
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)

        setupUI()
        loadMapData()
    }

    // MARK: - UI Setup

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 16
        contentStackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentStackView.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(contentStackView)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        let hiddenContainer = mapView.view
        hiddenContainer.translatesAutoresizingMaskIntoConstraints = false
        hiddenContainer.isHidden = true
        view.addSubview(hiddenContainer)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            hiddenContainer.widthAnchor.constraint(equalToConstant: 1),
            hiddenContainer.heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    // MARK: - Data Loading

	// Demo API key - see https://developer.mappedin.com/docs/demo-keys-and-maps
	// Using the outdoor/indoor map for Dynamic Focus demoT
    private func loadMapData() {
        let options = GetMapDataWithCredentialsOptions(
            key: "5eab30aa91b055001a68e996",
            secret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
            mapId: "mappedin-demo-mall"
        )

        mapView.getMapData(options: options) { [weak self] result in
            guard let self = self else { return }

            if case .success = result {
                print("getMapData success")
                self.loadEvents()
            } else if case .failure(let error) = result {
                print("getMapData error: \(error)")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.showError("Failed to load map data")
                }
            }
        }
    }

    private func loadEvents() {
        mapView.mapData.eventsManager.load { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.mapView.mapData.eventsManager.getEvents { [weak self] eventsResult in
                    guard let self = self else { return }
                    switch eventsResult {
                    case .success(let events):
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                            self.buildEventsUI(events: events)
                        }
                    case .failure(let error):
                        print("getEvents error: \(error)")
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                            self.showError("Failed to load events")
                        }
                    }
                }
            case .failure(let error):
                print("load events error: \(error)")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.showError("Failed to load events")
                }
            }
        }
    }

    // MARK: - UI Building

    private func buildEventsUI(events: [EventMetaData]) {
        if events.isEmpty {
            showError("No events found for this venue.")
            return
        }

        let headerLabel = UILabel()
        headerLabel.text = "\(events.count) Event\(events.count != 1 ? "s" : "")"
        headerLabel.font = .systemFont(ofSize: 22, weight: .bold)
        headerLabel.textColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0)
        contentStackView.addArrangedSubview(headerLabel)

        for event in events {
            let card = createEventCard(event: event)
            contentStackView.addArrangedSubview(card)
        }
    }

    private func createEventCard(event: EventMetaData) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 8
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 0.1
        cardView.clipsToBounds = false

        let clipContainer = UIView()
        clipContainer.layer.cornerRadius = 8
        clipContainer.clipsToBounds = true
        clipContainer.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(clipContainer)

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        clipContainer.addSubview(contentStack)

        NSLayoutConstraint.activate([
            clipContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            clipContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            clipContainer.topAnchor.constraint(equalTo: cardView.topAnchor),
            clipContainer.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: clipContainer.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: clipContainer.trailingAnchor),
            contentStack.topAnchor.constraint(equalTo: clipContainer.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: clipContainer.bottomAnchor)
        ])

        if let imageUrl = event.image?.url, !imageUrl.isEmpty {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
            loadImage(from: imageUrl, into: imageView)
            contentStack.addArrangedSubview(imageView)
        }

        let infoContainer = UIStackView()
        infoContainer.axis = .vertical
        infoContainer.spacing = 4
        infoContainer.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        infoContainer.isLayoutMarginsRelativeArrangement = true

        let nameLabel = UILabel()
        nameLabel.text = event.name
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0)
        infoContainer.addArrangedSubview(nameLabel)

        let dateText = formatDateRange(start: event.startDate, end: event.endDate)
        if !dateText.isEmpty {
            let dateLabel = UILabel()
            dateLabel.text = dateText
            dateLabel.font = .systemFont(ofSize: 13)
            dateLabel.textColor = UIColor(red: 0.53, green: 0.53, blue: 0.53, alpha: 1.0)
            infoContainer.addArrangedSubview(dateLabel)

            infoContainer.setCustomSpacing(8, after: dateLabel)
        }

        if let description = event.description, !description.isEmpty {
            let descLabel = UILabel()
            descLabel.text = description
            descLabel.font = .systemFont(ofSize: 14)
            descLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
            descLabel.numberOfLines = 4
            infoContainer.addArrangedSubview(descLabel)
        }

        contentStack.addArrangedSubview(infoContainer)

        return cardView
    }

    /// Formats an ISO 8601 date range into a human-readable string.
    private func formatDateRange(start: String, end: String) -> String {
        let startDate = start.components(separatedBy: "T").first.flatMap { $0.isEmpty ? nil : $0 }
        let endDate = end.components(separatedBy: "T").first.flatMap { $0.isEmpty ? nil : $0 }
        if startDate == nil && endDate == nil { return "" }
        if let s = startDate, let e = endDate {
            return s == e ? s : "\(s) — \(e)"
        }
        return startDate ?? endDate ?? ""
    }

    // MARK: - Image Loading

    private func loadImage(from urlString: String, into imageView: UIImageView) {
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            imageView.image = cachedImage
            return
        }

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self, weak imageView] data, _, error in
            guard let self = self,
                  let imageView = imageView,
                  let data = data,
                  error == nil else {
                return
            }

            let scaledImage = self.downsampleImage(data: data, maxDimension: 1024)

            guard let image = scaledImage else { return }

            self.imageCache.setObject(image, forKey: urlString as NSString)

            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }

    private func downsampleImage(data: Data, maxDimension: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return UIImage(data: data)
        }

        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return UIImage(data: data)
        }

        let maxSourceDimension = max(width, height)
        if maxSourceDimension <= maxDimension {
            return UIImage(data: data)
        }

        let scale = maxDimension / maxSourceDimension
        let targetWidth = width * scale
        let targetHeight = height * scale

        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(targetWidth, targetHeight)
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return UIImage(data: data)
        }

        return UIImage(cgImage: downsampledImage)
    }

    // MARK: - Error Display

    private func showError(_ message: String) {
        contentStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let errorLabel = UILabel()
        errorLabel.text = message
        errorLabel.font = .systemFont(ofSize: 16)
        errorLabel.textColor = .systemRed
        errorLabel.textAlignment = .center
        contentStackView.addArrangedSubview(errorLabel)
    }
}
