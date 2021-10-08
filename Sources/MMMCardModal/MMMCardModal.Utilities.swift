//
// MMMCardModal.
// Copyright (C) 2020 MediaMonks. All rights reserved.
//

import UIKit

extension UIView {
	
	internal func addFillConstraints(
		subview: UIView,
		constants: UIEdgeInsets = .zero,
		priority: UILayoutPriority = .required
	) {
	
		let top = topAnchor.constraint(equalTo: subview.topAnchor, constant: constants.top)
		top.priority = priority
		
		let bottom = bottomAnchor.constraint(equalTo: subview.bottomAnchor, constant: constants.bottom)
		bottom.priority = priority
		
		let left = leftAnchor.constraint(equalTo: subview.leftAnchor, constant: constants.left)
		left.priority = priority
		
		let right = rightAnchor.constraint(equalTo: subview.rightAnchor, constant: constants.right)
		right.priority = priority
		
		NSLayoutConstraint.activate([top, bottom, left, right])
	}
	
}
