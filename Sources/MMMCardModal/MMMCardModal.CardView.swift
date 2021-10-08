//
// MMMCardModal.
// Copyright (C) 2020 MediaMonks. All rights reserved.
//

import UIKit

extension MMMCardModal {
	
	internal class CardView: UIView {
		
		internal weak var options: Options? {
			didSet {
				updateUI()
			}
		}
		
		public let containerView = UIView(frame: .zero)
		public let animationView = UIView(frame: .zero)
		public let panGestureRecognizer = UIPanGestureRecognizer()
		public let tapGestureRecognizer = UITapGestureRecognizer()
		
		public private(set) var currentYPosition: CGFloat = 0
		
		private var topYConstraint: NSLayoutConstraint!
		private var bottomYConstraint: NSLayoutConstraint!
		
		public init(view: UIView, options: Options) {
			self.options = options
			
			super.init(frame: .zero)
			
			translatesAutoresizingMaskIntoConstraints = true
			
			tapGestureRecognizer.numberOfTouchesRequired = 1
			tapGestureRecognizer.numberOfTapsRequired = 1
			tapGestureRecognizer.cancelsTouchesInView = false
			addGestureRecognizer(tapGestureRecognizer)
			
			containerView.backgroundColor = .clear
			containerView.isUserInteractionEnabled = true
			containerView.translatesAutoresizingMaskIntoConstraints = false
			containerView.addGestureRecognizer(panGestureRecognizer)
			addSubview(containerView)
			addFillConstraints(subview: containerView)
			
			animationView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
			animationView.layer.masksToBounds = true
			animationView.translatesAutoresizingMaskIntoConstraints = false
			containerView.addSubview(animationView)
			
			view.translatesAutoresizingMaskIntoConstraints = false
			animationView.addSubview(view)
			animationView.addFillConstraints(
				subview: view,
				constants: .init(top: 0, left: 0, bottom: options.topPadding, right: 0)
			)
			
			let views = ["animationView": animationView]
			
			NSLayoutConstraint.activate(NSLayoutConstraint.constraints(
				withVisualFormat: "H:|-0-[animationView]-0-|",
				options: [], metrics: nil, views: views
			))
			
			let topConstraint = safeAreaLayoutGuide.topAnchor.constraint(
				equalTo: animationView.topAnchor,
				constant: -options.topPadding
			)
			
			// <= because we want to be able to swipe down without breaking child view constraints.
			let bottomConstraint = bottomAnchor.constraint(
				lessThanOrEqualTo: animationView.bottomAnchor,
				constant: -options.topPadding
			)
			
			// Add constraint that's equal to bottom at required - 1 so we almost always stick to it.
			let bottomEqualConstraint = bottomAnchor.constraint(
				equalTo: animationView.bottomAnchor,
				constant: -options.topPadding
			)
			bottomEqualConstraint.priority = .required - 1
			
			NSLayoutConstraint.activate([topConstraint, bottomConstraint, bottomEqualConstraint])
			
			topYConstraint = topConstraint
			bottomYConstraint = bottomConstraint
			
			updateUI()
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		public func setDragPosition(y: CGFloat) {
			currentYPosition = y
			updateUI()
		}
		
		private func updateUI() {
		
			guard let options = options else {
				// Options is released, no UI updates needed.
				return
			}
			
			switch options.animationType {
			case .transform:
				animationView.transform = .init(translationX: 0, y: currentYPosition)
				topYConstraint.constant = -options.topPadding
				
			case .constraints:
				animationView.transform = .identity
				topYConstraint.constant = -(options.topPadding + currentYPosition)
				
			}
			
			animationView.backgroundColor = options.cardBackgroundColor
			animationView.layer.cornerRadius = options.cardCornerRadius
			
			bottomYConstraint.constant = -options.topPadding
		}
	}
}
