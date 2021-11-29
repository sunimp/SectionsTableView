import UIKit
import UIExtensions
import SnapKit

public class SectionLabelView: UITableViewHeaderFooterView {
    private static let font = UIFont.systemFont(ofSize: 13)
    private static let defaultTopInset: CGFloat = 8

    private let label = UILabel()
    
    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(LayoutHelper.instance.marginContentInset)
            maker.top.equalToSuperview().inset(Self.defaultTopInset)
            maker.bottom.equalToSuperview()
        }
        
        label.font = Self.font
    }
    
    public required init?(coder: NSCoder) {
        fatalError()
    }

    func bind(title: String, topMargin: CGFloat) {
        label.text = title
        label.snp.updateConstraints { maker in
            maker.top.equalToSuperview().inset(topMargin)
        }
        layoutIfNeeded()
    }

    static func height(forContainerWidth containerWidth: CGFloat, text: String, additionalMargins: CGFloat) -> CGFloat {
        return ceil(text.height(forContainerWidth: containerWidth - LayoutHelper.instance.contentMarginWidth, font: font) + additionalMargins)
    }

}
