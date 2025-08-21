//
//  Utils.swift
//  active-speaker-ui-sample
//
//  Created by Dyte on 23/01/24.
//

import UIKit

class Utils {
    static func displayAlert(defaultActionTitle: String? = "OK", alertTitle: String, message: String) {
        let alertController = UIAlertController(title: alertTitle, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: defaultActionTitle, style: .default, handler: nil)
        alertController.addAction(defaultAction)

        guard let viewController = UIApplication.shared.windows.first?.rootViewController else {
            fatalError("keyWindow has no rootViewController")
        }

        viewController.present(alertController, animated: true, completion: nil)
    }
}

extension UIButton {
    func centerVertically(padding: CGFloat = 6.0) {
        guard
            let imageViewSize = imageView?.frame.size,
            let titleLabelSize = titleLabel?.frame.size
        else {
            return
        }

        let totalHeight = imageViewSize.height + titleLabelSize.height + padding

        imageEdgeInsets = UIEdgeInsets(
            top: -(totalHeight - imageViewSize.height),
            left: 0.0,
            bottom: 0.0,
            right: -titleLabelSize.width
        )

        titleEdgeInsets = UIEdgeInsets(
            top: 0.0,
            left: -imageViewSize.width,
            bottom: -(totalHeight - titleLabelSize.height),
            right: 0.0
        )

        contentEdgeInsets = UIEdgeInsets(
            top: 0.0,
            left: 0.0,
            bottom: titleLabelSize.height,
            right: 0.0
        )
    }
}

extension UIStackView {
    func addArrangedSubviews(_ views: UIView...) {
        for view in views {
            addArrangedSubview(view)
        }
    }

    func removeFully(view: UIView) {
        removeArrangedSubview(view)
        view.removeFromSuperview()
    }
}

private extension NSLayoutConstraint.Relation {
    func inverse() -> NSLayoutConstraint.Relation {
        switch self {
        case .equal:
            return .equal
        case .greaterThanOrEqual:
            return .lessThanOrEqual
        case .lessThanOrEqual:
            return .greaterThanOrEqual
        @unknown default:
            return self
        }
    }
}

public class ConstraintCreator: NSObject {
    let constraints: [Constraint]

    public init(constraints: [Constraint]) {
        self.constraints = constraints
    }

    // Public enum containing all possible cases for "Getting" the constraint
    public enum ConstraintType {
        case top
        case bottom
        case leading
        case trailing
        case width
        case height
        case centerX
        case centerY
        case aspectRatio
    }

    // Public enum containing all possible cases for constraints
    public enum Constraint {
        case equate(viewAttribute: NSLayoutConstraint.Attribute, toView: UIView, toViewAttribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation, constant: CGFloat, multiplier: CGFloat)

        case height(view: UIView?, relation: NSLayoutConstraint.Relation, constant: CGFloat, multiplier: CGFloat)

        case width(view: UIView?, relation: NSLayoutConstraint.Relation, constant: CGFloat, multiplier: CGFloat)

        case top(view: UIView, constant: CGFloat, relation: NSLayoutConstraint.Relation, multiplier: CGFloat)

        case bottom(view: UIView, constant: CGFloat, relation: NSLayoutConstraint.Relation, multiplier: CGFloat)

        case leading(view: UIView, constant: CGFloat, relation: NSLayoutConstraint.Relation, multiplier: CGFloat)

        case trailing(view: UIView, constant: CGFloat, relation: NSLayoutConstraint.Relation, multiplier: CGFloat)

        case before(view: UIView, constant: CGFloat, relation: NSLayoutConstraint.Relation, multiplier: CGFloat)

        case after(view: UIView, constant: CGFloat, relation: NSLayoutConstraint.Relation, multiplier: CGFloat)

        case above(view: UIView, constant: CGFloat, relation: NSLayoutConstraint.Relation, multiplier: CGFloat)

        case below(view: UIView, constant: CGFloat, relation: NSLayoutConstraint.Relation, multiplier: CGFloat)

        case centerX(view: UIView, constant: CGFloat, multiplier: CGFloat)

        case centerY(view: UIView, constant: CGFloat, multiplier: CGFloat)

        case aspectRatio(ratio: CGFloat)

        // A helper method which returns a NSLayoutConstraint on the basis of provided values
        func getConstraint(for view: UIView) -> NSLayoutConstraint {
            switch self {
            case let .equate(viewAttribute: viewAttribute, toView: toView, toViewAttribute: toViewAttribute, relation: relation, constant: constant, multiplier):
                return NSLayoutConstraint(item: view, attribute: viewAttribute, relatedBy: relation, toItem: toView, attribute: toViewAttribute, multiplier: multiplier, constant: constant)

            case let .height(view: toView, relation: relation, constant: constant, multiplier):
                return NSLayoutConstraint(item: view, attribute: .height, relatedBy: relation, toItem: nil, attribute: toView == nil ? .notAnAttribute : .height, multiplier: multiplier, constant: constant)

            case let .width(view: toView, relation: relation, constant: constant, multiplier):
                return NSLayoutConstraint(item: view, attribute: .width, relatedBy: relation, toItem: nil, attribute: toView == nil ? .notAnAttribute : .width, multiplier: multiplier, constant: constant)

            case let .top(view: toView, constant: constant, relation: relation, multiplier):
                return NSLayoutConstraint(item: view, attribute: .top, relatedBy: relation, toItem: toView, attribute: .top, multiplier: multiplier, constant: constant)

            case let .bottom(view: toView, constant: constant, relation: relation, multiplier):
                return NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: relation.inverse(), toItem: toView, attribute: .bottom, multiplier: multiplier, constant: -constant)

            case let .leading(view: toView, constant: constant, relation: relation, multiplier):
                return NSLayoutConstraint(item: view, attribute: .leading, relatedBy: relation, toItem: toView, attribute: .leading, multiplier: multiplier, constant: constant)

            case let .trailing(view: toView, constant: constant, relation: relation, multiplier):
                return NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: relation.inverse(), toItem: toView, attribute: .trailing, multiplier: multiplier, constant: -constant)

            case let .before(view: toView, constant: constant, relation: relation, multiplier):
                return NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: relation.inverse(), toItem: toView, attribute: .leading, multiplier: multiplier, constant: -constant)

            case let .above(view: toView, constant: constant, relation: relation, multiplier):
                return NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: relation.inverse(), toItem: toView, attribute: .top, multiplier: multiplier, constant: -constant)

            case let .after(view: toView, constant: constant, relation: relation, multiplier):
                return NSLayoutConstraint(item: view, attribute: .leading, relatedBy: relation, toItem: toView, attribute: .trailing, multiplier: multiplier, constant: constant)

            case let .below(view: toView, constant: constant, relation: relation, multiplier):
                return NSLayoutConstraint(item: view, attribute: .top, relatedBy: relation, toItem: toView, attribute: .bottom, multiplier: multiplier, constant: constant)

            case let .centerX(view: toView, constant: constant, multiplier):
                return NSLayoutConstraint(item: view, attribute: .centerX, relatedBy: .equal, toItem: toView, attribute: .centerX, multiplier: multiplier, constant: constant)

            case let .centerY(view: toView, constant: constant, multiplier):
                return NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: toView, attribute: .centerY, multiplier: multiplier, constant: constant)

            case let .aspectRatio(constant):
                return view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: constant)
            }
        }
    }

    // Use this method to equate constraints between any two attributes of two views
    ////Param - attibute - the attribute of main view
    ////Param - view - secondary view
    ////Param - toAttibute - the attribute of secondary view
    ////Param  - relation - the Layout constraint relation
    ////Param - constant - the height to be fixed
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func equateAttribute(_ attribute: NSLayoutConstraint.Attribute, toView view: UIView, toAttribute: NSLayoutConstraint.Attribute, withRelation relation: NSLayoutConstraint.Relation, _ constant: CGFloat = 0, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.equate(viewAttribute: attribute, toView: view, toViewAttribute: toAttribute, relation: relation, constant: constant, multiplier: multiplier)])
    }

    // Use this method to provide the height of the view
    ////Param - constant - the height to be fixed
    ////Param  - relation - the Layout constraint relation
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func height(_ constant: CGFloat, _ relation: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.height(view: nil, relation: relation, constant: constant, multiplier: multiplier)])
    }

    // Use this method to provide the width of the view
    ////Param - constant - the width to be fixed
    ////Param  - relation - the Layout constraint relation
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func width(_ constant: CGFloat, _ relation: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.width(view: nil, relation: relation, constant: constant, multiplier: multiplier)])
    }

    // Use this method to align top anchors of two views
    ////Param - view - the view to align top anchor with
    ////Param - constant - the constant to be applied while aligning views
    ////Param - relation - the Layout constraint relation
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func top(_ view: UIView, _ constant: CGFloat = 0, _ relation: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.top(view: view, constant: constant, relation: relation, multiplier: multiplier)])
    }

    // Use this method to align bottom anchors of two views
    ////Param - view - the view to align bottom anchor with
    ////Param - constant - the constant to be applied while aligning views
    ////Param - relation - the Layout constraint relation
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func bottom(_ view: UIView, _ constant: CGFloat = 0, _ relation: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.bottom(view: view, constant: constant, relation: relation, multiplier: multiplier)])
    }

    // Use this method to align leading anchors of two views
    ////Param - view - the view to align leading anchor with
    ////Param - constant - the constant to be applied while aligning views
    ////Param - relation - the Layout constraint relation
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func leading(_ view: UIView, _ constant: CGFloat = 0, _ relation: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.leading(view: view, constant: constant, relation: relation, multiplier: multiplier)])
    }

    // Use this method to align trailing anchors of two views
    ////Param - view - the view to align trailing anchor with
    ////Param - constant - the constant to be applied while aligning views
    ////Param - relation - the Layout constraint relation
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func trailing(_ view: UIView, _ constant: CGFloat = 0, _ relation: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.trailing(view: view, constant: constant, relation: relation, multiplier: multiplier)])
    }

    // Use this method to align the trailing and leading anchors of two views
    ////Param - view - the view to align trailing anchor with
    ////Param - constant - the constant to be applied while aligning views
    ////Param - relation - the Layout constraint relation
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func before(_ view: UIView, _ constant: CGFloat = 0, _ relation: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.before(view: view, constant: constant, relation: relation, multiplier: multiplier)])
    }

    // Use this method to align the leading and trailing anchors of two views
    ////Param - view - the view to align leading anchor with
    ////Param - constant - the constant to be applied while aligning views
    ////Param - relation - the Layout constraint relation
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func after(_ view: UIView, _ constant: CGFloat = 0, _ relation: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.after(view: view, constant: constant, relation: relation, multiplier: multiplier)])
    }

    // Use this method to align the bottom and top anchors of two views
    ////Param - view - the view to align bottom anchor with
    ////Param - constant - the constant to be applied while aligning views
    ////Param - relation - the Layout constraint relation
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func above(_ view: UIView, _ constant: CGFloat = 0, _ relation: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.above(view: view, constant: constant, relation: relation, multiplier: multiplier)])
    }

    // Use this method to align the top and bottom anchors of two views
    ////Param - view - the view to align top anchor with
    ////Param - constant - the constant to be applied while aligning views
    ////Param - relation - the Layout constraint relation
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func below(_ view: UIView, _ constant: CGFloat = 0, _ relation: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.below(view: view, constant: constant, relation: relation, multiplier: multiplier)])
    }

    // Use this method to align the centerX anchors of two views
    ////Param - view - the view to align center X anchor with
    ////Param - constant - the constant to be applied while aligning views
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func centerX(_ view: UIView, _ constant: CGFloat = 0, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.centerX(view: view, constant: constant, multiplier: multiplier)])
    }

    // Use this method to align the centerY anchors of two views
    ////Param - view - the view to align center Y anchor with
    ////Param - constant - the constant to be applied while aligning views
    ////Param - multiplier - multiplier for the constraint
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func centerY(_ view: UIView, _ constant: CGFloat = 0, _: UILayoutPriority = .required, _: NSLayoutConstraint.Relation = .equal, multiplier: CGFloat = 1) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.centerY(view: view, constant: constant, multiplier: multiplier)])
    }

    // Use this method to align the center anchors of two views
    ////Param - view - the view to align center anchors with
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func centerView(_ view: UIView) -> ConstraintCreator {
        return ConstraintCreator(constraints: ConstraintCreator.centerX(view).constraints + ConstraintCreator.centerY(view).constraints)
    }

    // Use this method to align the height and width anchors of a view
    ////Param - width - the constant to be applied while fixing width
    ////Param - height - the constant to be applied while fixing height
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func size(_ width: CGFloat, _ height: CGFloat) -> ConstraintCreator {
        return ConstraintCreator(constraints: ConstraintCreator.width(width).constraints + ConstraintCreator.height(height).constraints)
    }

    // Use this method to align the height and width anchors of a view
    ////Param - size - the constant to be applied while fixing size
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func size(_ size: CGSize) -> ConstraintCreator {
        return ConstraintCreator(constraints: ConstraintCreator.width(size.width).constraints + ConstraintCreator.height(size.height).constraints)
    }

    // Use this method to align the leading and trailing anchors of a view
    ////Param - view - the view to align leading and trailing anchors with
    ////Param - constant - the constant to be applied while aligning views
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func sameLeadingTrailing(_ view: UIView, _ constant: CGFloat = 0) -> ConstraintCreator {
        return ConstraintCreator(constraints: ConstraintCreator.leading(view, constant).constraints + ConstraintCreator.trailing(view, constant).constraints)
    }

    // Use this method to align the top and bottom anchors of a view
    ////Param - view - the view to align top and bottom anchors with
    ////Param - constant - the constant to be applied while aligning views
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func sameTopBottom(_ view: UIView, _ constant: CGFloat = 0, _ relation: NSLayoutConstraint.Relation = .equal) -> ConstraintCreator {
        return ConstraintCreator(constraints: ConstraintCreator.top(view, constant, relation).constraints + ConstraintCreator.bottom(view, constant, relation).constraints)
    }

    // Use this method to align the leading, trailing, top and bottom anchors of a view
    ////Param - view - the view to align all 4 anchors with
    ////Param - constant - the constant to be applied while aligning views
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func fillSuperView(_ view: UIView, _ top: CGFloat?, left: CGFloat?, bottom: CGFloat?, right: CGFloat?) -> ConstraintCreator {
        var constraints: [Constraint] = []

        if let leftInset = left {
            constraints += ConstraintCreator.leading(view, leftInset).constraints
        }

        if let bottomInset = bottom {
            constraints += ConstraintCreator.bottom(view, bottomInset).constraints
        }

        if let rightInset = right {
            constraints += ConstraintCreator.trailing(view, rightInset).constraints
        }

        if let topInset = top {
            constraints += ConstraintCreator.top(view, topInset).constraints
        }

        return ConstraintCreator(constraints: constraints)
    }

    // Use this method to align the leading, trailing, top and bottom anchors of a view
    ////Param - view - the view to align all 4 anchors with
    ////Param - constant - the constant to be applied while aligning views
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func fillSuperView(_ view: UIView, _ constant: CGFloat = 0) -> ConstraintCreator {
        return ConstraintCreator(constraints: ConstraintCreator.sameLeadingTrailing(view, constant).constraints + ConstraintCreator.sameTopBottom(view, constant).constraints)
    }

    // Use this create a ratio between width and height of the view
    ////Param - value - the ratio provided, will be taken as positive
    ////Returns - ConstraintCreator Object with suitable constraints
    public static func aspectRatio(_ value: CGFloat) -> ConstraintCreator {
        return ConstraintCreator(constraints: [Constraint.aspectRatio(ratio: abs(value))])
    }
}

public extension UIView {
    // A struct containing all keys for Objective-C runtime association
    enum AssociatedKeys {
        static var leadingConstraint = "leadingConstraint"
        static var trailingConstraint = "trailingConstraint"
        static var topConstraint = "topConstraint"
        static var bottomConstraint = "bottomConstraint"
        static var heightConstraint = "heightConstraint"
        static var widthConstraint = "widthConstraint"
        static var centerXConstraint = "centerXConstraint"
        static var centerYConstraint = "centerYConstraint"
        static var aspectRatioConstraint = "aspectRatioConstraint"
    }

    private static let constraintAssociation = ObjectAssociation<NSLayoutConstraint>()

    // The parameter for holding leading constraint on UIView
    private var leadingConstraint: NSLayoutConstraint? {
        get { return UIView.constraintAssociation.get(index: self, key: &AssociatedKeys.leadingConstraint) }
        set { UIView.constraintAssociation.set(index: self, key: &AssociatedKeys.leadingConstraint, newValue: newValue) }
    }

    // The parameter for holding trailing constraint on UIView
    private var trailingConstraint: NSLayoutConstraint? {
        get { return UIView.constraintAssociation.get(index: self, key: &AssociatedKeys.trailingConstraint) }
        set { UIView.constraintAssociation.set(index: self, key: &AssociatedKeys.trailingConstraint, newValue: newValue) }
    }

    // The parameter for holding top constraint on UIView
    private var topConstraint: NSLayoutConstraint? {
        get { return UIView.constraintAssociation.get(index: self, key: &AssociatedKeys.topConstraint) }
        set { UIView.constraintAssociation.set(index: self, key: &AssociatedKeys.topConstraint, newValue: newValue) }
    }

    // The parameter for holding bottom constraint on UIView
    private var bottomConstraint: NSLayoutConstraint? {
        get { return UIView.constraintAssociation.get(index: self, key: &AssociatedKeys.bottomConstraint) }
        set { UIView.constraintAssociation.set(index: self, key: &AssociatedKeys.bottomConstraint, newValue: newValue) }
    }

    // The parameter for holding height constraint on UIView
    private var heightConstraint: NSLayoutConstraint? {
        get { return UIView.constraintAssociation.get(index: self, key: &AssociatedKeys.heightConstraint) }
        set { UIView.constraintAssociation.set(index: self, key: &AssociatedKeys.heightConstraint, newValue: newValue) }
    }

    // The parameter for holding width constraint on UIView
    private var widthConstraint: NSLayoutConstraint? {
        get { return UIView.constraintAssociation.get(index: self, key: &AssociatedKeys.widthConstraint) }
        set { UIView.constraintAssociation.set(index: self, key: &AssociatedKeys.widthConstraint, newValue: newValue) }
    }

    // The parameter for holding centerX constraint on UIView
    private var centerXConstraint: NSLayoutConstraint? {
        get { return UIView.constraintAssociation.get(index: self, key: &AssociatedKeys.centerXConstraint) }
        set { UIView.constraintAssociation.set(index: self, key: &AssociatedKeys.centerXConstraint, newValue: newValue) }
    }

    // The parameter for holding centerY constraint on UIView
    private var centerYConstraint: NSLayoutConstraint? {
        get { return UIView.constraintAssociation.get(index: self, key: &AssociatedKeys.centerYConstraint) }
        set { UIView.constraintAssociation.set(index: self, key: &AssociatedKeys.centerYConstraint, newValue: newValue) }
    }

    // The parameter for holding aspect ratio constraint on UIView
    private var aspectRatioConstraint: NSLayoutConstraint? {
        get { return UIView.constraintAssociation.get(index: self, key: &AssociatedKeys.aspectRatioConstraint) }
        set { UIView.constraintAssociation.set(index: self, key: &AssociatedKeys.aspectRatioConstraint, newValue: newValue) }
    }
}

extension UIView {
    // MARK: - Public APIs

    // This function is used to add constraints to a view, and this in turn calls
    // another private function of the same name.
    ////Param - An array of "ConstraintCreator" objects
    func set(_ constraints: ConstraintCreator...) {
        for constraintCreator in constraints {
            let allConstraints = constraintCreator.constraints
            allConstraints.forEach { self.set($0) }
        }
    }

    // This function is used to get constraints of a view
    ////Param - A GetConstraint object
    ////Returns - An optional NSLayoutConstraint
    func get(_ constraint: ConstraintCreator.ConstraintType) -> NSLayoutConstraint? {
        switch constraint {
        case .top:
            return topConstraint
        case .bottom:
            return bottomConstraint
        case .leading:
            return leadingConstraint
        case .trailing:
            return trailingConstraint
        case .width:
            return widthConstraint
        case .height:
            return heightConstraint
        case .centerX:
            return centerXConstraint
        case .centerY:
            return centerYConstraint
        case .aspectRatio:
            return aspectRatioConstraint
        }
    }
}

private extension UIView {
    // MARK: - Private APIs

    // This function is used to add constraints to a view
    ////Param - A array of Constraint object
    private func set(_ constraint: ConstraintCreator.Constraint) {
        let nsLayoutConstraint = constraint.getConstraint(for: self)

        guard let view = nsLayoutConstraint.firstItem as? UIView else {
            assertionFailure("Constraint is not attached to a view. Please check")
            return
        }

        switch constraint {
        case .top:
            checkIfConstraintActiveAlready(topConstraint)
            topConstraint = nsLayoutConstraint

        case .leading:
            checkIfConstraintActiveAlready(leadingConstraint)
            leadingConstraint = nsLayoutConstraint

        case .height:
            checkIfConstraintActiveAlready(heightConstraint)
            heightConstraint = nsLayoutConstraint

        case .width:
            checkIfConstraintActiveAlready(widthConstraint)
            widthConstraint = nsLayoutConstraint

        case .bottom:
            checkIfConstraintActiveAlready(bottomConstraint)
            bottomConstraint = nsLayoutConstraint

        case .trailing:
            checkIfConstraintActiveAlready(trailingConstraint)
            trailingConstraint = nsLayoutConstraint

        case .before:
            checkIfConstraintActiveAlready(trailingConstraint)
            trailingConstraint = nsLayoutConstraint

        case .above:
            checkIfConstraintActiveAlready(bottomConstraint)
            bottomConstraint = nsLayoutConstraint

        case .after:
            checkIfConstraintActiveAlready(leadingConstraint)
            leadingConstraint = nsLayoutConstraint

        case .below:
            checkIfConstraintActiveAlready(topConstraint)
            topConstraint = nsLayoutConstraint

        case .centerX:
            checkIfConstraintActiveAlready(centerXConstraint)
            centerXConstraint = nsLayoutConstraint

        case .centerY:
            checkIfConstraintActiveAlready(centerYConstraint)
            centerYConstraint = nsLayoutConstraint

        case .aspectRatio:
            checkIfConstraintActiveAlready(aspectRatioConstraint)
            aspectRatioConstraint = nsLayoutConstraint

        case .equate:
            checkIfConstraintActiveAlready(nsLayoutConstraint)
        }

        view.translatesAutoresizingMaskIntoConstraints = false

        if validate(constraint: nsLayoutConstraint) {
            nsLayoutConstraint.isActive = true
        }
    }

    // This function checks if the constraint is already active or if repeated constraints
    // are being applied. If that is the case, it deactivates the previous one, and always
    // honors the latest one.
    ////Param - constraint - a NSLayoutConstraint to be validated
    private func checkIfConstraintActiveAlready(_ constraint: NSLayoutConstraint?) {
        if let unwrappedConstraint = constraint, constraint?.isActive == true {
            unwrappedConstraint.isActive = false
        }
    }

    // This function validates the constraint before activating it
    ////Param - The NSLayoutConstraint to be validated
    ////Returns - Whether to activate the constraint or not.
    private func validate(constraint: NSLayoutConstraint) -> Bool {
        if Thread.isMainThread == false {
            assertionFailure("This API can only be used from the main thread")
        }

        guard let _ = constraint.firstItem as? UIView else {
            assertionFailure("Constraint is not attached to a view. Please check")
            return false
        }

        return true
    }
}

// Helper class for getting and setting Objective-C runtime properties on objects.
// In this case object -> UIView and properties -> NSLayoutConstraint
final class ObjectAssociation<T: AnyObject> {
    private let policy: objc_AssociationPolicy

    /// - Parameter policy: An association policy that will be used when linking objects.
    init(policy: objc_AssociationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC) {
        self.policy = policy
    }

    /// Accesses associated object.
    /// - Parameter index: An object whose associated object is to be accessed.
    func get(index: AnyObject, key: inout String) -> T? {
        return objc_getAssociatedObject(index, &key) as! T?
    }

    func set(index: AnyObject, key: inout String, newValue: T?) {
        objc_setAssociatedObject(index, &key, newValue, policy)
    }
}

extension UIView {
    func wrapperView() -> UIView {
        let view = UIView()
        view.addSubview(self)
        return view
    }

    func blink() {
        alpha = 0.2
        UIView.animate(withDuration: 1, delay: 0.0, options: [.curveLinear, .repeat, .autoreverse], animations: { self.alpha = 1.0 }, completion: nil)
    }

    func stopBlink() {
        layer.removeAllAnimations()
    }

    func getSubviewsOf<T: UIView>(view: UIView) -> [T] {
        var subviews = [T]()

        for subview in view.subviews {
            subviews += getSubviewsOf(view: subview) as [T]

            if let subview = subview as? T {
                subviews.append(subview)
            }
        }

        return subviews
    }

    func addSubViews(_ views: UIView...) {
        for view in views {
            addSubview(view)
        }
    }

    func showActivityIndicator() {
        DispatchQueue.main.async {
            let container = UIView()
            container.frame = self.bounds // Set X and Y whatever you want
            container.tag = 11
            let activityView = UIActivityIndicatorView()
            activityView.tag = 12
            activityView.center = self.center
            container.addSubview(activityView)
            self.addSubview(container)
            activityView.startAnimating()
        }
    }

    func hideActivityIndicator() {
        DispatchQueue.main.async {
            if let activityView = self.viewWithTag(12) as? UIActivityIndicatorView, let container = self.viewWithTag(11) {
                activityView.stopAnimating()
                container.removeFromSuperview()
            }
        }
    }
}

protocol ConfigureView {
    associatedtype Model
    var model: Model { get }
    func configure(model: Model)
}

protocol ViewConfigurator {
    func configure(view: UIView)
}

protocol ReusableObject: AnyObject {}

extension ReusableObject {
    public static var reuseIdentifier: String {
        return String(describing: self)
    }
}

typealias TableViewCell = ConfigureView & ReusableObject & UITableViewCell

extension UITableView {
    func register<T: UITableViewCell>(_ cell: T.Type) where T: ReusableObject {
        register(cell.self, forCellReuseIdentifier: cell.reuseIdentifier)
    }
}

protocol KeyboardObservable: AnyObject {
    var keyboardObserver: KeyboardObserver? { get set }
    func startKeyboardObserving(onShow: @escaping (_ keyboardFrame: CGRect) -> Void,
                                onHide: @escaping () -> Void)
    func stopKeyboardObserving()
}

extension KeyboardObservable {
    public func startKeyboardObserving(onShow: @escaping (_ keyboardFrame: CGRect) -> Void,
                                       onHide: @escaping () -> Void)
    {
        keyboardObserver = KeyboardObserver(onShow: onShow, onHide: onHide)
    }

    public func stopKeyboardObserving() {
        keyboardObserver?.stopObserving()
        keyboardObserver = nil
    }
}

class KeyboardObserver {
    private var onShowHandler: ((_ keyboardFrame: CGRect) -> Void)?
    private var onHideHandler: (() -> Void)?

    init(onShow: @escaping (_ keyboardFrame: CGRect) -> Void, onHide: @escaping () -> Void) {
        onShowHandler = onShow
        onHideHandler = onHide
        startObserving()
    }

    private func startObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardWillShow(notification:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleKeyboardWillHide(notification:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc private func handleKeyboardWillShow(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        onShowHandler?(keyboardFrame)
    }

    @objc private func handleKeyboardWillHide(notification _: Notification) {
        onHideHandler?()
    }

    func stopObserving() {
        NotificationCenter.default.removeObserver(self)
        onShowHandler = nil
        onHideHandler = nil
    }
}
