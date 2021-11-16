//
// MMMCardModal.
// Copyright (C) 2020 MediaMonks. All rights reserved.
//

import UIKit

extension MMMCardModal {
	
	/// Don't use this class directly, use the MMMCardModal.ViewController instead.
	open class _ViewController: UIViewController, UIViewControllerTransitioningDelegate {
	
		fileprivate var _viewController: ViewController {
			guard case let vc as ViewController = self else {
				preconditionFailure("Don't use _ViewController directly")
			}
			
			return vc
		}
		
		private let _childView: UIView
		private weak var cardView: CardView?
		
		public private(set) var currentPosition: StickPosition? {
			didSet {
				if let value = currentPosition {
					_viewController.cardModalDidDrag(_viewController, to: value)
				}
			}
		}
		
		public var options = Options() {
			didSet {
				cardView?.options = options
				gestureController.options = options
				
				if case let presentation as PresentationController = presentationController {
					presentation.options = options
				}
			}
		}
		
		/// Assign to a scrollView to have the iOS 13 modal effect of dragging down.
		public weak var captureScrollView: UIScrollView? {
			didSet {
				oldValue?.panGestureRecognizer.removeTarget(self, action: #selector(didScrollPan(sender:)))
				
				gestureController.captureScrollView = captureScrollView
				
				if let scrollView = captureScrollView {
					scrollView.panGestureRecognizer.addTarget(self, action: #selector(didScrollPan(sender:)))
				}
			}
		}
		
		/// The view that holds the content insinde the scrollView. It's reccomended to assign this as well so the user doesn't notice the
		/// double scroll drag. Please note that this view will be transformed, downside is that you lose the bounce effect on top.
		public weak var captureScrollViewContent: UIView? {
			didSet {
				gestureController.captureScrollViewContent = captureScrollViewContent
			}
		}
		
		/// The positions where the CardModal should stick to. Defaults to `.top`.
		public var stickPositions: [StickPosition] = [.top]
		
		/// If the drag recognizer is enabled, disable this to stop listening to drag events.
		public var isDraggingEnabled: Bool = true {
			didSet {
				gestureController.isEnabled = isDraggingEnabled
			}
		}
		
		private let gestureController = GestureController()
		
		public init(view: UIView) {
			
			_childView = view
			
			super.init(nibName: nil, bundle: nil)
			
			gestureController.parent = _viewController
			gestureController.options = options
			
			if #available(iOS 13.0, *) {
				self.isModalInPresentation = true
			}
			
			transitioningDelegate = self
			modalPresentationStyle = .custom
			modalPresentationCapturesStatusBarAppearance = true
		}
		
		@available(*, unavailable)
		public required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
		
		/// Stick to a certain stick position.
		///
		/// - Parameters:
		///   - position: The StickPosition to stick to, this should be in the `stickPositions` array.
		///   - animated: If the change should be animated.
		public func stick(to position: StickPosition, animated: Bool) {
			
			assert(stickPositions.contains(position))
			
			setStickPosition(position, animated: animated)
		}
		
		/// Set controller to 'closed' state, please note that you will still have to call dismiss().
		///
		/// - Parameter animated: If the change should be animated.
		public func close(animated: Bool) {
			setClosedPosition(animated: animated)
		}
		
		/// The implementation can ask for a new snapshot from the presenting controller, e.g. when presenting as a
		/// sheet and valuable information has changed. Returns `true`if we succeeded.
		@discardableResult
		public func askForSnapshot() -> Bool {
			
			if case let presenter as PresentationController = presentationController {
				return presenter.setSnapshotView()
			}
			
			return false
		}
		
		// MARK: - Stick Positions
		
		fileprivate typealias StickOption = (stickPosition: StickPosition, difference: CGFloat)
		
		fileprivate func topMostStickDelta() -> CGFloat {
			guard let view = cardView else {
				// Nothing to work with.
				return 0
			}
			
			let height = view.containerView.frame.height
			let top = view.safeAreaInsets.top + options.topPadding
			
			return _viewController.stickPositions.map {
				return $0.delta(for: height, top: top)
			}.sorted { lhs, rhs in
				return rhs > lhs
			}.first ?? 0.0
		}
		
		fileprivate func nearestStickOption(delta: CGFloat) -> StickOption? {
			guard let view = cardView else {
				// Nothing to work with.
				return nil
			}

			let height = view.containerView.frame.height
			let top = view.safeAreaInsets.top + options.topPadding
			
			let sorted = _viewController.stickPositions.map { pos -> StickOption in
				return (pos, pos.delta(for: height, top: top) - delta)
			}.sorted { (lhs, rhs) -> Bool in
				// Sort by nearest delta.
				return abs(lhs.difference) < abs(rhs.difference)
			}

			return sorted.first
		}
		
		fileprivate func nextStickOption(delta: CGFloat, isDraggingDown: Bool) -> StickOption? {
			guard let view = cardView else {
				// Nothing to work with.
				return nil
			}
			
			let height = view.containerView.frame.height
			let top = view.safeAreaInsets.top + options.topPadding
			
			let sorted = _viewController.stickPositions.map { pos -> StickOption in
				return (pos, pos.delta(for: height, top: top) - delta)
			}.filter { option in
				if isDraggingDown {
					return option.difference > 0
				}
				
				return option.difference <= 0
			}.sorted { (lhs, rhs) -> Bool in
				// Sort by nearest delta.
				return abs(lhs.difference) < abs(rhs.difference)
			}
			
			return sorted.first
		}
		
		fileprivate func setStickPosition(
			_ position: StickPosition,
			animated: Bool,
			alternativeHeight: CGFloat? = nil
		) {
			
			guard
				let view = cardView,
				case let presentation as PresentationController = presentationController
			else {
				// No view or presentation to transform, ingore.
				return
			}
			
			_viewController.cardModalWillDrag(_viewController, to: position)
			
			let height = alternativeHeight ?? view.containerView.frame.height
			let top = view.safeAreaInsets.top + options.topPadding
			
			let delta = position.delta(for: height, top: top)
			
			if animated {
				view.layoutIfNeeded()
				
				animate({
					presentation.setBackgroundAnimationValues(progress: 1 - delta)
					
					view.setDragPosition(y: height * delta)
					view.layoutIfNeeded()
				}, completion: { [weak self] in
					self?.currentPosition = position
				})
			} else {
				presentation.setBackgroundAnimationValues(progress: 1 - delta)
				view.setDragPosition(y: height * delta)

				currentPosition = position
			}
		}
		
		fileprivate func setClosedPosition(animated: Bool) {
			guard
				let view = cardView,
				case let presentation as PresentationController = presentationController
			else {
				// No view or presentation to transform, ingore.
				return
			}
			
			_viewController.cardModalWillDragToClose(_viewController)
			
			let height = view.containerView.frame.height
			
			if animated {
				view.layoutIfNeeded()
				
				animate({
					presentation.setBackgroundAnimationValues(progress: 0)
					
					view.setDragPosition(y: height)
					view.layoutIfNeeded()
				}, completion: { [weak self] in
					self?.currentPosition = nil
					
					if let controller = self?._viewController {
						controller.cardModalDidDragToClose(controller)
					}
				})
			} else {
				
				presentation.setBackgroundAnimationValues(progress: 0)
				
				view.setDragPosition(y: height)
				
				currentPosition = nil
				_viewController.cardModalDidDragToClose(_viewController)
			}
		}
		
		private func animate(_ block: @escaping () -> Void, completion: (() -> Void)? = nil) {
			
			UIView.animate(
				withDuration: options.animationDuration,
				delay: 0.005,
				usingSpringWithDamping: options.animationDamping,
				initialSpringVelocity: options.animationVelocity, options: [],
				animations: {
				
					block()
				
				}, completion: { done in
					
					if done {
						completion?()
					}
				}
			)
		}
		
		// MARK: - Actions
		
		@objc private func didPan(sender: UIPanGestureRecognizer) {
			gestureController.update(recognizer: sender)
		}
		
		@objc private func didScrollPan(sender: UIPanGestureRecognizer) {
			gestureController.capture(recognizer: sender, contentView: captureScrollViewContent)
		}
		
		@objc private func didTap(sender: UITapGestureRecognizer) {
			
			guard let cardView = cardView else {
				// We can ignore touches.
				return
			}
			
			let location = sender.location(in: view)
			let converted = cardView.convert(cardView.animationView.frame, from: view)
			let isInFrame = converted.contains(location)
			
			if !isInFrame {
				// If the touch is not inside the animationView, the user tapped outside.
				_viewController.cardModalDidTapOutside(_viewController)
			}
		}
		
		// MARK: - UIViewController
		
		open override var preferredStatusBarStyle: UIStatusBarStyle {
			return .lightContent
		}
		
		public override func loadView() {
			let cardView = CardView(view: _childView, options: options)
			cardView.panGestureRecognizer.addTarget(self, action: #selector(didPan(sender:)))
			cardView.tapGestureRecognizer.addTarget(self, action: #selector(didTap(sender:)))
			
			gestureController.view = cardView
			
			self.cardView = cardView
			self.view = cardView
		}
		
		// MARK: - UIViewControllerTransitioningDelegate
		
		public func animationController(
			forPresented presented: UIViewController,
			presenting: UIViewController,
			source: UIViewController) -> UIViewControllerAnimatedTransitioning?
		{
			return nil
		}
		
		public func animationController(
			forDismissed dismissed: UIViewController
		) -> UIViewControllerAnimatedTransitioning? {
			return nil
		}
		
		public func presentationController(
			forPresented presented: UIViewController,
			presenting: UIViewController?,
			source: UIViewController
		) -> UIPresentationController? {
			
			let presenter = PresentationController(
				parent: _viewController,
				presented: presented,
				presenting: presenting
			)
			
			gestureController.presenter = presenter
			
			return presenter
		}
	}
}

// MARK: - Presentation Controller

extension MMMCardModal {
	
	internal class PresentationController: UIPresentationController {
		
		// We treat our modal as modalPresentationStyle = .fullScreen.
		public override var shouldPresentInFullscreen: Bool { true }
		
		// We sadly can't remove the presenters view.
		public override var shouldRemovePresentersView: Bool { false }
		
		private lazy var wrapperView: UIView = {
			let view = UIView(frame: .zero)
			view.translatesAutoresizingMaskIntoConstraints = false
			return view
		}()
		
		private lazy var backgroundView: UIView = {
			let view = UIView(frame: .zero)
			view.translatesAutoresizingMaskIntoConstraints = false
			view.backgroundColor = .black
			return view
		}()
		
		private var snapshotView: UIView?
		private weak var parent: ViewController?
		
		internal weak var options: Options?
		
		private var isPresentingSubModal: Bool { presentingViewController is ViewController }
		private var didSnapshotSubModal = false
		
		private var isSubModalTransformed: Bool {
			
			guard didSnapshotSubModal else {
				//  No submodal snapshot, so not transformed.
				return false
			}
			
			guard
				case let controller as PresentationController = presentingViewController.presentationController,
				let snap = controller.snapshotView
			else {
				return false
			}
			
			// a represents the scaleX, if that's smaller than 1 we're talking transformation.
			return snap.transform.a < 1
		}
		
		public init(
			parent: ViewController,
			presented: UIViewController,
			presenting: UIViewController?
		) {
			
			self.options = parent.options
			self.parent = parent
			
			super.init(presentedViewController: presented, presenting: presenting)
		}
		
		deinit {
			snapshotTimer?.invalidate()
		}
		
		private func setupBackgroundViews() {
		
			containerView?.insertSubview(wrapperView, at: 0)
			containerView?.addFillConstraints(subview: wrapperView)
			
			wrapperView.addSubview(backgroundView)
			wrapperView.addFillConstraints(subview: backgroundView)
			
			setSnapshotView()
		}
		
		private var snapshotTimer: Timer?
		
		@discardableResult
		fileprivate func setSnapshotView() -> Bool {
			
			// Let's ignore a timer if one is available.
			snapshotTimer?.invalidate()
			snapshotTimer = nil
			
			let alpha: CGFloat
			let cornerRadius: CGFloat
			let transform: CGAffineTransform
			
			if let old = snapshotView {
				alpha = old.alpha
				cornerRadius = old.layer.cornerRadius
				transform = old.transform
				
				old.removeFromSuperview()
			} else {
				alpha = 1
				cornerRadius = 0
				transform = .identity
			}
			
			didSnapshotSubModal = false
			
			if
				let options = options,
				let view = options.alternativeSnapshotView
			{
			
				snapshotView = view.snapshotView(afterScreenUpdates: false)
				
			}
			else if
				isPresentingSubModal,
				case let presenting as ViewController = presentingViewController,
				case let presenter as PresentationController = presenting.presentationController
			{
				
				snapshotView = presenter.containerView?.snapshotView(afterScreenUpdates: false)
				didSnapshotSubModal = true
				
			}
			else
			{
				snapshotView = presentingViewController.view.snapshotView(afterScreenUpdates: false)
			}
			
			snapshotView?.translatesAutoresizingMaskIntoConstraints = false
			snapshotView?.layer.masksToBounds = true
			
			// Set previous values, if any.
			snapshotView?.layer.cornerRadius = cornerRadius
			snapshotView?.transform = transform
			snapshotView?.alpha = alpha
			
			// Check if we should schedule another call.
			
			let timeout: TimeInterval? = {
				switch options?.snapshotPolicy {
				case .lowPriority: return 5
				case .highPriority: return 1
				case .default, nil: return nil
				}
			}()
			
			if let interval = timeout {
				
				let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
					self?.setSnapshotView()
				}
				
				snapshotTimer = timer
				
				RunLoop.main.add(timer, forMode: .common)
			}
			
			if let view = snapshotView {
				wrapperView.addSubview(view)
				wrapperView.addFillConstraints(subview: view)
				
				return true
			}
			
			return false
		}
		
		// MARK: - UIPresentationController
		
		public override func presentationTransitionWillBegin() {
			
			setupBackgroundViews()
			
			// Presented height is not known, assume we're full screen, completion will fix any issues.
			let alternativeHeight = presentingViewController.view.frame.height
			
			presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
				
				guard let self = self else { return }
				guard let firstPosition = self.parent?.stickPositions.first else {
					preconditionFailure("You should supply at least 1 stickPosition")
				}
				
				self.parent?.setStickPosition(
					firstPosition,
					animated: false,
					alternativeHeight: alternativeHeight
				)
				self.presentedViewController.setNeedsStatusBarAppearanceUpdate()
				
			}, completion: { [weak self] _ in
				
				guard let position = self?.parent?.currentPosition else {
					return
				}
				
				// Set position again to make sure calculations are correct.
				self?.parent?.setStickPosition(position, animated: false)
			})
		}
		
		public override func dismissalTransitionWillBegin() {
			
			switch options?.snapshotPolicy {
			case .lowPriority, .highPriority:
				setSnapshotView()
			case .default, nil:
				break
			}
			
			presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
				
				guard let self = self else { return }
				
				self.parent?.setClosedPosition(animated: false)
				self.presentedViewController.setNeedsStatusBarAppearanceUpdate()
				
			}, completion: nil)
		}
		
		public override func viewWillTransition(
			to size: CGSize,
			with coordinator: UIViewControllerTransitionCoordinator
		) {

			super.viewWillTransition(to: size, with: coordinator)
			
			let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
			
			coordinator.animate(alongsideTransition: { [weak self] _ in
				
				guard let self = self else { return }
				
				self.snapshotView?.frame = frame
				self.backgroundView.frame = frame
				
				self.presentedViewController.view.frame = frame
			
			}, completion: { [weak self] _ in
				
				guard let self = self else { return }
				
				self.setSnapshotView()
				
				if let position = self.parent?.currentPosition {
					let animated = self.options?.animateAfterOrientationChange ?? false
					
					self.parent?.setStickPosition(position, animated: animated)
				}
			})
		}
		
		// MARK: - Animation
		
		fileprivate func setBackgroundAnimationValues(progress: CGFloat) {
			
			guard let options = options else {
				self.snapshotView?.alpha = 1
				self.snapshotView?.layer.cornerRadius = 0
				self.snapshotView?.transform = .identity
				
				return
			}
			
			if options.isFadeEffectEnabled {
				self.snapshotView?.alpha = 1 - options.animationAlpha.calculate(progress: progress)
			} else {
				self.snapshotView?.alpha = 1
			}
			
			if options.isScaleEffectEnabled {
				
				let scaleValue = options.animationScale.calculate(progress:  progress)
				let addSafeArea = options.animationTransformToSafeArea && !isSubModalTransformed
				
				let transformValue = options.animationTransform.calculate(
					progress: progress,
					baseline: addSafeArea ? presentingViewController.view.safeAreaInsets.top : 0
				)
				
				let scaleAdjustment = ((self.snapshotView?.frame.height ?? 0) * scaleValue) / 2
				
				// If we snapshotted a sub modal, let's add negative transform and ignore safeArea to
				// create a stacked effect.
				let finalTransform = -scaleAdjustment + (
					isSubModalTransformed ? -transformValue : transformValue
				)
				
				self.snapshotView?.layer.cornerRadius = options.animationCornerRadius.calculate(progress: progress)
				
				self.snapshotView?.transform = CGAffineTransform(
					translationX: 0,
					y: finalTransform
				).scaledBy(
					x: 1 - scaleValue,
					y: 1 - scaleValue
				)
			} else {
				self.snapshotView?.layer.cornerRadius = 0
				self.snapshotView?.transform = .identity
			}
		}
	}
}

// MARK: - Gesture Controller

extension MMMCardModal {
	
	fileprivate class GestureController {
		
		public weak var parent: ViewController?
		public weak var view: CardView?
		public weak var presenter: PresentationController?
		public weak var options: Options?
		
		public var isEnabled: Bool = true
		
		private var scrollObserver: NSKeyValueObservation?
		public weak var captureScrollView: UIScrollView? {
			didSet {
				scrollObserver?.invalidate()
				
				if let scrollView = captureScrollView {
					scrollObserver = scrollView.observe(\.contentOffset) { [weak self] (_, _) in
						self?.scrollViewDidScroll()
					}
				}
			}
		}
		public weak var captureScrollViewContent: UIView?
		
		private var startDragY: CGFloat = 0
		private var baseYPosition: CGFloat = 0
		private var previousDragY: CGFloat = 0
		private var isDraggingDown: Bool = true
		
		// MARK: - PanGestureRecognizer
		
		public func update(recognizer: UIPanGestureRecognizer) {
			switch recognizer.state {
			case .began:
				guard isEnabled else {
					return
				}
				
				begin(recognizer: recognizer)
			case .changed:
				guard isEnabled else {
					end(recognizer: recognizer)
					return
				}
				
				move(recognizer: recognizer)
			case .ended, .cancelled, .failed:
				end(recognizer: recognizer)
			case .possible:
				return
			@unknown default:
				fatalError()
			}
		}
		
		private var shouldTransform: Bool = false
		private var shouldCapture: Bool = true
		
		public func capture(recognizer: UIPanGestureRecognizer, contentView: UIView? = nil) {
			
			guard shouldCapture else {
				scrollViewDidScroll()
				return
			}
			
			switch recognizer.state {
			case .began:
				guard isEnabled else {
					return
				}
				
				shouldTransform = true
				
				begin(recognizer: recognizer)
			case .changed:
				guard isEnabled else {
					end(recognizer: recognizer, fromScrollView: true)
					return
				}
				
				shouldTransform = true
				
				move(recognizer: recognizer)
			case .ended, .cancelled, .failed:
				// Let's not check for isEnabled here so when disabling mid-drag we can bounce back.
				end(recognizer: recognizer, fromScrollView: true)
			case .possible:
				return
			@unknown default:
				fatalError()
			}
		}
		
		private var didResetPositionAfterScroll = false
		
		private func scrollViewDidScroll() {
			
			guard let scrollView = captureScrollView else {
				// Nothing to work with.
				return
			}
			
			if scrollView.panGestureRecognizer.state == .ended {
				shouldCapture = scrollView.contentOffset.y <= 0
			} else if scrollView.contentOffset.y > 0 {
				shouldCapture = false
			}
			
			guard shouldTransform else {
				scrollView.transform = .identity
				
				return
			}
			
			if scrollView.contentOffset.y <= 0 {
				captureScrollViewContent?.transform = .init(translationX: 0, y: scrollView.contentOffset.y)
				
				didResetPositionAfterScroll = false
			} else {
				shouldTransform = false
				captureScrollViewContent?.transform = .identity
				
				if !didResetPositionAfterScroll {
					end(recognizer: scrollView.panGestureRecognizer, fromScrollView: true)
					
					didResetPositionAfterScroll = true
				}
			}
		}
		
		private func begin(recognizer: UIPanGestureRecognizer) {
		
			guard let view = view, let parent = parent, let options = options else {
				// No view to work with, ignore.
				return
			}
			
			startDragY = recognizer.translation(in: view.containerView).y
			
			let height = view.containerView.frame.height
			let top = view.safeAreaInsets.top + options.topPadding
			
			if let delta = parent.currentPosition?.delta(for: height, top: top) {
				baseYPosition = height * delta
			} else {
				baseYPosition = view.currentYPosition
			}
		}
		
		private func move(recognizer: UIPanGestureRecognizer) {
		
			guard let view = view, let parent = parent, let presenter = presenter, let options = options else {
				// No view or presenter to work with, ignore.
				return
			}
			
			let dragY = recognizer.translation(in: view.containerView).y
			var topY = baseYPosition + dragY - startDragY
			
			let height = view.containerView.frame.height
			let topMost = parent.topMostStickDelta() * height
			
			if topY < topMost {
				// Max out at topPadding, slow down scrolling motion by dividing resistance.
				topY = topMost - min((topMost - topY) / options.dragResistance, options.topPadding)
			}
			
			isDraggingDown = topY > previousDragY
			previousDragY = topY
			
			view.setDragPosition(y: topY)
			view.layoutIfNeeded()
			
			let delta = topY / view.containerView.frame.height
			
			if let (stickPosition, _) = parent.nearestStickOption(delta: delta) {
				parent._viewController.cardModalIsDragging(
					parent._viewController,
					to: stickPosition,
					progress: delta
				)
			}
			
			presenter.setBackgroundAnimationValues(progress: 1 - delta)
		}
		
		fileprivate func end(recognizer: UIPanGestureRecognizer, fromScrollView: Bool = false) {
		
			guard let view = view, let parent = parent, let options = options else {
				// No view or presenter to work with, ignore.
				return
			}
			
			let delta = view.currentYPosition / view.containerView.frame.height
			var velocity = recognizer.velocity(in: view.containerView).y
			
			// ScrollViews have the tendency to give really high velocities. Divide by a constant.
			if fromScrollView {
				velocity /= options.captureScrollViewVelocityDivision
			}
			
			// Check for isEnabled explicitly because we only want ending to a nearest stick
			// position when false.
			
			if isEnabled, abs(velocity) >= options.dragVelocity {
				// Got a high velocity drag, let's determine the direction and get the
				// next stick position.
				if let (position, _) = parent.nextStickOption(delta: delta, isDraggingDown: isDraggingDown) {
					parent.setStickPosition(position, animated: true)
					
					return
				}
			}
			
			// Dragging down with high velocity, and no stick position is found above, let's close.
			if isEnabled, isDraggingDown, velocity >= options.closeVelocity {
				parent.setClosedPosition(animated: true)
				
				return
			}
			
			guard let (stickPosition, stickDifference) = parent.nearestStickOption(delta: delta) else {
				// No stick position provided. Animate to the current position or close.
				if let position = parent.currentPosition {
					parent.setStickPosition(position, animated: true)
					
					return
				}
				
				if isEnabled {
					parent.setClosedPosition(animated: true)
				}
				
				return
			}
			
			if stickDifference >= -0.5 {
				// Let's animate to the closest position.
				parent.setStickPosition(stickPosition, animated: true)
			} else if isEnabled {
				// Too far away, let's close.
				parent.setClosedPosition(animated: true)
			}
		}
	}
}
