//
//  SectionLabelView.swift
//  SectionsTableView
//
//  Created by Sun on 2024/8/20.
//

import UIKit

import SnapKit
import UIExtensions

public class SectionLabelView: UITableViewHeaderFooterView {
    private static let font = UIFont.systemFont(ofSize: 13)
    private static let defaultTopInset: CGFloat = 8

    private let label = UILabel()
    
    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(LayoutHelper.shared.marginContentInset)
            maker.top.equalToSuperview().inset(Self.defaultTopInset)
            maker.bottom.equalToSuperview()
        }
        
        label.font = Self.font
    }
    
    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func bind(title: String, topMargin: CGFloat) {
        label.text = title
        label.snp.updateConstraints { maker in
            maker.top.equalToSuperview().inset(topMargin)
        }
        layoutIfNeeded()
    }

    public static func height(forContainerWidth containerWidth: CGFloat, text: String, additionalMargins: CGFloat) -> CGFloat {
        ceil(text.height(
            forContainerWidth: containerWidth - LayoutHelper.shared.contentMarginWidth,
            font: font
        ) + additionalMargins)
    }

}
