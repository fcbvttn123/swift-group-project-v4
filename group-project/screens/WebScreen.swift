//
//  WebViewController.swift
//  Assignment1-IOS
//
//  Created by fizza imran on 2024-02-01.
//

import UIKit
import WebKit

class WebScreen: UIViewController, WKNavigationDelegate {
    
    @IBOutlet var webView  : WKWebView!
    @IBOutlet var activity: UIActivityIndicatorView!
    var urlString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the URL in the web view
        if let urlString = urlString, let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        } else {
            // Handle error when URL string is nil or invalid
            print("Error: Invalid URL string")
        }

        webView.navigationDelegate = self
        
    }
    
    // This Fuction is called when navigation starts
    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        activity.isHidden = false
        activity.startAnimating()
    }
    
    // This Function is called when navigation finishes
    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        activity.isHidden = true
        activity.stopAnimating()
    }
    
}


