//
//  ViewController.swift
//  Road Sign Detector
//
//  Created by James Burriss on 02/02/2019.
//  Copyright © 2020 James Burriss. All rights reserved.
//

import UIKit

/// The main view controller.
class ViewController: UIViewController, UIDocumentPickerDelegate {
    
    /// The image view which displays the detection view.
    @IBOutlet private weak var imageView: UIImageView!
    
    /// The activity indicator view.
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    /// The label which displays the detection status.
    @IBOutlet private weak var label: UILabel!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.text = "Choose Image"
        activityIndicatorView.startAnimating()
        activityIndicatorView.isHidden = true
    }
    
    /// Selects an image to detect objects.
    func chooseImage() {
        openDocumentPicker()
    }
    
    /**
     Called when an image is selected.
     - parameter image: The image.
     */
    private func didSelectImage(_ image: UIImage) {
        let side = max(imageView.frame.size.width, imageView.frame.size.height)
        let size = CGSize(width: side, height: side)
        // Depth is 3 for 3x3 grid and 4 for 4x4 grid, set isFullScreenImage to true for 4x4
        let detectionView = DetectionView(category: .crosswalk,
                                          size: size,
                                          image: image,
                                          depth: 3,
                                          isFullScreenImage: false,
                                          precision: 0)
        
        imageView.setImage(nil, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            detectionView.render { result in
                switch result {
                case .success(let detectionView):
                    self.imageView.setImage(detectionView, animated: true)
                case .failure:
                    self.label.text = "Failed to Detect Objects"
                    self.activityIndicatorView.isHidden = true
                }
            }
        }
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    /// Opens the document picker.
    private func openDocumentPicker() {
        let controller = UIDocumentPickerViewController(documentTypes: ["public.image"], in: .open)
        controller.allowsMultipleSelection = false
        controller.delegate = self
        
        present(controller, animated: true) {
            self.label.text = "Detecting objects"
            self.activityIndicatorView.isHidden = false
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, let data = try? Data(contentsOf: url), let image = UIImage(data: data) else {
            return
        }
        didSelectImage(image)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        label.text = "Choose Image"
        activityIndicatorView.isHidden = true
        controller.dismiss(animated: true)
    }
}

extension UIImageView {
    
    /**
     Sets the image of the image view.
     - parameter image: The image.
     - parameter animated: Boolean value whether to animate the transition.
     */
    func setImage(_ image: UIImage?, animated: Bool) {
        if animated {
            UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve, animations: {
                self.image = image
            })
        } else {
            self.image = image
        }
    }
}
