//
// MMMCardModal.
// Copyright (C) 2020 MediaMonks. All rights reserved.
//

import UIKit
import MMMCardModal

fileprivate extension UIScreen {

    private static let cornerRadiusKey: String = {
        let components = ["Radius", "Corner", "display", "_"]
        return components.reversed().joined()
    }()

    /// The corner radius of the display. Uses a private property of `UIScreen`,
    /// and may report 0 if the API changes.
    var displayCornerRadius: CGFloat {
        guard let cornerRadius = self.value(forKey: Self.cornerRadiusKey) as? CGFloat else {
            return 0
        }

        return cornerRadius
    }
}

class ViewController: UIViewController {

	private let stackView = UIStackView(frame: .zero)

	override func viewDidLoad() {
		super.viewDidLoad()
		
		stackView.translatesAutoresizingMaskIntoConstraints = false
		stackView.alignment = .fill
		stackView.axis = .vertical
		stackView.distribution = .fillEqually
		
		view.addSubview(stackView)
		
		NSLayoutConstraint.activate([
			view.topAnchor.constraint(equalTo: stackView.topAnchor),
			view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
			view.leftAnchor.constraint(equalTo: stackView.leftAnchor),
			view.rightAnchor.constraint(equalTo: stackView.rightAnchor)
		])
		
		let buttonBasic = button(title: "Basic example", color: .systemTeal)
		buttonBasic.addTarget(self, action: #selector(hitBasic), for: .touchUpInside)
		
		let buttonMultiple = button(title: "Multiple stick positions, open modal-in-modal", color: .systemIndigo)
		buttonMultiple.addTarget(self, action: #selector(hitMultiple), for: .touchUpInside)
		
		let buttonCustom = button(title: "Custom animation parameters with 3 stick positions", color: .systemOrange)
		buttonCustom.addTarget(self, action: #selector(hitCustom), for: .touchUpInside)
		
		let buttonDisabledSwipe = button(title: "Disabled swipe with programmatic position changes", color: .systemRed)
		buttonDisabledSwipe.addTarget(self, action: #selector(hitDisabledSwipe), for: .touchUpInside)
		
		let buttonNavigation = button(title: "Usage with navigation", color: .systemYellow)
		buttonNavigation.addTarget(self, action: #selector(hitNavigation), for: .touchUpInside)
		
		let buttonScrollView = button(title: "Tracking UIScrollView", color: .systemBlue)
		buttonScrollView.addTarget(self, action: #selector(hitScrollView), for: .touchUpInside)
		
		stackView.addArrangedSubview(buttonBasic)
		stackView.addArrangedSubview(buttonMultiple)
		stackView.addArrangedSubview(buttonCustom)
		stackView.addArrangedSubview(buttonDisabledSwipe)
		stackView.addArrangedSubview(buttonNavigation)
		stackView.addArrangedSubview(buttonScrollView)
	}
	
	private func button(title: String, color: UIColor) -> UIButton {
		let button = UIButton(type: .system)
		button.setTitle(title, for: .normal)
		button.setTitleColor(.white, for: .normal)
		button.backgroundColor = color
		button.titleLabel?.numberOfLines = 0
		button.titleLabel?.textAlignment = .center
		button.titleLabel?.widthAnchor.constraint(lessThanOrEqualToConstant: 300).isActive = true
		
		return button
	}
	
	@objc private func hitBasic() {
	
		let vc = ExampleViewController(text: "Only top stick position", color: .systemTeal)
		
		present(vc, animated: true) {
			print("Presented!")
		}
	}
	
	private var multipleVC: ExampleViewController?
	
	@objc private func hitMultiple() {
		
		let vc = ExampleViewController(
			text: "Top and center stick, opens on top; animates constraints.",
			color: .systemIndigo,
			positions: [.top, .center],
			addSubButton: true
		)
		
		vc.options.animationType = .constraints
		vc.options.snapshotPolicy = .highPriority
		vc._view.subButton.addTarget(self, action: #selector(hitMultipleChild), for: .touchUpInside)
		
		present(vc, animated: true) {
			print("Presented!")
		}
		
		multipleVC = vc
	}
	
	@objc private func hitMultipleChild() {
	
		guard let parent = multipleVC else {
			fatalError()
		}
		
		let vc = ExampleViewController(
			text: "Modal presented by modal, e.g. layered modals.",
			color: .systemOrange,
			positions: [.top, .center],
			addSubButton: true
		)
		
		vc.options.animationType = .constraints
		vc._view.subButton.addTarget(self, action: #selector(hitMultipleChild), for: .touchUpInside)
		
		parent.present(vc, animated: true)
		
		multipleVC = vc
	}
	
	@objc private func hitCustom() {
		
		let vc = ExampleViewController(
			text: "Center and 1/3rd, opens on center. Adjusts constrainst, doesn't animate scale.",
			color: .systemOrange,
			positions: [.center, .percentage(0.3)]
		)
		
		vc.options.animationType = .constraints
		vc.options.isScaleEffectEnabled = false
		
		present(vc, animated: true) {
			print("Presented!")
		}
	}
	
	@objc private func hitNavigation() {
		
		let vc = ChildViewController(text: "With navigationController", number: 0)
		
		let nav = NavigationController(rootViewController: vc)
		nav.isNavigationBarHidden = false
		
		let host = MMMCardModal.NavigationHost(controller: nav)
		host.stickPositions = [.top, .center]
		host.options.cardBackgroundColor = .systemYellow
		
		present(host, animated: true) {
			print("Presented!")
		}
	}
	
	@objc private func hitScrollView() {
		
		let vc = ScrollViewController(
			text: "Scroll stuff!",
			color: .systemBlue
		)
		
		present(vc, animated: true) {
			print("Presented!")
		}
	}
	
	@objc private func hitDisabledSwipe() {
		
		let vc = DisabledSwipeViewController()
		
		present(vc, animated: true) {
			print("Presented!")
		}
	}

}

/// All these example controllers are a quick draft, you want better data & view management etc.
class ExampleViewController: MMMCardModal.ViewController {
	
	class View: UIView {
		
		public let label = UILabel()
		public let close = UIButton(type: .close)
		public let subButton = UIButton(type: .detailDisclosure)
		
		init(text: String, color: UIColor, addSubButton: Bool) {
			super.init(frame: .zero)
			
			backgroundColor = color
			
			label.translatesAutoresizingMaskIntoConstraints = false
			label.text = text
			label.textAlignment = .center
			label.numberOfLines = 0
			label.setContentCompressionResistancePriority(.required, for: .vertical)
			addSubview(label)
			
			close.translatesAutoresizingMaskIntoConstraints = false
			close.setContentCompressionResistancePriority(.required, for: .vertical)
			addSubview(close)
			
			if addSubButton {
				addSubview(subButton)
				
				subButton.translatesAutoresizingMaskIntoConstraints = false
				subButton.tintColor = .white
				subButton.setContentCompressionResistancePriority(.required, for: .vertical)
				
				label.bottomAnchor.constraint(greaterThanOrEqualTo: subButton.topAnchor, constant: 20).isActive = true
				close.topAnchor.constraint(greaterThanOrEqualTo: subButton.bottomAnchor, constant: 20).isActive = true
				centerYAnchor.constraint(equalTo: subButton.centerYAnchor).isActive = true
				centerXAnchor.constraint(equalTo: subButton.centerXAnchor).isActive = true
			}
			
			let views = ["label": label, "close": close]
			
			NSLayoutConstraint.activate(
				NSLayoutConstraint.constraints(
					withVisualFormat: "H:|-[label]-|",
					options: [], metrics: nil, views: views
				)
			)
			
			NSLayoutConstraint.activate(
				NSLayoutConstraint.constraints(
					withVisualFormat: "V:|-20-[label]-(>=20)-[close]",
					options: [], metrics: nil, views: views
				)
			)
			
			NSLayoutConstraint.activate([
				centerXAnchor.constraint(equalTo: close.centerXAnchor),
				safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: close.bottomAnchor, constant: 20)
			])
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}
	
	// A fast example, you want better data flow than this.
	
	public let _view: View
	
	init(
		text: String,
		color: UIColor,
		positions: [MMMCardModal.StickPosition] = [.top],
		addSubButton: Bool = false
	) {
		_view = View(text: text, color: color, addSubButton: addSubButton)
		
		super.init(view: _view)
		
		self.stickPositions = positions
		self.options = .init {
			$0.cardBackgroundColor = color
			$0.animationCornerRadius = .init(from: UIScreen.main.displayCornerRadius, to: 12, clamp: false)
		}
		
		_view.close.addTarget(self, action: #selector(hitClose), for: .touchUpInside)
	}
	
	@objc private func hitClose() {
		dismiss(animated: true, completion: nil)
	}
}

class DisabledSwipeViewController: MMMCardModal.ViewController {
	
	class View: UIView {
		
		public let topButton = UIButton(type: .system)
		public let centerButton = UIButton(type: .system)
		public let bottomButton = UIButton(type: .system)
		public let closeButton = UIButton(type: .close)
		
		private let stackView = UIStackView()
		
		init() {
			super.init(frame: .zero)
			
			backgroundColor = .systemRed
			tintColor = .white
			
			stackView.translatesAutoresizingMaskIntoConstraints = false
			stackView.alignment = .center
			stackView.axis = .horizontal
			stackView.distribution = .fillEqually
			addSubview(stackView)
			
			topButton.setTitle("Top", for: .normal)
			stackView.addArrangedSubview(topButton)
			
			centerButton.setTitle("Center", for: .normal)
			stackView.addArrangedSubview(centerButton)
			
			bottomButton.setTitle("Bottom", for: .normal)
			stackView.addArrangedSubview(bottomButton)
			
			closeButton.translatesAutoresizingMaskIntoConstraints = false
			addSubview(closeButton)
			
			let views = [
				"stackView": stackView,
				"closeButton": closeButton
			]
			
			NSLayoutConstraint.activate(
				NSLayoutConstraint.constraints(
					withVisualFormat: "H:|-[stackView]-|",
					options: [], metrics: nil, views: views
				)
			)
			
			NSLayoutConstraint.activate(
				NSLayoutConstraint.constraints(
					withVisualFormat: "V:|-20-[stackView]-(>=20)-[closeButton]",
					options: [], metrics: nil, views: views
				)
			)
			
			NSLayoutConstraint.activate([
				centerXAnchor.constraint(equalTo: closeButton.centerXAnchor),
				safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 20)
			])
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}

	init() {
		let view = View()
		
		super.init(view: view)
		
		self.isDraggingEnabled = false
		self.stickPositions = [.percentage(0.7), .percentage(0.35), .top]
		self.options = .init {
			$0.cardBackgroundColor = .systemRed
			
			// To keep the close button at the bottom at all times
			$0.animationType = .constraints
			
			// Higher speed (3.5x as fast) to max out on 0.35% stick pos.
			$0.animationCornerRadius = .init(
				from: UIScreen.main.displayCornerRadius,
				to: 12,
				speed: 3.5,
				threshold: 0.35,
				clamp: false
			)
			$0.animationScale = .init(from: 0.0, to: 0.05, speed: 3.5, threshold: 0.35)
			$0.animationTransform = .init(from: 0, to: 6, speed: 3.5, threshold: 0.35)
			$0.animationAlpha = .init(from: 0.0, to: 0.5, speed: 3.5)
		}
		
		view.topButton.addTarget(self, action: #selector(hitTop), for: .touchUpInside)
		view.centerButton.addTarget(self, action: #selector(hitCenter), for: .touchUpInside)
		view.bottomButton.addTarget(self, action: #selector(hitBottom), for: .touchUpInside)
		view.closeButton.addTarget(self, action: #selector(hitClose), for: .touchUpInside)
	}
	
	@objc private func hitTop() {
		stick(to: .top, animated: true)
	}
	
	@objc private func hitCenter() {
		stick(to: .percentage(0.35), animated: true)
	}
	
	@objc private func hitBottom() {
		stick(to: .percentage(0.7), animated: true)
	}
	
	@objc private func hitClose() {
		dismiss(animated: true, completion: nil)
	}
}

class NavigationController: UINavigationController, UINavigationControllerDelegate, MMMCardModal.NavigationController {
	
	var viewControllerDidChange: (() -> Void)?
	var isDraggingEnabledDidChange: (() -> Void)?
	
	override init(rootViewController: UIViewController) {
		super.init(rootViewController: rootViewController)
		
		delegate = self
	}
	
	@available(*, unavailable)
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
		viewControllerDidChange?()
	}
}

class ChildViewController: UIViewController, MMMCardModal.ChildControllerDelegate {
	
	weak var navigationHost: MMMCardModal.NavigationHost? {
		didSet {
			// NavigationHost is by nature set after viewDidLoad, call this later.
			update()
		}
	}
	
	private let text: String
	private let number: Int
	
	private let colors: [UIColor] = [.systemYellow, .systemRed, .systemBlue, .systemPink, .systemTeal]
	
	private var color: UIColor {
		colors[number % colors.count]
	}
	
	init(text: String, number: Int) {
		self.text = text
		self.number = number
		
		super.init(nibName: nil, bundle: nil)
		
		self.title = "VC \(number)"
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func loadView() {
		// Stealing a view, don't do this.
		self.view = ExampleViewController.View(text: text, color: color, addSubButton: true)
	}
	
	override func viewDidLoad() {
		guard case let view as ExampleViewController.View = view else { return }
		
		view.close.addTarget(self, action: #selector(hitClose), for: .touchUpInside)
		view.subButton.addTarget(self, action: #selector(hitSub), for: .touchUpInside)
		
		navigationItem.leftBarButtonItem = .init(title: "Close", style: .done, target: self, action: #selector(hitClose))
		navigationItem.rightBarButtonItem = .init(title: "Next", style: .plain, target: self, action: #selector(hitPush))
	}
	
	@objc private func hitClose() {
		navigationHost?.dismiss(animated: true, completion: nil)
	}
	
	@objc private func hitSub() {
		navigationHost?.present(ExampleViewController(text: "Sub controller!", color: .systemGray), animated: true)
	}
	
	@objc private func hitPush() {
		let vc = ChildViewController(text: text, number: number + 1)
		
		navigationController?.pushViewController(vc, animated: true)
	}
	
	private func update() {
		// Set the card background to the current VC color.
		navigationHost?.options.cardBackgroundColor = color
		navigationHost?.options.animationCornerRadius = .init(from: UIScreen.main.displayCornerRadius, to: 12, clamp: false)
	}
}

class ScrollViewController: MMMCardModal.ViewController {
	
	class View: UIView {
		
		public let scrollView = UIScrollView(frame: .zero)
		public let contentView = UIView(frame: .zero)
		
		private let label = UILabel()
		public let close = UIButton(type: .close)
		
		init(text: String, color: UIColor) {
			super.init(frame: .zero)
			
			backgroundColor = color
			
			scrollView.translatesAutoresizingMaskIntoConstraints = false
			addSubview(scrollView)
			
			contentView.translatesAutoresizingMaskIntoConstraints = false
			scrollView.addSubview(contentView)
			
			label.translatesAutoresizingMaskIntoConstraints = false
			label.text = text
			label.textAlignment = .center
			label.numberOfLines = 0
			contentView.addSubview(label)
			
			close.translatesAutoresizingMaskIntoConstraints = false
			addSubview(close)
			
			let views = ["contentView": contentView, "label": label, "close": close]
			
			NSLayoutConstraint.activate(
				NSLayoutConstraint.constraints(
					withVisualFormat: "H:|-[contentView]-|",
					options: [], metrics: nil, views: views
				) + NSLayoutConstraint.constraints(
					withVisualFormat: "H:|-[label]-|",
					options: [], metrics: nil, views: views
				)
			)
			
			NSLayoutConstraint.activate(
				NSLayoutConstraint.constraints(
					withVisualFormat: "V:|-20-[label]-(>=20)-[close]",
					options: [], metrics: nil, views: views
				) + NSLayoutConstraint.constraints(
					withVisualFormat: "V:|-[contentView(2000)]-|",
					options: [], metrics: nil, views: views
				)
			)
			
			NSLayoutConstraint.activate([
				centerXAnchor.constraint(equalTo: close.centerXAnchor),
				safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: close.bottomAnchor, constant: 20),
				topAnchor.constraint(equalTo: scrollView.topAnchor, constant: .zero),
				bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: .zero),
				leftAnchor.constraint(equalTo: scrollView.leftAnchor, constant: .zero),
				rightAnchor.constraint(equalTo: scrollView.rightAnchor, constant: .zero)
			])
		}
		
		@available(*, unavailable)
		required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}
	}

	// A fast example, you want better data flow than this.
	init(
		text: String,
		color: UIColor,
		positions: [MMMCardModal.StickPosition] = [.top]
	) {
		let view = View(text: text, color: color)
		
		super.init(view: view)
		
		self.stickPositions = positions
		self.options = .init {
			$0.cardBackgroundColor = color
			$0.animationCornerRadius = .init(from: UIScreen.main.displayCornerRadius, to: 12, clamp: false)
		}
		
		view.close.addTarget(self, action: #selector(hitClose), for: .touchUpInside)
		
		captureScrollView = view.scrollView
		captureScrollViewContent = view.contentView
	}
	
	@objc private func hitClose() {
		dismiss(animated: true, completion: nil)
	}
}
