//
//  SectionColorHeader.swift
//  SectionsTableView
//
//  Created by Sun on 2024/8/20.
//

import UIKit

public class SectionColorHeader: UITableViewHeaderFooterView {

    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        backgroundView = UIView()
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
