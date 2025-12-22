import UIKit
import Mappedin
import Foundation

/// Demo view controller showing a category directory with location profiles.
///
/// This demo displays all location categories organized in a hierarchical structure,
/// showing parent → child category relationships and their associated locations
/// with images, names, and descriptions.
final class LocationsDemoViewController: UIViewController {
    private let mapView = MapView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    private let imageCache = NSCache<NSString, UIImage>()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Locations"
        view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.96, alpha: 1.0)

        setupUI()
        loadMapData()
    }

    private func setupUI() {
        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Content stack view
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 24
        contentStackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        contentStackView.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(contentStackView)

        // Loading indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)

        // Hidden MapView container (needed to load data)
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

    private func loadMapData() {
        // See Trial API key Terms and Conditions
        // https://developer.mappedin.com/docs/demo-keys-and-maps
        let options = GetMapDataWithCredentialsOptions(
            key: "mik_yeBk0Vf0nNJtpesfu560e07e5",
            secret: "mis_2g9ST8ZcSFb5R9fPnsvYhrX3RyRwPtDGbMGweCYKEq385431022",
            mapId: "660c0c6e7c0c4fe5b4cc484c"
        )

        mapView.getMapData(options: options) { [weak self] result in
            guard let self = self else { return }

            if case .success = result {
                print("getMapData success")
                self.loadCategoryDirectory()
            } else if case .failure(let error) = result {
                print("getMapData error: \(error)")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.showError("Failed to load map data")
                }
            }
        }
    }

    /// Loads all location categories and profiles, then builds the directory UI.
    private func loadCategoryDirectory() {
        // First, get all location categories
        mapView.mapData.getByType(.locationCategory) { [weak self] (categoriesResult: Result<[LocationCategory], Error>) in
            guard let self = self else { return }

            if case .success(let categories) = categoriesResult {
                // Then get all location profiles
                self.mapView.mapData.getByType(.locationProfile) { [weak self] (profilesResult: Result<[LocationProfile], Error>) in
                    guard let self = self else { return }

                    if case .success(let profiles) = profilesResult {
                        // Build lookup maps
                        let profileMap = Dictionary(uniqueKeysWithValues: profiles.map { ($0.id, $0) })
                        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })

                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                            self.buildCategoryUI(
                                categories: categories,
                                categoryMap: categoryMap,
                                profileMap: profileMap
                            )
                        }
                    } else if case .failure(let error) = profilesResult {
                        print("Failed to get profiles: \(error)")
                        DispatchQueue.main.async {
                            self.loadingIndicator.stopAnimating()
                            self.showError("Failed to load location profiles")
                        }
                    }
                }
            } else if case .failure(let error) = categoriesResult {
                print("Failed to get categories: \(error)")
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.showError("Failed to load categories")
                }
            }
        }
    }

    /// Builds the category directory UI from the loaded data.
    private func buildCategoryUI(
        categories: [LocationCategory],
        categoryMap: [String: LocationCategory],
        profileMap: [String: LocationProfile]
    ) {
        // Find parent categories (categories with children)
        let parentCategories = categories.filter { !$0.children.isEmpty }

        if parentCategories.isEmpty {
            showError("No categories with children found")
            return
        }

        for parentCategory in parentCategories {
            // Loop through each child category
            for childId in parentCategory.children {
                guard let childCategory = categoryMap[childId] else { continue }

                // Create category section
                let sectionView = createCategorySection(
                    parentCategory: parentCategory,
                    childCategory: childCategory,
                    profileMap: profileMap
                )
                contentStackView.addArrangedSubview(sectionView)
            }
        }
    }

    /// Creates a section view for a category with its locations.
    private func createCategorySection(
        parentCategory: LocationCategory,
        childCategory: LocationCategory,
        profileMap: [String: LocationProfile]
    ) -> UIView {
        let sectionView = UIStackView()
        sectionView.axis = .vertical
        sectionView.spacing = 16

        // Create title container with icons
        let titleContainer = UIStackView()
        titleContainer.axis = .horizontal
        titleContainer.alignment = .center
        titleContainer.spacing = 8

        // Add parent category icon if exists
        if !parentCategory.icon.isEmpty {
            let parentIcon = createIconImageView()
            loadImage(from: parentCategory.icon, into: parentIcon)
            titleContainer.addArrangedSubview(parentIcon)
        }

        // Add parent category name
        let parentNameLabel = UILabel()
        parentNameLabel.text = parentCategory.name
        parentNameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        parentNameLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        titleContainer.addArrangedSubview(parentNameLabel)

        // Add separator arrow
        let separatorLabel = UILabel()
        separatorLabel.text = "→"
        separatorLabel.font = .systemFont(ofSize: 16)
        separatorLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        titleContainer.addArrangedSubview(separatorLabel)

        // Add child category icon if exists
        if !childCategory.icon.isEmpty {
            let childIcon = createIconImageView()
            loadImage(from: childCategory.icon, into: childIcon)
            titleContainer.addArrangedSubview(childIcon)
        }

        // Add child category name
        let childNameLabel = UILabel()
        childNameLabel.text = childCategory.name
        childNameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        childNameLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        titleContainer.addArrangedSubview(childNameLabel)

        // Add spacer
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleContainer.addArrangedSubview(spacer)

        sectionView.addArrangedSubview(titleContainer)

        // Add divider
        let divider = UIView()
        divider.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 2).isActive = true
        sectionView.addArrangedSubview(divider)

        // Add location cards
        let locationsStack = UIStackView()
        locationsStack.axis = .vertical
        locationsStack.spacing = 16

        for profileId in childCategory.locationProfiles {
            if let profile = profileMap[profileId], !profile.name.isEmpty {
                let card = createLocationCard(profile: profile)
                locationsStack.addArrangedSubview(card)
            }
        }

        sectionView.addArrangedSubview(locationsStack)

        return sectionView
    }

    /// Creates an icon image view with fixed size.
    private func createIconImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
        return imageView
    }

    /// Creates a card view for a location profile.
    private func createLocationCard(profile: LocationProfile) -> UIView {
        let cardView = UIView()
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 8
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        cardView.layer.shadowOpacity = 0.1
        cardView.clipsToBounds = false

        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        // Create a container for clipping corners
        let clipContainer = UIView()
        clipContainer.layer.cornerRadius = 8
        clipContainer.clipsToBounds = true
        clipContainer.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(clipContainer)

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

        // Add image if available
        if let imageUrl = profile.images.first?.url, !imageUrl.isEmpty {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.backgroundColor = UIColor(red: 0.88, green: 0.88, blue: 0.88, alpha: 1.0)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.heightAnchor.constraint(equalToConstant: 200).isActive = true
            loadImage(from: imageUrl, into: imageView)
            contentStack.addArrangedSubview(imageView)
        }

        // Location info container
        let infoContainer = UIStackView()
        infoContainer.axis = .vertical
        infoContainer.spacing = 8
        infoContainer.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        infoContainer.isLayoutMarginsRelativeArrangement = true

        // Location name
        let nameLabel = UILabel()
        nameLabel.text = profile.name
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.0)
        infoContainer.addArrangedSubview(nameLabel)

        // Location description
        if let description = profile.description, !description.isEmpty {
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

    /// Loads an image from a URL into an image view, scaling it down for better performance.
    private func loadImage(from urlString: String, into imageView: UIImageView) {
        // Check cache first
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

            // Scale down the image for better performance
            let scaledImage = self.downsampleImage(data: data, maxDimension: 1024)

            guard let image = scaledImage else { return }

            // Cache the scaled image
            self.imageCache.setObject(image, forKey: urlString as NSString)

            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }

    /// Downsamples an image to a maximum dimension for better memory usage and scrolling performance.
    private func downsampleImage(data: Data, maxDimension: CGFloat) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return UIImage(data: data)
        }

        // Get image dimensions
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return UIImage(data: data)
        }

        // Calculate the scale factor
        let maxSourceDimension = max(width, height)
        if maxSourceDimension <= maxDimension {
            // Image is already small enough
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

    /// Shows an error message.
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
