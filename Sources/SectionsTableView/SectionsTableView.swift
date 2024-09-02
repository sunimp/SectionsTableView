//
//  SectionsTableView.swift
//
//  Created by Sun on 2021/11/29.
//

import UIKit

import SnapKit

// MARK: - SectionsDataSource

public protocol SectionsDataSource: AnyObject {
    func buildSections() -> [SectionProtocol]
    func unbind(cell: UITableViewCell)
    func onBottomReached()
    func userDidScroll()
    func didScroll()
    func userWillDragging()
}

extension SectionsDataSource {
    public func unbind(cell _: UITableViewCell) { }
    public func onBottomReached() { }
    public func userDidScroll() { }
    public func didScroll() { }
    public func userWillDragging() { }
}

// MARK: - SectionsTableView

open class SectionsTableView: UITableView, UITableViewDelegate, UITableViewDataSource {
    // MARK: Properties

    public var sections = [SectionProtocol]()
    public weak var sectionDataSource: SectionsDataSource?

    // MARK: Lifecycle

    public init(style: UITableView.Style) {
        super.init(frame: .zero, style: style)

        delegate = self
        dataSource = self

        cellLayoutMarginsFollowReadableWidth = false

        tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.ulpOfOne))
        tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.ulpOfOne))

        rowHeight = 0
        sectionHeaderHeight = 0
        sectionFooterHeight = 0
        estimatedSectionHeaderHeight = 0
        estimatedSectionFooterHeight = 0
        estimatedRowHeight = 0

        registerCell(forClass: SectionEmptyCell.self)
        registerHeaderFooter(forClass: SectionLabelView.self)
        registerHeaderFooter(forClass: SectionColorHeader.self)
        registerHeaderFooter(forClass: SectionSpinnerView.self)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Functions

    open func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    open func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = sections[indexPath.section].rows[indexPath.row]
        let separatorHeight = tableView.separatorStyle == .none ? 0 : 1 / UIScreen.main.scale
        return (row.dynamicHeight?(width)).map { $0 + separatorHeight } ?? row.height
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        triggerBottomReachedIfRequired(indexPath: indexPath)

        let row = sections[indexPath.section].rows[indexPath.row]
        switch row.rowType {
        case let .dynamic(reuseIdentifier, prepare):
            if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) {
                prepare(cell)
                return cell
            } else {
                print("Can't dequeue cell, did you forget to register cell?")
                return UITableViewCell(style: .default, reuseIdentifier: "")
            }

        case let .static(cell):
            return cell
        }
    }

    open func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        sections[indexPath.section].rows[indexPath.row].bindCell(cell: cell, animated: false)
    }

    open func tableView(_: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt _: IndexPath) {
        sectionDataSource?.unbind(cell: cell)
    }

    open func tableView(_: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].getHeaderHeight(containerWidth: width)
    }

    open func tableView(_: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        sections[section].getFooterHeight(containerWidth: width)
    }

    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        sections[section].getHeaderView(tableView: tableView)
    }

    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        sections[section].getFooterView(tableView: tableView)
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if sections[indexPath.section].rows[indexPath.row].autoDeselect {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        if let cell = cellForRow(at: indexPath) {
            sections[indexPath.section].rows[indexPath.row].onSelect(cell: cell)
        }
    }

    open func scrollViewDidScroll(_: UIScrollView) {
        sectionDataSource?.didScroll()
        if isDragging, !isDecelerating {
            sectionDataSource?.userDidScroll()
        }
    }

    open func scrollViewWillBeginDragging(_: UIScrollView) {
        sectionDataSource?.userWillDragging()
    }

    open func triggerBottomReachedIfRequired() {
        indexPathsForVisibleRows?.forEach { indexPath in
            triggerBottomReachedIfRequired(indexPath: indexPath)
        }
    }

    public func reload(animated: Bool = false) {
        if animated {
            reloadAnimated()
        } else {
            buildSections()
            reloadData()
        }
    }

    public func buildSections() {
        sections = sectionDataSource?.buildSections() ?? []
    }

    public func tableView(
        _: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    )
        -> UISwipeActionsConfiguration? {
        guard sections.count > indexPath.section else {
            return nil
        }
        let section = sections[indexPath.section]

        guard section.rows.count > indexPath.row else {
            return nil
        }
        let row = section.rows[indexPath.row]

        guard let provider = row.rowActionProvider else {
            return nil
        }

        let cell = cellForRow(at: indexPath)

        let config = UISwipeActionsConfiguration(actions: provider().map { rowAction in
            let action = UIContextualAction(style: .normal, title: nil) { _, _, handler in
                rowAction.action(cell)
                handler(true)
            }
            switch rowAction.pattern {
            case let .text(title, color, icon):
                action.backgroundColor = UIColor(patternImage: patternImage(
                    title: title,
                    color: color,
                    icon: icon,
                    rowHeight: row.height
                ))

            case let .icon(image: image, background: backgroundColor):
                action.image = image
                action.backgroundColor = backgroundColor
            }
            return action
        })

        config.performsFirstActionWithFullSwipe = true

        return config
    }

    private func reloadAnimated() {
        let oldSections = sections
        buildSections()

        var insertSectionsIndexSet = IndexSet()
        var deleteSectionsIndexSet = IndexSet()
        var reloadSectionsIndexSet = IndexSet()

        var moveRowsIndexPaths = [(IndexPath, IndexPath)]()
        var insertRowsIndexPaths = [IndexPath]()
        var deleteRowsIndexPaths = [IndexPath]()

        var reloadRowTuples = [(RowProtocol, IndexPath)]()

        for (oldSectionIndex, oldSection) in oldSections.enumerated() {
            if let sectionIndex = sections.firstIndex(where: { $0.id == oldSection.id }) {
                let section = sections[sectionIndex]
                var usedIndexes = [Int]()
                for (oldRowIndex, oldRow) in oldSection.rows.enumerated() {
                    var rowIndex: Int?
                    for (index, row) in section.rows.enumerated() {
                        if row.id == oldRow.id, usedIndexes.firstIndex(of: index) == nil {
                            rowIndex = index
                            usedIndexes.append(index)
                            break
                        }
                    }
                    if let rowIndex {
                        let row = section.rows[rowIndex]
                        if row.hash != oldRow.hash {
                            reloadRowTuples.append((row, IndexPath(row: oldRowIndex, section: oldSectionIndex)))
                        }
                        if rowIndex != oldRowIndex {
                            moveRowsIndexPaths.append((
                                IndexPath(row: oldRowIndex, section: oldSectionIndex),
                                IndexPath(row: rowIndex, section: sectionIndex)
                            ))
                        }
                    } else {
                        deleteRowsIndexPaths.append(IndexPath(row: oldRowIndex, section: oldSectionIndex))
                    }
                }

                for (rowIndex, row) in section.rows.enumerated() {
                    if !oldSection.rows.contains(where: { $0.id == row.id }) {
                        insertRowsIndexPaths.append(IndexPath(row: rowIndex, section: sectionIndex))
                    }
                }

                if !section.isSameState(with: oldSection) {
                    reloadSectionsIndexSet.insert(oldSectionIndex)
                }
            } else {
                deleteSectionsIndexSet.insert(oldSectionIndex)
            }
        }

        for (sectionIndex, section) in sections.enumerated() {
            if !oldSections.contains(where: { $0.id == section.id }) {
                insertSectionsIndexSet.insert(sectionIndex)
            }
        }

        if !reloadRowTuples.isEmpty {
            for reloadRowTuple in reloadRowTuples {
                if let cell = cellForRow(at: reloadRowTuple.1) {
                    sectionDataSource?.unbind(cell: cell)
                    reloadRowTuple.0.bindCell(cell: cell, animated: true)
                }
            }
        }

        if
            !insertSectionsIndexSet.isEmpty || !deleteSectionsIndexSet.isEmpty || !reloadSectionsIndexSet
                .isEmpty || !moveRowsIndexPaths.isEmpty || !insertRowsIndexPaths.isEmpty || !deleteRowsIndexPaths.isEmpty
        {
            beginUpdates()
            if !insertSectionsIndexSet.isEmpty {
                insertSections(insertSectionsIndexSet, with: .top)
            }
            if !deleteSectionsIndexSet.isEmpty {
                deleteSections(deleteSectionsIndexSet, with: .none)
            }
            if !reloadSectionsIndexSet.isEmpty {
                reloadSections(reloadSectionsIndexSet, with: .automatic)
            }

            if !moveRowsIndexPaths.isEmpty {
                for (at, to) in moveRowsIndexPaths {
                    moveRow(at: at, to: to)
                }
            }
            if !insertRowsIndexPaths.isEmpty {
                insertRows(at: insertRowsIndexPaths, with: .top)
            }
            if !deleteRowsIndexPaths.isEmpty {
                deleteRows(at: deleteRowsIndexPaths, with: .fade)
                for deleteRowsIndexPath in deleteRowsIndexPaths {
                    triggerBottomReachedIfRequired(indexPath: deleteRowsIndexPath)
                }
            }
            endUpdates()
        }
    }

    private func triggerBottomReachedIfRequired(indexPath: IndexPath) {
        let section = sections[indexPath.section]

        if section.paginating, indexPath.row > section.rows.count - 5 {
            sectionDataSource?.onBottomReached()
        }
    }

    private func patternImage(title: String, color: UIColor, icon: UIImage?, rowHeight: CGFloat) -> UIImage {
        let containerSize = CGSize(width: 75, height: 74)
        let iconOffset: CGFloat = 14
        let iconSize = CGSize(width: 24, height: 24)
        let textHorizontalMargin: CGFloat = 3
        let textContainerSize = CGSize(
            width: containerSize.width - textHorizontalMargin * 2,
            height: containerSize.height - iconOffset - iconSize.height
        )

        let offsetY = max(0, (rowHeight - containerSize.height) / 2)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributedText = NSAttributedString(
            string: title,
            attributes: [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.foregroundColor: UIColor.white,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13),
            ]
        )
        let textSize = attributedText.boundingRect(
            with: CGSize(width: textContainerSize.width, height: .greatestFiniteMagnitude),
            options: [.usesFontLeading, .usesLineFragmentOrigin],
            context: nil
        ).size

        var patternImage: UIImage?

        UIGraphicsBeginImageContextWithOptions(
            CGSize(width: containerSize.width * 2, height: rowHeight),
            false,
            UIScreen.main.scale
        )
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: containerSize.width * 2, height: rowHeight))

            if let icon {
                icon.draw(in: CGRect(
                    x: (containerSize.width - icon.size.width) / 2,
                    y: offsetY + iconOffset + (iconSize.height - icon.size.height) / 2,
                    width: icon.size.width,
                    height: icon.size.height
                ))
            }

            let textPosition = CGPoint(
                x: (containerSize.width - textSize.width) / 2,
                y: offsetY + iconOffset + iconSize.height + max(0, textContainerSize.height - textSize.height) / 2
            )
            attributedText.draw(in: CGRect(origin: textPosition, size: textSize))

            patternImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return patternImage ?? UIImage()
    }
}

// MARK: - RowType

public enum RowType {
    case dynamic(reuseIdentifier: String, prepare: (UITableViewCell) -> Void)
    case `static`(cell: UITableViewCell)
}

// MARK: - RowProtocol

public protocol RowProtocol {
    var id: String { get }
    var hash: String? { get }
    var height: CGFloat { get }
    var separatorInset: UIEdgeInsets? { get }
    var autoDeselect: Bool { get }
    var rowActionProvider: (() -> [RowAction])? { get }
    var rowType: RowType { get }
    var dynamicHeight: ((CGFloat) -> CGFloat)? { get }
    func bindCell(cell: UITableViewCell, animated: Bool)
    func onSelect(cell: UITableViewCell)
}

// MARK: - SectionProtocol

public protocol SectionProtocol {
    var id: String { get }
    var paginating: Bool { get }
    var rows: [RowProtocol] { get }
    func getHeaderHeight(containerWidth: CGFloat) -> CGFloat
    func getFooterHeight(containerWidth: CGFloat) -> CGFloat
    func getHeaderView(tableView: UITableView) -> UIView?
    func getFooterView(tableView: UITableView) -> UIView?
    func isSameState(with section: SectionProtocol) -> Bool
}

// MARK: - ViewState

public enum ViewState<T: UITableViewHeaderFooterView>: Equatable {
    case margin(height: CGFloat)
    case marginColor(height: CGFloat, color: UIColor?)
    case cellType(hash: String, binder: ((T) -> Void)?, dynamicHeight: (CGFloat) -> CGFloat)
    case `static`(view: T, height: CGFloat)
    case text(text: String, topMargin: CGFloat, bottomMargin: CGFloat)
    case spinner

    // MARK: Static Functions

    public static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case let (.margin(heightA), .margin(heightB)):
            heightA == heightB
        case let (.marginColor(heightA, colorA), .marginColor(heightB, colorB)):
            heightA == heightB && colorA == colorB
        case let (.cellType(hashA, _, _), .cellType(hashB, _, _)):
            hashA == hashB
        case let (.text(textA, topMarginA, bottomMarginA), .text(textB, topMarginB, bottomMarginB)):
            textA == textB && topMarginA == topMarginB && bottomMarginA == bottomMarginB
        case (.spinner, .spinner):
            true
        case let (.static(viewA, _), .static(viewB, _)): viewA == viewB
        default:
            false
        }
    }
}

// MARK: - Section

public struct Section<H: UITableViewHeaderFooterView, F: UITableViewHeaderFooterView>: SectionProtocol {
    // MARK: Properties

    public let id: String
    public let paginating: Bool
    public var rows: [RowProtocol]

    let headerState: ViewState<H>
    let footerState: ViewState<F>

    // MARK: Lifecycle

    public init(
        id: String,
        paginating: Bool = false,
        headerState: ViewState<H> = .margin(height: 0),
        footerState: ViewState<F> = .margin(height: 0),
        rows: [RowProtocol] = []
    ) {
        self.id = id
        self.paginating = paginating
        self.headerState = headerState
        self.footerState = footerState
        self.rows = rows
    }

    // MARK: Functions

    public func getHeaderHeight(containerWidth: CGFloat) -> CGFloat { getHeight(
        viewState: headerState,
        containerWidth: containerWidth
    ) }
    public func getFooterHeight(containerWidth: CGFloat) -> CGFloat { getHeight(
        viewState: footerState,
        containerWidth: containerWidth
    ) }

    public func isSameState(with section: SectionProtocol) -> Bool {
        guard let section = section as? Section else {
            return false
        }
        return footerState == section.footerState && headerState == section.headerState
    }

    public func getHeaderView(tableView: UITableView) -> UIView? {
        getView(tableView: tableView, viewState: headerState)
    }

    public func getFooterView(tableView: UITableView) -> UIView? {
        getView(tableView: tableView, viewState: footerState)
    }

    private func getHeight<T>(viewState: ViewState<T>, containerWidth: CGFloat) -> CGFloat {
        if case let .margin(height) = viewState {
            return height
        }

        if case let .marginColor(height, _) = viewState {
            return height
        }

        if case let .cellType(_, _, dynamicHeight) = viewState {
            return dynamicHeight(containerWidth)
        }

        if case let .text(text, topMargin, bottomMargin) = viewState {
            return SectionLabelView.height(
                forContainerWidth: containerWidth,
                text: text,
                additionalMargins: topMargin + bottomMargin
            )
        }

        if case let .static(_, height) = viewState {
            return height
        }

        if case .spinner = viewState {
            return 50
        }

        return 44 // fallback
    }

    private func getView<T>(tableView: UITableView, viewState: ViewState<T>) -> UIView? {
        if
            case let .cellType(_, binder, _) = viewState,
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: T.self)) as? T {
            binder?(view)
            return view
        }

        if
            case let .text(text, topMargin, _) = viewState,
            let view = tableView
                .dequeueReusableHeaderFooterView(withIdentifier: String(
                    describing: SectionLabelView
                        .self
                )) as? SectionLabelView {
            view.bind(title: text, topMargin: topMargin)
            return view
        }

        if
            case .spinner = viewState,
            let view = tableView
                .dequeueReusableHeaderFooterView(withIdentifier: String(
                    describing: SectionSpinnerView
                        .self
                )) as? SectionSpinnerView {
            view.bind()
            return view
        }

        if
            case let .marginColor(_, color) = viewState,
            let view = tableView
                .dequeueReusableHeaderFooterView(withIdentifier: String(
                    describing: SectionColorHeader
                        .self
                )) as? SectionColorHeader {
            view.backgroundView?.backgroundColor = color
            return view
        }

        if case let .static(view: view, _) = viewState {
            return view
        }

        return nil
    }
}

// MARK: - Row

public struct Row<T: UITableViewCell>: RowProtocol {
    // MARK: Properties

    public let id: String
    public var hash: String?
    public let height: CGFloat
    public let separatorInset: UIEdgeInsets?
    public var autoDeselect: Bool
    public var rowActionProvider: (() -> [RowAction])?
    public let rowType: RowType
    public var dynamicHeight: ((CGFloat) -> CGFloat)?

    var bind: ((T, Bool) -> Void)?
    var action: ((T) -> Void)?

    // MARK: Lifecycle

    public init(
        id: String,
        hash: String? = nil,
        height: CGFloat? = nil,
        separatorInset: UIEdgeInsets? = nil,
        autoDeselect: Bool = false,
        rowActionProvider: (() -> [RowAction])? = nil,
        rowType: RowType? = nil,
        dynamicHeight: ((CGFloat) -> CGFloat)? = nil,
        bind: ((T, Bool) -> Void)? = nil,
        action: ((T) -> Void)? = nil
    ) {
        self.id = id
        self.hash = hash
        self.height = height ?? 44
        self.separatorInset = separatorInset
        self.autoDeselect = autoDeselect
        self.rowActionProvider = rowActionProvider
        self.rowType = rowType ?? .dynamic(reuseIdentifier: String(describing: T.self), prepare: { _ in })
        self.dynamicHeight = dynamicHeight
        self.bind = bind
        self.action = action
    }

    // MARK: Static Functions

    public static func empty(id: String, height: CGFloat, backgroundColor: UIColor? = nil) -> RowProtocol {
        Row<SectionEmptyCell>(id: id, height: height, bind: { cell, _ in
            if let backgroundColor {
                cell.backgroundColor = backgroundColor
            }
        })
    }

    // MARK: Functions

    public func bindCell(cell: UITableViewCell, animated: Bool) {
        if let cell = cell as? T {
            bind?(cell, animated)
        }

        if let separatorInset {
            cell.separatorInset = separatorInset
        }
    }

    public func onSelect(cell: UITableViewCell) {
        if let cell = cell as? T {
            action?(cell)
        }
    }
}

// MARK: - StaticRow

public class StaticRow: RowProtocol {
    // MARK: Properties

    public let id: String
    public var hash: String?
    public let height: CGFloat
    public let separatorInset: UIEdgeInsets?
    public var autoDeselect: Bool
    public var rowActionProvider: (() -> [RowAction])?
    public let rowType: RowType
    public var dynamicHeight: ((CGFloat) -> CGFloat)?
    public var onReady: (() -> Void)?

    private var action: (() -> Void)?

    private var readyReported = false

    // MARK: Lifecycle

    public init(
        cell: UITableViewCell,
        id: String,
        height: CGFloat? = nil,
        separatorInset: UIEdgeInsets? = nil,
        autoDeselect: Bool = false,
        rowActionProvider: (() -> [RowAction])? = nil,
        dynamicHeight: ((CGFloat) -> CGFloat)? = nil,
        action: (() -> Void)? = nil,
        onReady: (() -> Void)? = nil
    ) {
        self.id = id
        self.height = height ?? 44
        self.separatorInset = separatorInset
        self.autoDeselect = autoDeselect
        self.rowActionProvider = rowActionProvider
        rowType = .static(cell: cell)
        self.dynamicHeight = dynamicHeight
        self.action = action
        self.onReady = onReady
    }

    // MARK: Functions

    public func bindCell(cell: UITableViewCell, animated _: Bool) {
        guard !readyReported else {
            return
        }

        readyReported = true

        cell.layoutIfNeeded()
        onReady?()
    }

    public func onSelect(cell _: UITableViewCell) {
        action?()
    }
}

// MARK: - RowAction

public struct RowAction {
    // MARK: Nested Types

    public enum Pattern {
        case text(title: String, color: UIColor, icon: UIImage?)
        case icon(image: UIImage?, background: UIColor)
    }

    // MARK: Properties

    let pattern: Pattern
    var action: (UITableViewCell?) -> Void

    // MARK: Lifecycle

    public init(pattern: Pattern, action: @escaping (UITableViewCell?) -> Void) {
        self.pattern = pattern
        self.action = action
    }
}
