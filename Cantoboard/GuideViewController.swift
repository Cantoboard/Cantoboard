//
//  IntroductionViewController.swift
//  Cantoboard
//
//  Created by Alex Man on 5/27/21.
//

import Foundation
import UIKit
import WebKit

class GuideViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = URLRequest(url: Bundle.main.url(forResource: "Guide", withExtension: "html")!)
        webView.navigationDelegate = self
        webView.load(request)
    }
}

extension GuideViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.navigationType == .linkActivated,
              let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        UIApplication.shared.open(url)
        decisionHandler(.cancel)
    }
}
