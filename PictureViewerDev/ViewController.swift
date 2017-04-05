//
//  ViewController.swift
//  PictureViewerDev
//
//  Created by qifx on 24/03/2017.
//  Copyright © 2017 Manfred. All rights reserved.
//

import UIKit
import PictureViewer
import Alamofire

class ViewController: UIViewController, PictureViewerDelegate {

    var dic = Dictionary<Int, SourceItem>()
    var vc: PictureViewerController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let videoPath = Bundle.main.path(forResource: "1", ofType: "mov")
        let remoteURL = URL.init(string: "http://10.0.40.94:8080/test.mp4")
        let picturePath = Bundle.main.path(forResource: "1", ofType: "jpg")
        let pictureData = try! Data.init(contentsOf: URL(fileURLWithPath: picturePath!))
        for i in 0...9 {
            if i % 3 == 0 {
                let si = SourceItem(id: "\(i)", type: "image", localUrl: nil, remoteUrl: nil, data: pictureData)
                dic[i] = si
            } else if i % 3 == 1 {
                let si = SourceItem(id: "\(i)", type: "video", localUrl: URL.init(fileURLWithPath: videoPath!), remoteUrl: nil, data: nil)
                dic[i] = si
            } else {
                let si = SourceItem(id: "\(i)", type: "video", localUrl: nil, remoteUrl: remoteURL, data: nil)
                dic[i] = si
            }
        }
        vc = PictureViewerController(fileDic: dic, currentFileIndex: 0)
        vc!.pictureViewerDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        present(vc!, animated: true, completion: nil)
    }

    func needDownloadSource(index: Int, item: SourceItem, downloadProgressNotificationName: Notification.Name, downloadEndNotificationName: Notification.Name, downloadErrorNotificationName: Notification.Name) {
        Alamofire.request(item.remoteUrl!).downloadProgress(closure: { (p: Progress) in
            if p.completedUnitCount == p.totalUnitCount {
                return
            } else {
                NotificationCenter.default.post(name: downloadProgressNotificationName, object: nil, userInfo: ["percent": Double(p.completedUnitCount) / Double(p.totalUnitCount)])
            }
        }).response { (response: DefaultDataResponse) in
            guard let data = response.data else {
                NotificationCenter.default.post(name: downloadErrorNotificationName, object: nil, userInfo: nil)
                return
            }
            let fileName = item.remoteUrl!.lastPathComponent
            let tempURL = URL.init(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
            do {
                try data.write(to: tempURL)
            } catch _ {
                NotificationCenter.default.post(name: downloadErrorNotificationName, object: nil, userInfo: nil)
            }
            
            let newItem = SourceItem(id: item.id, type: item.type, localUrl: tempURL, remoteUrl: item.remoteUrl, data: item.data)
            self.dic[NSString(string: item.id).integerValue] = newItem
            
            self.vc?.fileDic = self.dic
            
            guard let vcs = self.vc?.viewControllers as? [ContentViewController] else {
                return
            }
            for vc in vcs {
                if vc.si.id == newItem.id {
                    vc.si = newItem
                    NotificationCenter.default.post(name: downloadEndNotificationName, object: nil, userInfo: nil)
                    return
                }
            }
        }
    }
}

