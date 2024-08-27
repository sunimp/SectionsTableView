//
//  ViewController.swift
//  SectionsTableView-Example
//
//  Created by Sun on 2024/8/20.
//

import UIKit

import SnapKit
import SectionsTableView

class ViewController: UIViewController, SectionsDataSource {
    private let tableView = SectionsTableView(style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)

        tableView.registerCell(forClass: UITableViewCell.self)

        tableView.sectionDataSource = self
        tableView.separatorStyle = .singleLine
        tableView.backgroundColor = .clear
        tableView.delaysContentTouches = false

        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.alwaysBounceVertical = false
        tableView.buildSections()
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        var rows = [RowProtocol]()

        for i in 0..<20 {
            let sendButtonRow = Row<UITableViewCell>(id: "indexed_row", height: 44, bind: { cell, _ in
                cell.backgroundColor = .clear
                cell.selectionStyle = .none
                cell.textLabel?.text = "Row number #\(i)"
                cell.textLabel?.textColor = .black
            }, action: { [weak self] cell in
                self?.onRowTap()
            })
            rows.append(sendButtonRow)
        }

        sections.append(Section(id: "section",
            headerState: .spinner,
            footerState: .text(text: "FooterHeader + top margin 16", topMargin: 16, bottomMargin: 8),
            rows: rows))
        return sections
    }

    private func onRowTap() {
        print("Tapped row!")
    }

}
