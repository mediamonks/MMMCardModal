//
// MMMCardModal.
// Copyright (C) 2020 MediaMonks. All rights reserved.
//

import UIKit

extension MMMCardModal {
	
	/// Options for presenting the MMMCardModal.
	///
	/// Set custom options by modifying `self.options` after initializing. If you want to edit the options
	/// after the init call, you should override it with a new `MMMCardModal.Options` object.
	public class Options {
		
		public struct AnimationConstant {
		
			/// Start from value.
			public var from: CGFloat
			
			/// Animate to value.
			public var to: CGFloat
			
			/// Animation speed, defaults to 1. This is used as a multiplier.
			public var speed: CGFloat = 1
			
			/// Only start the animation after this threshold is met. From 0 to 1, defaults to 0. This is
			public var threshold: CGFloat = 0
			
			/// If the value should be clamped to max at `to`.
			public var clamp: Bool = true
			
			public init(from: CGFloat, to: CGFloat, speed: CGFloat = 1, threshold: CGFloat = 0, clamp: Bool = true) {
				self.from = from
				self.to = to
				self.speed = speed
				self.threshold = threshold
				self.clamp = clamp
			}
			
			public func calculate(progress: CGFloat, baseline: CGFloat = 0) -> CGFloat {
				guard progress > threshold else {
					return self.from
				}
			
				let to = (baseline + self.to)
				let value = map(value: progress - threshold, start1: 0, stop1: 1 - threshold, start2: from, stop2: to)
				
				return clamp ? max(min(to, value), self.from) : value
			}
			
			private func map(
				value: CGFloat,
				start1: CGFloat,
				stop1: CGFloat,
				start2: CGFloat,
				stop2: CGFloat
			) -> CGFloat {
				
				let end = (stop1 - start1)
				
				if end == 0 {
					// Avoid division by zero, return the 'min' value, start2.
					return start2
				}
				
				return start2 + (stop2 - start2) * ((value - start1) / end)
			}
		}
		
		public enum AnimationType {
			/// We use transforms to animate.
			case transform
			/// We animate the constraints, this resizes the CardView; your constraints should be ready for this.
			case constraints
		}
		
		public enum SnapshotPolicy {
			/// We only take a snapshot once, before presenting the modal, and one right before dismisssing.
			case `default`
			/// We take snapshots with low priority, this equals to every 5 seconds, and right before dismissing. Use
			/// this if you open as a sheet, and want to keep the background up-to-date, but the data shown isn't
			/// updated that often.
			case lowPriority
			/// We take snapshots with high priority, this equals to every second, and right befoire dismisssing. Use
			/// this if you open as a sheet, and the background changes a lot, with data you want to keep up-to-date.
			case highPriority
		}
		
		/// If the presenting viewController (snapshot thereof) should be scaled
		/// out (iOS 13+ style). Defaults to `true`.
		public var isScaleEffectEnabled: Bool = true
		
		/// If the presenting viewController (snapshot thereof) should be faded
		/// out. Defaults to `true`.
		public var isFadeEffectEnabled: Bool = true
		
		/// The amount of space from the top of the screen to the modal.
		public var topPadding: CGFloat = 16
		
		/// The background color behind the snapshot of the presenting viewController.
		public var backgroundColor: UIColor = .black
		
		/// The cornerRadius of the card where the presented viewController lives.
		public var cardCornerRadius: CGFloat = 12
		
		/// The backgroundColor of the card where the presented viewController lives.
		public var cardBackgroundColor: UIColor = .white
		
		/// The amount of velocity it takes to stick to the next `StickPosition`.
		public var dragVelocity: CGFloat = 500
		
		/// The amount of velocity it takes to close.
		public var closeVelocity: CGFloat = 850
		
		/// The amount to divide the velocity by when it comes from a captured scrollview, UIScrollViews have a tendency to pass
		/// really high velocities. Defaults to 2 (e.g. velocity will be divided by 2).
		public var captureScrollViewVelocityDivision: CGFloat = 2
		
		/// The resistance when the card is dragged up too far.
		public var dragResistance: CGFloat = 16
		
		/// The policy for updating the constraints, if your view has constraints set to the bottom layout guide this can cause unwanted
		/// behaviour. By default we don't update the top constraint, the view is only transformed.
		///
		/// **Options:**
		/// 	- `transform`; Only transform the view.
		///		- `constraints`; Only animate the top constraint, don't transform.
		public var animationType: AnimationType = .transform
		
		/// The duration of the complete animation, in seconds. Defaults to 0.5 seconds.
		public var animationDuration: TimeInterval = 0.5
		
		/// The damping applied to the animation spring, in seconds. Defaults to 0.7.
		public var animationDamping: CGFloat = 0.7
		
		/// The velocity of to the animation spring. Defaults to 0.7.
		public var animationVelocity: CGFloat = 0.7
		
		/// The maximum amount the presenting viewController will be faded out,
		/// only used when `isFadeEffectEnabled` is `true`.
		public var animationAlpha: AnimationConstant = .init(from: 0.0, to: 0.5)
		
		/// The maximum amount the presenting viewController will be scaled,
		/// only used when `isScaleEffectEnabled` is `true`.
		public var animationScale: AnimationConstant = .init(from: 0.0, to: 0.05)
		
		/// The maximum amount the presenting viewController will be transformed,
		/// so it's still visible, only used when `isScaleEffectEnabled` is `true`.
		public var animationTransform: AnimationConstant = .init(from: 0, to: 6)
		
		/// If the animationTransform should respect the safeArea.
		public var animationTransformToSafeArea: Bool = true
		
		/// The maximum amount of the cornerRadius applied to the presenting viewController,
		/// only used when `isScaleEffectEnabled` is `true`.
		public var animationCornerRadius: AnimationConstant = .init(from: 0, to: 12)
		
		/// If the modal should animate  back to it's stickPosition after an orientation change, or if this
		/// should happen directly.
		public var animateAfterOrientationChange: Bool = false
		
		/// Alternative view to take the snapshot from, e.g. for when the presenting viewController
		/// is not full screen.
		public var alternativeSnapshotView: UIView?
		
		/// How we should take snapshots. See documeentation in `SnapshotPolicy` for more info on each case.
		public var snapshotPolicy: SnapshotPolicy = .default
		
		/// Initialize with default values.
		public init() {}
		
		/// Initialize new `Options` object with a callback to set the required options.
		///
		/// **Usage:**
		/// ```
		/// .init {
		/// 	$0.backgroundColor = .red
		/// 	$0.cardCornerRadius = 25
		/// }
		/// ```
		///
		/// - Parameter block: Callback to set options
		public init(block: (Options) -> Void) {
			block(self)
		}
	}
}
