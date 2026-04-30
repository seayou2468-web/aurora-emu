import UIKit

final class SwiftControllerOverlayView: UIView {
    private let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) { nil }

    func apply(skin: SwiftSkin) {
        alpha = CGFloat(skin.opacity)
        if let name = skin.overlayImageName { imageView.image = UIImage(named: name) }
        else { imageView.image = nil }
    }
}
