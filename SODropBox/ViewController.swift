//
//  ViewController.swift
//  SODropBox
//
//  Created by Hitesh on 9/29/16.
//  Copyright © 2016 myCompany. All rights reserved.
//

import UIKit
import SwiftyDropbox

class ViewController: UIViewController {

    let arrDropboxImages = NSMutableArray()
    @IBOutlet weak var collectionViewDropbox: UICollectionView!
    
    @IBOutlet weak var imgProfile: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionViewDropbox.hidden = true
        
        imgProfile.layer.cornerRadius = imgProfile.frame.size.height/2
        imgProfile.layer.masksToBounds = true
    }

    @IBAction func actionDropboxLogin(sender: AnyObject) {
        
        if (Dropbox.authorizedClient != nil) {
    
            //User is already authorized
            //Fetch images from user's DropBox folder
            self.getImageFromDropbox()
        } else {
            
            //User not authorized
            //So we go for authorize user first.
            Dropbox.authorizeFromController(UIApplication.sharedApplication(), controller: self, openURL: { (url) in
                UIApplication.sharedApplication().openURL(url)
                
                //Fetch images from user's DropBox folder
                self.getImageFromDropbox()
            })

        }
    }
    
    
    //Fetch all images from DropBox
    func getImageFromDropbox() {
        
        let client = Dropbox.authorizedClient
        
        //Get list of folder of dropbox by set (path: "/")
        //Or you can get folder inside a folder by set (path: "/Photos")
        client!.files.listFolder(path: "/Photos/1").response({ (objList, error) in
            if let resultList = objList {
                //var entrycount = resultList.entries.count
                
                //Create a for loop for get all the entities individually
                for entry in resultList.entries {
                    //entrycount -= 1
                    
                    //Check if file have metadata or not
                    if let fileMetadata = entry as? Files.FileMetadata {
                        
                        //Check file type by extention .jpg/.png
                        //You can check this by your own added extention
                        if self.isFileImage(fileMetadata.name) == true {
                            
                            //Get Path for save image in document directory
                            let destination : (NSURL, NSHTTPURLResponse) -> NSURL = { temporaryURL, response in
                                return self.getDocumentDirectoryPath(fileMetadata.name)
                            }
                            
                            //Download Image on destination path
                            client!.files.download(path: fileMetadata.pathLower!, destination: destination).response { response, error in
                                if let (_, url) = response {
                                    let data = NSData(contentsOfURL: url)
                                    let img = UIImage(data: data!)
                                    
                                    if !self.arrDropboxImages.containsObject(img!) {
                                        self.arrDropboxImages.addObject(img!)
                                        self.collectionViewDropbox.hidden = false
                                        self.collectionViewDropbox.reloadData()
                                    }
                                    else {
                                        print("Image already added to array")
                                    }
                                }
                            }
                        } else {
                            //File is not an image
                        }
                    } else {
                        //If file have not metadata it mean it is a folder.
                    }
                    
//                    if (entrycount == 0 && self.arrDropboxImages.count > 0) {
//                        self.collectionViewDropbox.hidden = false
//                        self.collectionViewDropbox.reloadData()
//                    }
                    
                }
                
                
            } else {
                print(error)
            }
        })
    }
    
    //Logout
    func logoutFromDropBox() {
        //Check Dropbox is authorized or not
        if (Dropbox.authorizedClient != nil) {
            
            //If Authorized then unlink it.
            Dropbox.unlinkClient()
        }
    }
    
    //MARK: check for file type
    private func isFileImage(filename:String) -> Bool {
        let lastPathComponent = filename.pathExtension().lowercaseString
        return lastPathComponent == "jpg" || lastPathComponent == "png"
    }
    
    //to get document directory path
    func getDocumentDirectoryPath(fileName:String) -> NSURL {
        let fileManager = NSFileManager.defaultManager()
        let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let UUID = NSUUID().UUIDString
        let pathComponent = "\(UUID)-\(fileName)"
        return directoryURL.URLByAppendingPathComponent(pathComponent)
    }
    
    
    //MARK: UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrDropboxImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath)
        configureCell(cell, forItemAtIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UICollectionViewCell, forItemAtIndexPath: NSIndexPath) {
        let imgView = cell.viewWithTag(1) as? UIImageView
        imgView!.image = arrDropboxImages.objectAtIndex(forItemAtIndexPath.row) as? UIImage
        cell.contentView.addSubview(imgView!)
    }
    
    //MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        imgProfile.image = arrDropboxImages.objectAtIndex(indexPath.row) as? UIImage
        collectionViewDropbox.hidden = true
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension String {
    public func lastPathComponent() -> String {
        return (self as NSString).lastPathComponent
    }
    
    public func pathExtension() -> String {
        return (self as NSString).pathExtension
    }
}

