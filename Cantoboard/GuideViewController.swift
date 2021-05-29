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
        
        let request = URLRequest(url: Bundle.main.url(forResource: "Guide/Guide", withExtension: "html")!)
        webView.navigationDelegate = self
        webView.configuration.suppressesIncrementalRendering = true
        webView.load(request)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Restart all mp4 playbacks.
        webView.evaluateJavaScript("""
            var images = document.images;
            for (var i=0; i<images.length; i++) {
                images[i].src = images[i].src + "?" + new Date().getTime();
            }
            """, completionHandler: nil)
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

class TabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers?.forEach({ _ = $0.view })
    }
}
