//
//  EditItemViewController.swift
//  TestTabbed
//
//  Created by David Evans on 7/11/17.
//  Copyright © 2017 David Evans. All rights reserved.
//

import UIKit
import MobileCoreServices

class EditDetailViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    var auctionItem: AuctionItem? = nil
   
    @IBAction func auctionTypeChanged(_ sender: Any) {

        if (auctionTypeToggle.isOn) {
            endDatePicker.isEnabled = false
            endDateLabel.text = "First Come, First Serve"
        } else {
            endDatePicker.isEnabled = true
            updateExpiryFullDate()
        }
        
    }
    
    func updateExpiryFullDate() {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        endDateLabel.text = formatter.string(from: endDatePicker.date)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        endDatePicker.isHidden = true
        endDatePicker.addTarget(self, action: #selector(self.expiryUIDateChanged), for: UIControlEvents.valueChanged)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(endDateLabelPressed))
        endDateLabel.addGestureRecognizer(tap)
        
        
        endDatePicker.minimumDate = Date()
        
        self.hideKeyboardWhenTappedAround()
        
        let calendar = Calendar.current
        var dc = DateComponents()
        dc.timeZone = TimeZone(abbreviation: "CST")
        dc.weekday = 5
        let fiveDaysFromNow = calendar.date(byAdding: dc, to: Date())
        
        let x1 = calendar.date(bySetting: .hour,value:15,of:fiveDaysFromNow!)
        let expiry = calendar.date(bySetting: .minute,value:00,of:x1!)
        endDatePicker.setDate(expiry!, animated: false)
        updateExpiryFullDate()
      
        UIGraphicsBeginImageContext(self.view.frame.size)
        UIImage(named: "nwa_blur")?.draw(in: self.view.bounds)
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
        
        self.view.backgroundColor = UIColor(patternImage: image)
        
        if auctionItem != nil {
            self.minimumBid.text = "\(auctionItem?.minBid ?? 0)"
            self.txtDescription.text = auctionItem?.name
            self.endDatePicker.setDate((auctionItem?.endDate)!, animated: true)
            updateExpiryFullDate()
            self.auctionTypeToggle.isOn = (auctionItem?.firstComeFirstServe)!
            if self.auctionItem?.image != "" {
                let image = dataContainer.getImage(urlString: (auctionItem?.image)!)
                if (image != nil) {
                    self.imagePreview.image = image
                }
            } else {
                self.imagePreview.image = nil
            }
            
        }
        
        
    }
    
    func endDateLabelPressed() {
        if !auctionTypeToggle.isOn {
            if endDatePicker.isHidden == true {
                endDatePicker.isHidden = false
                imagePreview.isHidden = true
            } else {
                endDatePicker.isHidden = true
                imagePreview.isHidden = false
            }
        }
    }
    
    func expiryUIDateChanged(sender:UIDatePicker) {
        updateExpiryFullDate()
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.auctionItem = nil
        self.dismiss(animated: true, completion: nil)
    }

    @IBOutlet weak var datePickerSuperView: UIView!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        if (txtDescription.text == "") {
            showAlert(title: "Incomplete", message: "Description required")
            return
        }
        if (minimumBid.text == "") {
            showAlert(title: "Incomplete", message: "Minimum Bid required")
            return
        }
        Util.showWaiting(viewController: self)
        
        var uuid:String? = nil
        if auctionItem != nil {
            uuid = auctionItem?.id
        }
        
        let uploadTask = dataContainer.addAuctionItem(description: txtDescription.text!, image: imageView.image!, minBid: minimumBid.text!, firstComeFirstServe: auctionTypeToggle.isOn, expiry: endDatePicker.date, id:uuid)

        uploadTask.observe(.progress) { snapshot in
            self.progressBar.setProgress(Float((snapshot.progress?.fractionCompleted)!), animated: true)

        }
        uploadTask.observe(.success) { snapshot in
            self.auctionItem = nil
            Util.dismissWaiting()
            self.dismiss(animated: true, completion: nil)
        }
        uploadTask.observe(.failure) { snapshot in
            if let error = snapshot.error as NSError? {
                self.showAlert(title:"Save Failed", message:error.localizedDescription)
            }
            self.auctionItem = nil
            Util.dismissWaiting()
            self.dismiss(animated: true, completion: nil)
        }
        
    }
    
    @IBOutlet weak var imageView: UIImageView!
    var newMedia: Bool?
    
    @IBOutlet weak var auctionTypeToggle: UISwitch!
    @IBOutlet weak var minimumBid: UITextField!
    @IBOutlet weak var endDateLabel: UILabel!
    @IBOutlet weak var imagePreview: UIImageView!

    @IBOutlet weak var txtDescription: UITextField!
    @IBAction func usePhotoLibrary(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.savedPhotosAlbum) {
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType =
                UIImagePickerControllerSourceType.photoLibrary
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true,
                         completion: nil)
            newMedia = false
        }
    }
    @IBAction func useCamera(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.camera) {
            
            let imagePicker = UIImagePickerController()
            
            imagePicker.delegate = self
            imagePicker.sourceType =
                UIImagePickerControllerSourceType.camera
            imagePicker.mediaTypes = [kUTTypeImage as String]
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true,
                         completion: nil)
            newMedia = true
        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        self.dismiss(animated: true, completion: nil)
        
        if mediaType.isEqual(to: kUTTypeImage as String) {
            let image = info[UIImagePickerControllerOriginalImage]
                as! UIImage
            
            imageView.image = image
            if (newMedia == true) {
                
                
                //UIImageWriteToSavedPhotosAlbum(image, self,
                //                               #selector(EditItemViewController.image(image:didFinishSavingWithError:contextInfo:)), nil)
            }
            
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    func image(image: UIImage, didFinishSavingWithError error: NSErrorPointer, contextInfo:UnsafeRawPointer) {
        
        if error != nil {
            showAlert(title: "Save Failed", message: "Failed to save image")
        }
    }
    
    func showAlert(title:String,message:String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: "OK",
                                         style: .cancel, handler: nil)
        
        alert.addAction(cancelAction)
        self.present(alert, animated: true,
                     completion: nil)
    }
    
    
}
