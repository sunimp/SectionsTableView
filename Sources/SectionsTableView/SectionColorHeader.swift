//
//  SectionColorHeader.swift
//  SectionsTableView
//
//  Created by Sun on 2024/8/20.
//

import UIKit

public class SectionColorHeader: UITableViewHeaderFooterView {

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView()
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
