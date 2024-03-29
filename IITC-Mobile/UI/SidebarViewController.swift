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
    static var iconMap = [
        "ic_action_about": UIImage(systemName: "info.circle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),
        "ic_action_view_as_list": UIImage(systemName: "doc.plaintext", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),
        "ic_action_cc_bcc": UIImage(systemName: "person.2.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),
        "ic_action_warning": UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),

        "ic_action_star": UIImage(systemName: "star.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),
        "ic_missions": UIImage(systemName: "map.fill", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),
        "ic_action_data_usage": UIImage(systemName: "", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),
        "ic_action_paste": UIImage(systemName: "square.text.square", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),
        "ic_action_view_as_list_compact": UIImage(systemName: "doc.plaintext", withConfiguration: UIImage.SymbolConfiguration(weight: .bold)),

        "ic_action_new_event": UIImage(systemName: "note.text.badge.plus", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
    ]

    private enum SidebarItemType: Int {
        case header, row
    }

    private enum SidebarSection: Int, CaseIterable {
        case panel, map, overlay

        func toString() -> String {
            switch self {
            case .panel:
                return "Panel"
            case .map:
                return "Map"
            case .overlay:
                return "Overlays"
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
            if let image = iconMap[panel.icon] {
                return SidebarItem(id: "\(panel.id)", type: .row, layerId: 0, title: panel.label, image: image, active: false)
            }
            return SidebarItem(id: "\(panel.id)", type: .row, layerId: 0, title: panel.label, image: iconMap["ic_action_new_event"]!, active: false)
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

    var layerControl: UISegmentedControl = UISegmentedControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureNavigationItem()
        self.collectionView.collectionViewLayout = self.createLayout()
        self.configureDataSource()
        self.configureLayerController()
        self.configureSegmentControl()
        self.frameSize = self.view.frame.size
        self.safeAreaInsets = self.view.safeAreaInsets
        self.configureInsetOfCollectionContent()
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
        if self.dataSource.snapshot(for: .panel).isExpanded(header) {
            snapshot.expand([header])
        }
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
        if self.dataSource.snapshot(for: .map).isExpanded(header) {
            snapshot.expand([header])
        }
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
        if self.dataSource.snapshot(for: .overlay).isExpanded(header) {
            snapshot.expand([header])
        }
        snapshot.append(items, to: header)
        return snapshot
    }

    private func configureDataSource() {
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
            (cell, _, item) in

            var contentConfiguration = UIListContentConfiguration.sidebarHeader()
            contentConfiguration.text = item.title
            contentConfiguration.textProperties.font = .preferredFont(forTextStyle: .headline)
            contentConfiguration.textProperties.color = .secondaryLabel

            cell.contentConfiguration = contentConfiguration
            cell.accessories = [.outlineDisclosure(options: .init(style: .header))]
        }

        let rowRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SidebarItem> {
            (cell, _, item) in

            var contentConfiguration = UIListContentConfiguration.sidebarCell()
            contentConfiguration.text = item.title
            contentConfiguration.image = item.image?.withRenderingMode(.alwaysTemplate)
            cell.contentConfiguration = contentConfiguration

            cell.backgroundView = {
                let view = UIView()
                view.backgroundColor = .clear
                return view
            }()
            cell.selectedBackgroundView = {
                let bgview = UIView(frame: CGRect(x: 0, y: 0, width: cell.frame.size.width, height: cell.frame.size.height))
                bgview.layer.cornerRadius = 5
                bgview.backgroundColor = UIColor.opaqueSeparator
                return bgview
            }()

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
        for section in SidebarSection.allCases {
            let header = SidebarItem.header(for: section)
            var snapshot = NSDiffableDataSourceSectionSnapshot<SidebarItem>()
            snapshot.append([header])
            snapshot.expand([header])
            dataSource.apply(snapshot, to: section)
        }
        self.collectionView.dataSource = dataSource
    }

    func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (_, layoutEnvironment) -> NSCollectionLayoutSection? in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebar)
            configuration.showsSeparators = false
            configuration.headerMode = .firstItemInSection
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            #if targetEnvironment(macCatalyst)
            section.interGroupSpacing = 4
            #endif
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

    var isScrolledByLayerControl: Bool = false
    private func scrollTo(section: SidebarSection) {
        guard let index = self.dataSource.indexPath(for: .header(for: section)) else {
            return
        }
        isScrolledByLayerControl = true
        self.collectionView.scrollToItem(at: index, at: .top, animated: true)
    }

    func configureSegmentControl() {
        self.navigationItem.titleView = self.layerControl

        for section in SidebarSection.allCases {
            self.layerControl.insertSegment(action: UIAction(title: section.toString(), handler: { _ in
                self.scrollTo(section: section)
            }), at: section.rawValue, animated: false)
        }
        self.layerControl.selectedSegmentIndex = 0
    }

    // MARK: - UI Changes
    var frameSize: CGSize = .zero
    var safeAreaInsets: UIEdgeInsets = .zero

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.configureNavigationItem()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        frameSize = size
        self.configureInsetOfCollectionContent()
    }

    override func viewSafeAreaInsetsDidChange() {
        safeAreaInsets = self.view.safeAreaInsets
        self.configureInsetOfCollectionContent()
    }

    func configureInsetOfCollectionContent() {
        // add extra space at bottom for better scroll anchor experience.
        let contentHeight = frameSize.height - safeAreaInsets.top - safeAreaInsets.bottom
        let cellHeight: CGFloat = 55
        self.collectionView.contentInset = .init(top: 0, left: 0, bottom: contentHeight - cellHeight, right: 0)
    }

    // MARK: - Button Action

    @objc func doneButtonPressed(_ sender: Any) {
        self.splitViewController?.show(.secondary)
    }

    // MARK: - UICollectionViewDelegate

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

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrolledByLayerControl = false
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isScrolledByLayerControl {
            return
        }
        let topOfFirstCell = self.view.convert(CGPoint(x: collectionView.frame.size.width / 2, y: collectionView.safeAreaInsets.top), to: self.collectionView)
        if let idx = collectionView.indexPathForItem(at: topOfFirstCell) {
            self.layerControl.selectedSegmentIndex = idx.section
            return
        }

        var minY = CGFloat(65536)
        var idx: IndexPath?
        for cell in collectionView.visibleCells {
            let cellY = cell.frame.minY
            if cellY < topOfFirstCell.y {
                continue
            }
            if cellY < minY {
                minY = cellY
                idx = collectionView.indexPath(for: cell)
            }
        }

        guard let idx = idx else {
            return
        }
        self.layerControl.selectedSegmentIndex = idx.section
    }
}
