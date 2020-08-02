//
//  WebViewController.swift
//  MiniprogramExample
//
//  Created by 欧阳鑫 on 2019/12/4.
//  Copyright © 2019 欧阳鑫. All rights reserved.
//

import UIKit
import WebKit

// setData 通知原生，再通知 webview 的 setData

class WebViewController: UIViewController {
    
    static func createWebview(appId: String, webviewId: Int) -> WebViewController {
        let webviewController = WebViewController(appId: appId, webviewId: webviewId)
        return webviewController
    }
    
    var webview: WKWebView?
    
    // Vue 实例是否已经初始化完成
    var isReady: Bool = false
    
    // appId 用于 webview 调用原生时找到对应的 MiniprogranController
    let appId: String
    
    // webviewId 用于对应的 JSContext 找到对应的 PageController
    let webviewId: Int
    
    // ready 以前把脚本记录
    var scripts: [String] = []
    
    var htmlContent = ""
    
    init(appId: String, webviewId: Int) {
        self.appId = appId
        self.webviewId = webviewId
        logger.info("🧲 init")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setTitlebar()
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let controller = WKUserContentController()
        controller.add(self, name: "trigger")
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.userContentController = controller
        
        webview = WKWebView(frame: view.bounds, configuration: configuration)
        webview!.uiDelegate = self
        webview!.navigationDelegate = self
        view.addSubview(webview!)
        logger.info("🧲 didload")
        
        if !htmlContent.isEmpty {
            webview!.loadHTMLString(htmlContent, baseURL: URL(string: "http://localhost"))
        }
    }
    
    deinit {
        webview?.configuration.userContentController.removeScriptMessageHandler(forName: "trigger")
    }
    
    
    private func run(script: String) {
        webview?.evaluateJavaScript(script) { (data, error) in
            if (error != nil) {
                logger.error(error)
            }
        }
    }
    
    public func load(pagePath: String) {
        var error: Error?
        let htmlContent = ReaderController.shared.readFilecontent(appId: appId, filename: pagePath.appending("/index.html"), error: &error)
        if error != nil {
            logger.error(error)
            return
        }
        logger.info("🧲 load")
        guard let wview = webview else {
            self.htmlContent = htmlContent
            return
        }
        
        wview.loadHTMLString(htmlContent, baseURL: URL(string: "http://localhost"))
    }
    
    public func setData(data: String) {
        let script = "window.__setData(\(data))"
        if !isReady {
            scripts.append(script)
            return
        }
        
        run(script: script)
    }
    
    public func ready() {
        self.isReady = true
        self.scripts.forEach { (script) in
            self.run(script: script)
        }
    }
}

extension WebViewController: WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate  {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "trigger":
            let option = WebviewInvokeNativeOption(JSONString: message.body as? String ?? "")
            option?.invoke(target: self)
        default: break
            //                assertionFailure("Received invalid message: \(message.name)")
        }
    }
    
}
