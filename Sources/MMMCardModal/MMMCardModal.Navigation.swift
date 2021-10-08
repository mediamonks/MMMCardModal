//
// MMMCardModal.
// Copyright (C) 2020 MediaMonks. All rights reserved.
//

import UIKit

public protocol CardModal_ChildControllerDelegate: UIViewController, // swiftlint:disable:this class_delegate_protocol
	CardModal_PresentationProtocol
{
	/// This should be `weak` in the implementation.
	var navigationHost: MMMCardModal.NavigationHost? { get set }
}

extension CardModal_ChildControllerDelegate {
	
	fileprivate var identifier: ObjectIdentifier { ObjectIdentifier(self) }
	
	public func cardModalWillDragToClose(_ controller: MMMCardModal.ViewController) {
		navigationHost?.dismiss(animated: true)
	}
}

public protocol CardModal_NavigationController: UIViewController {
	
	/// Supply the base view.
	var view: UIView! { get }
	
	/// Supply the current view controller.
	var topViewController: UIViewController? { get }
	
	/// Call this when the controller changes.
	var viewControllerDidChange: (() -> Void)? { get set }
	
	/// If the dragging is enabled. You might want to disable this when swiping to a new controller.
	var isDraggingEnabled: Bool { get }
	
	/// Call this when the controller changes.
	var isDraggingEnabledDidChange: (() -> Void)? { get set }
}

extension CardModal_NavigationController {

	public var isDraggingEnabled: Bool { true }
}

extension MMMCardModal {

	/// Conform the ViewControllers in your NavigationController to this delegate to get a reference to
	/// the `NavigationHost` and the delegate callbacks.
	public typealias ChildControllerDelegate = CardModal_ChildControllerDelegate

	/// If you have a custom NavigationController, you can conform to this protocol.
	public typealias NavigationController = CardModal_NavigationController

	/// Present a set of ViewControllers in a MMMCardModal.
	///
	/// You can conform the controllers in your `NavigationController` to `ChildControllerDelegate`
	/// to get access to the `NavigationHost` and the delegate callbacks to detect closing & position
	/// changes.
	///
	/// Make sure to have the reference to the parent `navigationHost` defined as `weak` to avoid
	/// cyclic references.
	///
	/// **Required:**
	///  - You should implement `cardModalWillDragToClose` to close the presented
	///  `NavigationHost` and usually do some cleaning up. You can  dismiss the presented
	///  `NavigationHost` with animation so the StatusBar animates with it. Get a reference
	///  to the host by conforming to the `ChildControllerDelegate` protocol.
	open class NavigationHost: ViewController {

		private struct WeakReference {
			fileprivate weak var delegate: ChildControllerDelegate?
		}

		private let controller: NavigationController
		private var childDelegates = [WeakReference]()

		public init(controller: NavigationController) {
			self.controller = controller
			
			controller.view.translatesAutoresizingMaskIntoConstraints = false

			super.init(view: controller.view)
			
			controller.viewControllerDidChange = { [weak self] in
				self?.attachIfPossible()
			}
			
			controller.isDraggingEnabledDidChange = { [weak self] in
				self?.update()
			}
			
			update()
			attachIfPossible()
		}
		
		open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
			return controller.supportedInterfaceOrientations
		}

		private func attachIfPossible() {
			
			guard case let child as ChildControllerDelegate = controller.topViewController else {
				// Not for us.
				return
			}
			
			child.navigationHost = self
			
			let exists = childDelegates.contains { ref in
				guard let delegate = ref.delegate else { return false }

				return delegate == child
			}

			if !exists {
				childDelegates.append(.init(delegate: child))
			}
		}
		
		private func update() {
			isDraggingEnabled = controller.isDraggingEnabled
		}

		// MARK: - Child delegates proxy

		open func cardModalWillDrag(_ controller: ViewController, to position: StickPosition) {
			childDelegates.forEach {
				$0.delegate?.cardModalWillDrag(controller, to: position)
			}
		}

		open func cardModalDidDrag(_ controller: ViewController, to position: StickPosition) {
			childDelegates.forEach {
				$0.delegate?.cardModalDidDrag(controller, to: position)
			}
		}
		
		open func cardModalIsDragging(_ controller: ViewController, to position: StickPosition, progress: CGFloat) {
			childDelegates.forEach {
				$0.delegate?.cardModalIsDragging(controller, to: position, progress: progress)
			}
		}

		open func cardModalWillDragToClose(_ controller: ViewController) {
			childDelegates.forEach {
				$0.delegate?.cardModalWillDragToClose(controller)
			}
		}

		open func cardModalDidDragToClose(_ controller: ViewController) {
			childDelegates.forEach {
				$0.delegate?.cardModalDidDragToClose(controller)
			}
		}
		
		public func cardModalDidTapOutside(_ controller: ViewController) {
			childDelegates.forEach {
				$0.delegate?.cardModalDidTapOutside(controller)
			}
		}
	}
}
