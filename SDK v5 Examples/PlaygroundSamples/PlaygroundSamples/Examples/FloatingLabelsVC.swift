//
//  FloatingLabelsVC.swift
//  PlaygroundSamples
//
import Mappedin
import UIKit

class FloatingLabelsVC: UIViewController, MPIMapViewDelegate {

    let mainStackView = UIStackView()
    var mapView: MPIMapView?
    let floatingLabelStyleButton = UIButton(type: .system)
    var loadingIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMainStackView()
        setupMapView()
        setupButton()
    }
    
    func setupMainStackView() {
        view.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        mainStackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        mainStackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true
        mainStackView.axis = .vertical
        mainStackView.distribution = .fill
        mainStackView.alignment = .fill
    }
    
    func setupMapView() {
        mapView = MPIMapView(frame: view.frame)
        mapView?.delegate = self
        if let mapView = mapView {
            mainStackView.addArrangedSubview(mapView)
            
            // See Trial API key Terms and Conditions
            // https://developer.mappedin.com/api-keys/
            mapView.loadVenue(options:
                MPIOptions.Init(
                    clientId: "5eab30aa91b055001a68e996",
                    clientSecret: "RJyRXKcryCMy4erZqqCbuB1NbR66QTGNXVE0x3Pg6oCIlUR1",
                    venue: "mappedin-demo-mall"
                ),
                  showVenueOptions: MPIOptions.ShowVenue(labelAllLocationsOnInit: true, multiBufferRendering: true, xRayPath: true, outdoorView: MPIOptions.OutdoorView(enabled: true), shadingAndOutlines: true))
        }
        
        loadingIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        if let loadingIndicator = loadingIndicator {
            loadingIndicator.center = view.center
            loadingIndicator.startAnimating()
            view.addSubview(loadingIndicator)
        }
    }
    
    func setupButton() {
        let floatingLabelStackView = UIStackView()
        floatingLabelStackView.axis = .horizontal
        floatingLabelStackView.alignment = .center
        floatingLabelStackView.spacing = 8
        floatingLabelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        floatingLabelStackView.isLayoutMarginsRelativeArrangement = true

        let styleLabel = UILabel()
        styleLabel.text = "Style: "
        styleLabel.translatesAutoresizingMaskIntoConstraints = false
        floatingLabelStackView.addArrangedSubview(styleLabel)

        floatingLabelStyleButton.setTitle("Default", for: .normal)
        floatingLabelStyleButton.menu = populateStyleMenu()
        floatingLabelStyleButton.showsMenuAsPrimaryAction = true
        floatingLabelStyleButton.translatesAutoresizingMaskIntoConstraints = false
        floatingLabelStackView.addArrangedSubview(floatingLabelStyleButton)
        floatingLabelStackView.addArrangedSubview(UIView())
        mainStackView.addArrangedSubview(floatingLabelStackView)
    }
    
    // Populates the Style Selection menu.
    func populateStyleMenu() -> UIMenu {
        var menuActions: [UIAction] = []
        
        let darkOnLightStyle = UIAction(title: "Dark on Light") { (action) in
            // Remove and re-add all Floating Labels using the Dark on Light style.
            let styleOptions = MPIOptions.FloatingLabelAllLocations(appearance: MPIOptions.FloatingLabelAppearance.darkOnLight)
            
            self.mapView?.floatingLabelManager.removeAll()
            self.mapView?.floatingLabelManager.labelAllLocations(options: styleOptions)
            
            self.floatingLabelStyleButton.setTitle("Dark on Light", for: .normal)
        }
        menuActions.append(darkOnLightStyle)
        
        let lightOnDarkStyle = UIAction(title: "Light on Dark") { (action) in
            // Remove and re-add all Floating Labels using the Light on Dark style.
            let styleOptions = MPIOptions.FloatingLabelAllLocations(appearance: MPIOptions.FloatingLabelAppearance.lightOnDark)
            
            self.mapView?.floatingLabelManager.removeAll()
            self.mapView?.floatingLabelManager.labelAllLocations(options: styleOptions)
            
            self.floatingLabelStyleButton.setTitle("Light on Dark", for: .normal)
        }
        menuActions.append(lightOnDarkStyle)
        
        let svgIconsStyle = UIAction(title: "SVG Icons") { (action) in
            // Remove and re-add all Floating Labels using with an SVG icon.
            // Note that SVG must be instantiated using triple " to avoid characters being double escaped.
            let svgIcon: String = """
                <svg width="92" height="92" viewBox="-17 0 92 92" fill="none" xmlns="http://www.w3.org/2000/svg">
                <g clip-path="url(#clip0)">
                <path d="M53.99 28.0973H44.3274C41.8873 28.0973 40.7161 29.1789 40.7161 31.5387V61.1837L21.0491 30.7029C19.6827 28.5889 18.8042 28.1956 16.0714 28.0973H6.5551C4.01742 28.0973 2.84619 29.1789 2.84619 31.5387V87.8299C2.84619 90.1897 4.01742 91.2712 6.5551 91.2712H16.2178C18.7554 91.2712 19.9267 90.1897 19.9267 87.8299V58.3323L39.6912 88.6656C41.1553 90.878 41.9361 91.2712 44.669 91.2712H54.0388C56.5765 91.2712 57.7477 90.1897 57.7477 87.8299V31.5387C57.6501 29.1789 56.4789 28.0973 53.99 28.0973Z" fill="white"/>
                <path d="M11.3863 21.7061C17.2618 21.7061 22.025 16.9078 22.025 10.9887C22.025 5.06961 17.2618 0.27124 11.3863 0.27124C5.51067 0.27124 0.747559 5.06961 0.747559 10.9887C0.747559 16.9078 5.51067 21.7061 11.3863 21.7061Z" fill="white"/>
                </g>
                <defs>
                <clipPath id="clip0">
                <rect width="57" height="91" fill="white" transform="translate(0.747559 0.27124)"/>
                </clipPath>
                </defs>
                </svg>
            """
            
            let foreGroundColor = MPIOptions.FloatingLabelAppearance.Color(active: "#BF4320", inactive: "#7E2D16")
            let backgroundColor = MPIOptions.FloatingLabelAppearance.Color(active: "#FFFFFF", inactive: "#FAFAFA")
            
            let markerAppearance = MPIOptions.FloatingLabelAppearance.Marker(
                foregroundColor: foreGroundColor,
                backgroundColor: backgroundColor,
                icon: svgIcon
            )
            let markerTheme = MPIOptions.FloatingLabelAppearance(marker: markerAppearance)
            let styleOptions = MPIOptions.FloatingLabelAllLocations(appearance: markerTheme)

            self.mapView?.floatingLabelManager.removeAll()
            self.mapView?.floatingLabelManager.labelAllLocations(options: styleOptions)
            
            self.floatingLabelStyleButton.setTitle("SVG Icons", for: .normal)
        }
        menuActions.append(svgIconsStyle)
        
        let customColorStyle = UIAction(title: "Custom Colours") { (action) in
            // Remove and re-add all Floating Labels using custom colours.
            let floatingLabelAppearance = MPIOptions.FloatingLabelAppearance(text: MPIOptions.FloatingLabelAppearance.Text(numLines: 2, foregroundColor: "#DAA520", backgroundColor: "#000000"))
            let styleOptions = MPIOptions.FloatingLabelAllLocations(appearance: floatingLabelAppearance)
            self.mapView?.floatingLabelManager.removeAll()
            self.mapView?.floatingLabelManager.labelAllLocations(options: styleOptions)
            
            self.floatingLabelStyleButton.setTitle("Custom Colours", for: .normal)
        }
        menuActions.append(customColorStyle)
        
        let defaultStyle = UIAction(title: "Default") { (action) in
            // Remove and re-add all Floating Labels using the default style.
            self.mapView?.floatingLabelManager.removeAll()
            self.mapView?.floatingLabelManager.labelAllLocations()
            self.floatingLabelStyleButton.setTitle("Default", for: .normal)
        }
        menuActions.append(defaultStyle)
        
        return UIMenu(title: "Floating Label Style", options: .displayInline, children: menuActions);
    }
    
    func onDataLoaded(data: Mappedin.MPIData) {}
    
    func onFirstMapLoaded() {
        loadingIndicator?.stopAnimating()
        
        // Zoom in when the map loads to better show the Floating Labels.
        mapView?.cameraManager.set(cameraTransform: MPIOptions.CameraConfiguration(zoom: 800.0,  position: mapView?.currentMap?.createCoordinate(latitude: 43.86181934825464, longitude: -78.94672121994297)))
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onPolygonClicked(polygon: Mappedin.MPIPolygon) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
}
