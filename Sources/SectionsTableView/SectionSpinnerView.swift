//
//  SectionSpinnerView.swift
//  SectionsTableView
//
//  Created by Sun on 2021/11/29.
//

import UIKit

import SnapKit
import UIExtensions

public class SectionSpinnerView: UITableViewHeaderFooterView {
    // MARK: Properties

    private let activityIndicator = UIActivityIndicatorView()

    // MARK: Lifecycle

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview().inset(LayoutHelper.shared.marginContentInset)
            maker.centerX.equalToSuperview()
        }
    }
    
    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Functions

    public func bind() {
        activityIndicator.startAnimating()
    }
}
