import UIKit
import UIExtensions

class SectionSpinnerView: UITableViewHeaderFooterView {

    private let activityIndicator = UIActivityIndicatorView()

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview().inset(LayoutHelper.instance.marginContentInset)
            maker.centerX.equalToSuperview()
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError()
    }

    func bind() {
        activityIndicator.startAnimating()
    }

}
