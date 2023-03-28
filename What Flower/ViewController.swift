//
//  ViewController.swift
//  What Flower
//
//  Created by Anurag Bhatt on 21/03/23.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController , UIImagePickerControllerDelegate , UINavigationControllerDelegate {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var imageDisplay: UIImageView!
    
    let imagePicker = UIImagePickerController() // we need to instantiate the class with an object so that we can use the methods or functions of that class
    
    let wikiUrl = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self // we've set the delegate as the current view controller i.e the viewcontroller
        imagePicker.allowsEditing = false // this function lets the user edit the photo that he has taken
        imagePicker.sourceType = .camera // this is telling what the nav bar button should do when it is clicked and it will open the camera for the user
        
    }
    
    
    
    
    
    
    // MARK: - IMAGE PICKER CONTROLLER
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        // the image that the user has selected will be in info so we need to tap into it and it is in the form of a dictionary and in a dict in order to get the value of the key we just pass in the key
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage{
            
            // the compiler does not know the type of data which will be returning from the above call so we are down casting it to an image so that the compiler can only let it set to the background if it is only of type image. we've downcasted the userPickedImage to be of image type only as we can see the key that we've provided to the dictionary can have any data type so to tell the compiler that it should be of an image type we've casted it as UIImage
            
            // now we will convert the user selected image to COREML image so that our ML Model can interpret it and classify it
            
            guard let ciimage = CIImage(image: userPickedImage) else // gaurd is to guard the assignment if the assignment fails then it will return us a fatal error
            {
                fatalError("COULD NOT COVERT THE USER IMAGE TO CORE ML IMAGE")
            }
            
            detect(image: ciimage)  // now we call the function that will use the converted ciimage to interpret the image
            
            
            // now we want to set the background of the user phone to the image that he has picked so we use
//            imageDisplay.image = userPickedImage
            
        }
        
        // here we're setting the user picked image to the imagePicker or the background that the ui image has been spreaded onto
        
        
        
        
        // once the user has done picking the image we need to dismiss the camera
        
        imagePicker.dismiss(animated: true , completion: nil)
        
    }
    
    
    
    
    
    
    
    
    
    
    // MARK: - DETECT FUNCTION
    
    func detect (image : CIImage)  // we've created an function that will have a parametre which take the CIImage and interprets it
    {
        // now we use the flowerClassifier model to classify our converted image
        
        // here we create a model so that we can tap into a var inside the flowerclassifier called model
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model)else // gaurd is to guard the assignment if the assignment fails then it will return us a fatal error
        {
            fatalError("Loading CoreML Model failed")
        }
        
        // now we create a request and perform the classification on the image this request will use the model which we have initialised as the flowerclassifier ml model
        
        let request = VNCoreMLRequest(model: model) { request , error in
            
            // now we need to create a handler that will handle our requests through this function
            
            // once this request has been completed our compelition handler will either send us an error or the reques that we asked for
            
            guard let classification = request.results?.first as? VNClassificationObservation else
            {
                fatalError("couldnt classify the image")
            }// now we're tapping onto the result that the handler has made after classifying the image
            
            self.navigationItem.title =  classification.identifier.capitalized // now we're setting the navigation bar title to the first and the most highest confidence result
            
            
            self.requesInfo(flowerName: classification.identifier)
            
        }
        
        // here is the handler
        
        let handler = VNImageRequestHandler(ciImage: image) // we've created a class object to use the functions of a class called VNImageRequestHandler which will take the function detect input image VNImagereq takes input as a ciImage that is our converted image being passed onto the funtion
        do
        {
            try handler.perform([request])
        }
        catch{
            
            print(error)
        }
        
    }
    
    
    
    
    
    
    // MARK: - CAMERA TAPPED ACTION
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        // we want the camera to present when the button is tapped and nothing should happen when it is done presenting
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    
    // MARK: - REQUEST METHOD FOR FLOWER
    
    func requesInfo(flowerName : String)
    {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        AF.request(wikiUrl, method: .get, parameters: parameters).responseJSON { (response) in
            switch response.result {
            case .success(let value):
                
                print("got the wikipedia info")
                print(response.result)
                
                let flowerJSON: JSON = JSON(value)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.imageDisplay.sd_setImage(with: URL(string: flowerImageURL))
                
                print(flowerDescription)
                
                self.label.text = flowerDescription
                
            case .failure:
                print("did not get the wikipedia info")
                
                
            }
            
            
            
            
        }
        
    }
    
}
    



