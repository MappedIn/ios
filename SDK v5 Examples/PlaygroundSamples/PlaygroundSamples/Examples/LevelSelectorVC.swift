//
//  LevelSelectorVC.swift
//  PlaygroundSamples
//

import Mappedin
import UIKit

class LevelSelectorVC: UIViewController, MPIMapViewDelegate {

    let mainStackView = UIStackView()
    var mapView: MPIMapView?
    let buildingButton = UIButton(type: .system)
    let levelButton = UIButton(type: .system)
    var loadingIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupMainStackView()
        setupMapView()
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
                    venue: "mappedin-demo-campus"
                ),
                  showVenueOptions: MPIOptions.ShowVenue(multiBufferRendering: true, outdoorView: MPIOptions.OutdoorView(enabled: true), shadingAndOutlines: true))
        }
        
        loadingIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        if let loadingIndicator = loadingIndicator {
            loadingIndicator.center = view.center
            loadingIndicator.startAnimating()
            view.addSubview(loadingIndicator)
        }
    }
    
    func setupButtons() {
        let buildingStackView = UIStackView()
        buildingStackView.axis = .horizontal
        buildingStackView.alignment = .center
        buildingStackView.spacing = 8
        buildingStackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        buildingStackView.isLayoutMarginsRelativeArrangement = true

        let buildingLabel = UILabel()
        buildingLabel.text = "Building: "
        buildingLabel.translatesAutoresizingMaskIntoConstraints = false
        buildingStackView.addArrangedSubview(buildingLabel)

        // Set the button title to the name of the first map group (building).
        buildingButton.setTitle(mapView?.venueData?.mapGroups.first?.name, for: .normal)
        buildingButton.menu = populateBuildingMenu()
        buildingButton.showsMenuAsPrimaryAction = true
        buildingButton.translatesAutoresizingMaskIntoConstraints = false
        buildingStackView.addArrangedSubview(buildingButton)
        buildingStackView.addArrangedSubview(UIView())
        mainStackView.addArrangedSubview(buildingStackView)

        let levelStackView = UIStackView()
        levelStackView.axis = .horizontal
        levelStackView.alignment = .center
        levelStackView.spacing = 8
        levelStackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        levelStackView.isLayoutMarginsRelativeArrangement = true

        let levelLabel = UILabel()
        levelLabel.text = "Level: "
        levelStackView.addArrangedSubview(levelLabel)

        // Set the button title to the name of the first map (level) in the first map group (building).
        levelButton.setTitle(mapView?.venueData?.mapGroups.first?.maps.first?.name, for: .normal)
        // Populate all maps (levels) in the first map group.
        levelButton.menu = populateLevelMenu(selectedBuilding: mapView?.venueData?.mapGroups.first?.name ?? "Default")
        levelButton.showsMenuAsPrimaryAction = true
        levelButton.translatesAutoresizingMaskIntoConstraints = false
        levelStackView.addArrangedSubview(levelButton)
        levelStackView.addArrangedSubview(UIView())
        mainStackView.addArrangedSubview(levelStackView)
    }
    
    // Populates the Building Selection menu with all Map Groups.
    func populateBuildingMenu() -> UIMenu {
        var menuActions: [UIAction] = []
        
        // Loop through all map groups and add their name to the building selection menu.
        mapView?.venueData?.mapGroups.forEach{mapGroup in
            let buildingAction = UIAction(title: mapGroup.name ?? "Unknown") { (action) in
                // When a building is selected from the menu, change the button title and trigger loading of all
                // map names (levels) in the map group into the level selection menu.
                print(mapGroup.name ?? "Unknown" + " was clicked")
                self.buildingButton.setTitle(mapGroup.name, for: .normal)
                self.levelButton.menu = self.populateLevelMenu(selectedBuilding: mapGroup.name ?? "Default")
                
                //Ensure there is a map in the group to display.
                if let theMap = mapGroup.maps.first {
                    self.mapView?.setMap(map: theMap)
                    self.levelButton.setTitle(theMap.name, for: .normal)
                }
           }
            menuActions.append(buildingAction)
        }
        
        return UIMenu(title: "Choose a Building", options: .displayInline, children: menuActions);
    }
  
    // Populates the Level Selection menu with all Map names in the selected building (Map Group).
    func populateLevelMenu (selectedBuilding:String) -> UIMenu {
        var menuActions: [UIAction] = []
        
        //  Loop through all maps and add their name to the level selection menu.
        mapView?.venueData?.mapGroups.first(where: {$0.name == selectedBuilding})?.maps.forEach{map in
            let levelAction = UIAction(title: map.name) { (action) in
                // When a new level is selected, change the button title and display the chosen map.
                print(map.name + " was clicked")
                self.levelButton.setTitle(map.name, for: .normal)
                self.mapView?.setMap(map: map)
            }
            menuActions.append(levelAction)
        }
        return UIMenu(title: "Choose a Level", options: .displayInline, children: menuActions);
    }

    // Populate the buttons once the venue data has loaded.
    func onDataLoaded(data: Mappedin.MPIData) {
        setupButtons()
    }
    
    func onFirstMapLoaded() {
        loadingIndicator?.stopAnimating()
    }
    
    func onMapChanged(map: Mappedin.MPIMap) {}
    
    func onNothingClicked() {}
    
    func onBlueDotPositionUpdate(update: Mappedin.MPIBlueDotPositionUpdate) {}
    
    func onBlueDotStateChange(stateChange: Mappedin.MPIBlueDotStateChange) {}
    
    func onStateChanged(state: Mappedin.MPIState) {}
    
    func onCameraChanged(cameraChange: Mappedin.MPICameraTransform) {}
    
    func onPolygonClicked(polygon: MPIPolygon) {}
}
