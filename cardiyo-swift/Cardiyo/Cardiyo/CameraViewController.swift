//
//  CameraViewController.swift
//  Cardioh
//
//  Created by Dmitry Pimenov on 10/11/16.
//  Copyright © 2016 Dmitry. All rights reserved.
//
import UIKit
import CameraManager
import AVFoundation
import CoreGraphics
import GBHFacebookImagePicker

class CameraViewController: UIViewController, GBHFacebookImagePickerDelegate {
    weak var image: UIImage?
    let cameraManager = CameraManager()
    var isPreviewShown: Bool?
    
    var isFbImage: Bool? = false
    var isFrontCamera: Bool? = true
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    var activityInfo: ActivityInfo?
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItem.Style.plain, target: navigationController, action: nil)
        navigationItem.leftBarButtonItem = backButton
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.askForCameraPermissions()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(CameraViewController.cancelButtonPressed))
        swipeRight.direction = UISwipeGestureRecognizer.Direction.right
        self.view.addGestureRecognizer(swipeRight)
        cameraButton.isHidden = true
        self.cameraView.isHidden = true
        self.isPreviewShown = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraView.isHidden = true;
        cameraManager.stopCaptureSession()
    }
    
    override func prepare(for segue: UIStoryboardSegue?, sender: Any?) {
        // Create a new variable to store the instance of PlayerTableViewController
        if segue?.identifier == "CameraToSummary" {
            let destinationVC = segue!.destination as! EndOfRunViewController
            let camActivityInfo = self.activityInfo!
            camActivityInfo.primaryImage = self.image
            camActivityInfo.takenWithFrontCamera = self.isFrontCamera
            camActivityInfo.isFbImage = self.isFbImage
            destinationVC.activityInfo = camActivityInfo
        }
    }
    
    @IBAction func captureButtonPressed(_ sender: UIButton) {
        var successfulCapture = false;
        if (cameraManager.cameraOutputMode == .stillImage){
            cameraManager.capturePictureWithCompletion({ (image, error) -> Void in
                if (error != nil){
                    //handle error
                } else {
                    //successful capture
                }
                
                if ((image) != nil){
                    self.image = self.cropToBounds(image: image!, width: 500, height: 500);

                }
                print(self.image?.size)
                self.performSegue(withIdentifier: "CameraToSummary", sender: nil)
                successfulCapture = true;
             })
        }
    }
    
    @IBAction func switchCameras(_ sender: UIButton){
        if (self.isFrontCamera!){
            cameraManager.cameraDevice = .back
            self.isFrontCamera = false
        } else {
            cameraManager.cameraDevice = .front
            self.isFrontCamera = true
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        //return to main
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        self.navigationController?.popToRootViewController(animated:true);
    }
    
    @IBAction func showFBImagePicker(_ sender: UIButton){
        let picker = GBHFacebookImagePicker()
        picker.presentFacebookAlbumImagePicker(from: self, delegate: self)
    }
    
    func askForCameraPermissions() {
        self.isFrontCamera = true
        cameraManager.cameraDevice = .front
        cameraManager.showAccessPermissionPopupAutomatically = false
        cameraManager.cameraOutputMode = .stillImage
        cameraManager.cameraOutputQuality = .high
        cameraManager.flashMode = .off
        cameraManager.writeFilesToPhoneLibrary = false
        cameraManager.askUserForCameraPermission({ permissionGranted in
            if permissionGranted {
                self.addCameraToView()
            } else {
                if (self.checkPermissions() == false)
                {
                    self.presentErrorModal()
                }
            }
        })
    }
    
    func addCameraToView(){
        if (self.isPreviewShown == false){
            cameraButton.isHidden = false;
            cameraManager.addPreviewLayerToView(self.cameraView)
            self.isPreviewShown = true;
        }
        cameraManager.resumeCaptureSession()
        UIView.animate(withDuration: 0.25,
                       delay: 0.25,
                       options: UIView.AnimationOptions.curveEaseIn,
                       animations: { () -> Void in
                        self.cameraView.isHidden = false;
        }, completion: { (finished) -> Void in
            // ....
        })
    }
    
    func checkPermissions() -> Bool {
        var result = false
        let cameraMediaType = AVMediaType.video
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: cameraMediaType)
        
        switch cameraAuthorizationStatus {
        case .denied:
            result = false
            break
        case .authorized:
            result = true
        case .restricted:
            result = false
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: cameraMediaType) { granted in
                if granted {
                    result = true
                } else {
                    result = false
                }
                
            }
        }
        return result
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    func presentErrorModal(){
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "errorVC") as! ErrorViewController
        vc.shouldCheckLocationPermissions = true;
        vc.shouldCheckImagePermissions = true;
        present(vc, animated: true, completion: nil)
    }
    
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        let contextSize: CGSize = image.size
        var minorAxis: CGFloat = 0.0
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(0.0)
        var cgheight: CGFloat = CGFloat(0.0)
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            minorAxis = contextSize.height
            posX = 0
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            minorAxis = contextSize.width
            posX = 0
            posY = 0
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        let scaleFactor = minorAxis/min(CGFloat(width), CGFloat(height))
        let rect: CGRect = CGRect.init(x: posX, y: posY, width: cgwidth, height: cgheight);
        let imageRef = image.cgImage!.cropping(to: rect)
        var image = UIImage()
        if (self.isFrontCamera!){
            image = UIImage(cgImage: imageRef!, scale: image.scale*scaleFactor, orientation: .leftMirrored)
        } else {
            image = UIImage(cgImage: imageRef!, scale: image.scale*scaleFactor, orientation: .right)
        }
        print(image.imageOrientation)
        let size = image.size //TODO: remove this at some point
        print(size)
        return image
    }
    
    func cropToBoundsFb(image: UIImage, width: Double, height: Double) -> UIImage {
        let contextSize: CGSize = image.size
        var minorAxis: CGFloat = 0.0
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            minorAxis = contextSize.height
            posX = 0
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            minorAxis = contextSize.width
            posX = 0
            posY = 0
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        let scaleFactor = minorAxis/min(CGFloat(width), CGFloat(height))
        let rect: CGRect = CGRect.init(x: posX, y: posY, width: cgwidth, height: cgheight);
        let imageRef = image.cgImage!.cropping(to: rect)
        var image = UIImage()
        image = UIImage(cgImage: imageRef!, scale: image.scale*scaleFactor, orientation: .up)
        let size = image.size //why does this work - DO NOT REMOVE
        print(size)
        return image
    }
    
    
    // MARK: - GBHFacebookImagePicker Protocol
    func facebookImagePicker(imagePicker: UIViewController, didSelectImage image: UIImage?, WithUrl url: String) {
        if let pickedImage = image {
            self.isFbImage = true
            self.image = self.cropToBoundsFb(image: pickedImage, width: 500, height: 500);
            print("image was cropped: \(self.image)")
            self.performSegue(withIdentifier: "CameraToSummary", sender: nil)
            imagePicker.dismiss(animated: true, completion: nil)
        }

    }
    func facebookImagePicker(imagePicker: UIViewController, didFailWithError error: Error?) {
    }
    
    func facebookImagePicker(didCancelled imagePicker: UIViewController) {
    }

}
