//
//  DescriptionPresentationController.swift
//  Cantoboard
//
//  Created by Alex Man on 23/11/21.
//

import UIKit

class DescriptionPresentationController: UIPresentationController {
    lazy var backdropView: UIView = {
        let backdropView = UIView(frame: containerView!.frame)
        backdropView.backgroundColor = .systemFill.withAlphaComponent(0.2)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissPresentedViewController))
        tapGestureRecognizer.cancelsTouchesInView = false
        backdropView.addGestureRecognizer(tapGestureRecognizer)
        return backdropView
    }()
    
    override var frameOfPresentedViewInContainerView: CGRect {
        let bounds = containerView!.bounds
        let presentedController = (presentedViewController as! UINavigationController)
        let descriptionViewController = presentedViewController.children.first as! DescriptionViewController
        
        presentedController.view.layoutIfNeeded()
        
        var height = presentedController.view.safeAreaInsets.top +
            presentedController.navigationBar.bounds.height +
            DescriptionViewController.paddingBetweenTitleAndDescription +
            DescriptionViewController.stackViewInset.top +
            descriptionViewController.stackView.bounds.height +
            DescriptionViewController.stackViewInset.bottom +
            presentedController.view.safeAreaInsets.bottom
        
        height = min(height, containerView!.bounds.height)
        return CGRect(x: 0, y: bounds.height - height, width: bounds.width, height: height)
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        backdropView.alpha = 0
        containerView!.addSubview(backdropView)
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in self.backdropView.alpha = 1 })
    }
    
    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        
        backdropView.alpha = 1
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in self.backdropView.alpha = 0 }) { _ in
            self.backdropView.removeFromSuperview()
        }
    }
    
    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
        backdropView.frame = containerView!.frame
    }
    
    @objc func dismissPresentedViewController() {
        presentedViewController.dismiss(animated: true, completion: nil)
    }
}
