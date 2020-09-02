//
//  A short exmaple of displaying Mappedin Web in a WebView.
//
//  Copyright © 2019 Mappedin. All rights reserved.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    
    @IBOutlet var webView: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        view = webView
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Setup WebView with local html file. Another option is to use an external url and load it here.

        To get you started we've provided a Mappedin key and secret that has access to some demo venues.
         
        When you're ready to start using your own venues you will need to contact a Mappedin representative
        to get your own unique key and secret. Add your Mappedin api keys, search keys, and the venue's
        slug to this file.

         */
        if let url = Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "Website") {
            webView.loadFileURL(url, allowingReadAccessTo: url)
            let myRequest = URLRequest(url: url)
            webView.load(myRequest)
        } else {
            print("Website files not found")
        }
        
        
    }
    
    //Setup in order to open certain links in an external browser
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            /*
             Logic to decide which urls will be loaded in an external browser.
             Because we are loading from a local file, any url starting with http would be external websites
             Urls starting with tel should be opened on the browser as well, which should trigger the phone app to be opened
             */
            if url.absoluteString.hasPrefix("http") || url.absoluteString.hasPrefix("tel") {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }
}

