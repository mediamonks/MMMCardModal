//
// MMMCardModal.
// Copyright (C) 2020 MediaMonks. All rights reserved.
//

import UIKit

extension MMMCardModal {
	
	public enum StickPosition: Equatable {
		/// The top of the screen, below the safeArea and with normalPadding applied. Same as `.percentage(0)`.
		case top
		
		/// The center of the screen. Same as `.percentage(0.5)`.
		case center
		
		/// Amount in points to stick at, from the bottom.
		case points(CGFloat)
		
		/// Percentage of screen to stick at, e.g. 0.3 = 30% from the top.
		case percentage(CGFloat)
		
		internal func delta(for height: CGFloat, top: CGFloat) -> CGFloat {
			switch self {
				case .top: return 0
				case .center: return 0.5
				case .percentage(let val): return val
				case .points(let val): return 1 - ((val + top) / height)
			}
		}
	}
}

public protocol CardModal_PresentationProtocol {
	
	/// Called when the MMMCardModal will drag to a new stickPosition.
	/// - Parameters:
	///   - controller: The presented MMMCardModal controller.
	///   - position: The new position.
	func cardModalWillDrag(
		_ controller: MMMCardModal.ViewController,
		to position: MMMCardModal.StickPosition
	)
	
	/// Called while the MMMCardModal is dragging to a new stickPosition, so you can animate with the progress.
	/// - Parameters:
	///   - controller: The presented MMMCardModal controller.
	///   - position: The new position.
	///   - progress: The animation progress, in 'StickPosition' style, so 0.0 = top; 1.0 = bottom; 0.5 = center of screen.
	func cardModalIsDragging(
		_ controller: MMMCardModal.ViewController,
		to position: MMMCardModal.StickPosition,
		progress: CGFloat
	)
	
	/// Called when the MMMCardModal did drag to a new stickPosition.
	/// - Parameters:
	///   - controller: The presented MMMCardModal controller.
	///   - position: The new position.
	func cardModalDidDrag(
		_ controller: MMMCardModal.ViewController,
		to position: MMMCardModal.StickPosition
	)
	
	/// Called when the MMMCardModal will drag to close. Use this to dismiss the presented viewController.
	/// - Parameters:
	///   - controller: The presented MMMCardModal controller.
	func cardModalWillDragToClose(_ controller: MMMCardModal.ViewController)
	
	/// Called when the MMMCardModal did drag to close.
	/// - Parameter controller: The presented MMMCardModal controller.
	func cardModalDidDragToClose(_ controller: MMMCardModal.ViewController)
	
	/// Called when the MMMCardModal did tap outside of the presented card.
	/// - Parameter controller: The presented MMMCardModal controller.
	func cardModalDidTapOutside(_ controller: MMMCardModal.ViewController)
}

extension CardModal_PresentationProtocol {
	
	public func cardModalWillDrag(
		_ controller: MMMCardModal.ViewController,
		to position: MMMCardModal.StickPosition
	) {}
	
	public func cardModalIsDragging(
		_ controller: MMMCardModal.ViewController,
		to position: MMMCardModal.StickPosition,
		progress: CGFloat
	) {}
	
	public func cardModalDidDrag(
		_ controller: MMMCardModal.ViewController,
		to position: MMMCardModal.StickPosition
	) {}
	
	public func cardModalWillDragToClose(_ controller: MMMCardModal.ViewController) {
		controller.dismiss(animated: true)
	}
	
	public func cardModalDidDragToClose(_ controller: MMMCardModal.ViewController) {}
	
	public func cardModalDidTapOutside(_ controller: MMMCardModal.ViewController) {}
}
