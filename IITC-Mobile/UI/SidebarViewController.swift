//
//  SidebarViewController.swift
//  IITC-Mobile
//
//  Created by Hubert Zhang on 2022/2/21.
//  Copyright © 2022 IITC. All rights reserved.
//

import UIKit
import Combine

import BaseFramework

@available(iOS 14.0, *)
class SidebarViewController: UICollectionViewController {

    private enum SidebarItemType: Int {
        case header, row
    }

    private enum SidebarSection: Int {
        case panel, map, overlay

        func toString() -> String {
            switch self {
            case .panel:
                return "Panel"
            case .map:
                return "Base Layer"
            case .overlay:
                return "Overlay Layers"
            }
        }
    }

    private struct SidebarItem: Hashable, Identifiable {
        let id: String
        let type: SidebarItemType
        let layerId: Int
        let title: String
        let image: UIImage?
        let active: Bool

        static func header(for section: SidebarSection) -> Self {
            return SidebarItem(id: section.toString(), type: .header, layerId: 0, title: section.toString(), image: nil, active: false)
        }

        static func rowFrom(panel: Panel) -> Self {
            return SidebarItem(id: "\(panel.id)", type: .row, layerId: 0, title: panel.label, image: UIImage(named: panel.icon) ?? UIImage(named: "ic_action_new_event"), active: false)
        }

        static func rowFrom(layer: Layer) -> Self {
            return SidebarItem(id: "L-\(layer.layerID)", type: .row, layerId: layer.layerID, title: layer.layerName, image: nil, active: layer.active)
        }
    }

    private var dataSource: UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>!

    private var panelSubscriber: AnyCancellable?
    private var mapSubscriber: AnyCancellable?
    private var overlaySubscriber: AnyCancellable?

    private var layersController = LayersController.sharedInstance

    lazy var doneButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationItem()
        self.collectionView.collectionViewLayout = self.createLayout()
        self.configureDataSource()
        self.configureLayerController()
        // Do any additional setup after loading the view.
    }

    func configureNavigationItem() {
        if self.splitViewController?.traitCollection.horizontalSizeClass == .compact {
            self.navigationItem.leftBarButtonItem = self.doneButton
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
    }

    private func panelSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        let header = SidebarItem.header(for: .panel)

        var items = [SidebarItem]()
        for panel in layersController.panels {
            items.append(.rowFrom(panel: panel))
        }

        snapshot.append([header])
        snapshot.expand([header])
        snapshot.append(items, to: header)
        return snapshot
    }

    private func mapSnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        let header = SidebarItem.header(for: .map)

        var items = [SidebarItem]()
        for layer in layersController.baseLayers {
            items.append(.rowFrom(layer: layer))
        }

        snapshot.append([header])
        snapshot.expand([header])
        snapshot.append(items, to: header)
        return snapshot
    }

    private func overlaySnapshot() -> NSDiffableDataSourceSectionSnapshot<SidebarItem> {
        var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
        let header = SidebarItem.header(for: .overlay)

        var items = [SidebarItem]()
        for layer in layersController.overlayLayers {
            items.append(.rowFrom(layer: layer))
        }

        snapshot.append([header])
        snapshot.expand([header])
        snapshot.append(items, to: header)
        return snapshot
    }

    private func configureDataSource() {
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
            (cell, _, item) in

            var contentConfiguration = UIListContentConfiguration.sidebarHeader()
            contentConfiguration.text = item.title
            contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .subheadline)
            contentConfiguration.textProperties.color = .secondaryLabel

            cell.contentConfiguration = contentConfiguration
            cell.accessories = [.outlineDisclosure()]
        }

        let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
            (cell, _, item) in

            var contentConfiguration = UIListContentConfiguration.sidebarSubtitleCell()
            contentConfiguration.text = item.title
            contentConfiguration.image = item.image?.withRenderingMode(.alwaysTemplate)

            cell.contentConfiguration = contentConfiguration
            if item.active {
                cell.accessories = [.checkmark()]
            } else {
                cell.accessories = []
            }
        }

        dataSource = UICollectionViewDiffableDataSource<SidebarSection, SidebarItem>(collectionView: collectionView) {
            (collectionView, indexPath, item) -> UICollectionViewCell in

            switch item.type {
            case .header:
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            default:
                return collectionView.dequeueConfiguredReusableCell(using: rowRegistration, for: indexPath, item: item)
            }
        }
        self.collectionView.dataSource = dataSource
    }

    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (_, layoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.showsSeparators = false
            configuration.headerMode = .firstItemInSection
            configuration.backgroundColor = .clear
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return section
        }
        return layout
    }

    func configureLayerController() {
        self.panelSubscriber = layersController.$panels.receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let snapshot = self.panelSnapshot()
                self.dataSource.apply(snapshot, to: .panel, animatingDifferences: true)
            }
        self.mapSubscriber = layersController.$baseLayers.receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let snapshot = self.mapSnapshot()
                self.dataSource.apply(snapshot, to: .map, animatingDifferences: true)
            }
        self.overlaySubscriber = layersController.$overlayLayers.receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let snapshot = self.overlaySnapshot()
                self.dataSource.apply(snapshot, to: .overlay, animatingDifferences: true)
            }
    }

    // MARK: - TraitCollection
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.configureNavigationItem()
    }

    // MARK: - Button Action

    @objc func doneButtonPressed(_ sender: Any) {
        self.splitViewController?.show(.secondary)
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let sidebarItem = dataSource.itemIdentifier(for: indexPath) else { return }
        switch indexPath.section {
        case SidebarSection.panel.rawValue:
            layersController.openPanel(sidebarItem.id)
            self.splitViewController?.show(.secondary)
        case SidebarSection.map.rawValue:
            layersController.show(map: sidebarItem.layerId)
            self.splitViewController?.show(.secondary)
        case SidebarSection.overlay.rawValue:
            layersController.show(overlay: sidebarItem.layerId)
        default:
            return
        }
    }
}
