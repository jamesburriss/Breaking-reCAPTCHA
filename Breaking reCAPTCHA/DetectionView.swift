//
//  DetectionView.swift
//  Breaking reCAPTCHA
//
//  Created by James Burriss on 15/04/2020.
//  Copyright © 2020 James Burriss. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

/// The detection view.
class DetectionView {
    
    /// A selection box.
    private typealias Box = UIView
    
    /// The machine learning model.
    private lazy var model: VNCoreMLModel = {
        guard let model = try? VNCoreMLModel(for: FinalObjectDetector().model) else {
            fatalError("Failed to initialise model")
        }
        return model
    }()
    
    /// The object detector.
    private lazy var objectDetector = ObjectDetector(model: model)
    
    /// The category of objects.
    private var category: ObjectCategory
    
    /// The detection view size.
    private var size: CGSize
    
    /// The image to detect objects.
    private var image: UIImage
    
    /// The depth of the boxes.
    private var depth: Int
    
    /// Boolean value whether detecting objects in a single image.
    private var isFullScreenImage: Bool
    
    /// The level of precision for each detection.
    private var precision: CGFloat
    
    /// The view.
    private var view: UIView
    
    /// The selection boxes.
    private var selectionBoxes: [Box]
    
    /**
     Initialises the detection view.
     - parameter category: The category of objects.
     - parameter size: The size of the detection view.
     - parameter image: The image to detect objects.
     - parameter depth: The number of boxes. Default is 1.
     - parameter isFullScreenImage: Boolean value whether detecting objects in a single image. Default is true.
     - parameter precision: The level of precision for each detection.
     */
    init(category: ObjectCategory, size: CGSize, image: UIImage, depth: Int = 1, isFullScreenImage: Bool = true, precision: CGFloat) {
        self.category = category
        self.size = size
        self.image = image.resized(targetSize: size)
        self.depth = depth
        self.isFullScreenImage = isFullScreenImage
        self.precision = precision
        self.view = UIView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        self.selectionBoxes = []
    }
    
    /**
     Renders the detection view.
     - parameter completion: A completion handler called once the objects have been detected.
     */
    func render(completion: @escaping (Result<UIImage, ObjectDetector.ObjectDetectorError>) -> Void) {
        // Draw the boxes and image view.
        drawImageView()
        drawBoxes()
        
        // Detect objects in single image.
        if isFullScreenImage {
            let containerFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            detectObjects(category, image: image, containerFrame: containerFrame) { result in
                switch result {
                case .success:
                    completion(.success(self.drawDetectionView()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
            return
        }
        
        // Detect objects in multiple images.
        let group = CountingDispatchGroup(enter: selectionBoxFrames.count)
        var error: ObjectDetector.ObjectDetectorError?
        
        // Detect objects.
        for (index, selectionBoxFrame) in selectionBoxFrames.enumerated() {
            guard let image = crop(at: index) else {
                group.leave()
                continue
            }
            detectObjects(category, image: image, containerFrame: selectionBoxFrame) { result in
                switch result {
                case .success:
                    break
                case .failure(let detectError):
                    error = detectError
                }
                group.leave()
            }
        }
        
        // Wait for detection to complete.
        group.manager.notify(queue: .main) {
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(self.drawDetectionView()))
        }
    }
    
    /**
     Crops the image at a given index.
     - parameter index: The index.
     - returns: The image.
     */
    func crop(at index: Int) -> UIImage? {
        image.crop(frame: selectionBoxFrames[index], in: size)
    }
    
    /// Draws the detection view.
    private func drawDetectionView() -> UIImage {
        // Layout view in preparation for rendering.
        view.setNeedsLayout()
        view.layoutIfNeeded()

        // Render view and save as image.
        let renderer = UIGraphicsImageRenderer(size: self.view.bounds.size)
        let image = renderer.image { _ in
            self.view.drawHierarchy(in: self.view.bounds, afterScreenUpdates: true)
        }
        return image
    }
    
    // MARK: - Object Detection
    
    /**
     Detects the objects in the image.
     - parameter category: The category of objects.
     - parameter image: The image to detect.
     - parameter containerFrame: The container frame of the image.
     - parameter completion: A completion handler called when the object detection has completed.
     */
    private func detectObjects(_ category: ObjectCategory, image: UIImage, containerFrame: CGRect, completion: @escaping (Result<Void, ObjectDetector.ObjectDetectorError>) -> Void) {
        let imageFrame = AVMakeRect(aspectRatio: containerFrame.size, insideRect: CGRect(x: 0, y: 0, width: containerFrame.width, height: containerFrame.height))
        objectDetector.detectObjects(category, in: image, frame: imageFrame) { result in
            switch result {
            case .success(let boundaries):
                for boundary in boundaries {
                    let adjustedBoundary = CGRect(x: boundary.origin.x + containerFrame.origin.x, y: boundary.origin.y + containerFrame.origin.y, width: boundary.width + self.precision, height: boundary.height + self.precision).intersection(containerFrame)
                    
                    // Add object detection view.
                    let boundaryView = UIView(frame: adjustedBoundary)
                    boundaryView.backgroundColor = DetectionView.objectColor
                    self.view.addSubview(boundaryView)
                    
                    // Check which box that detection is contained within.
                    for selectionBox in self.selectionBoxes {
                        if selectionBox.frame.intersects(adjustedBoundary) {
                            selectionBox.backgroundColor = DetectionView.boxSelectionColor
                        }
                    }
                }
                
                completion(.success(()))
            case .failure:
                completion(.failure(.failedToIdentifyObjects))
            }
        }
    }
    
    // MARK: - Layout
    
    /// The frames of the selection boxes.
    private var selectionBoxFrames: [CGRect] {
        let boxWidth = size.width / CGFloat(depth)
        let boxHeight = size.height / CGFloat(depth)
        var frames: [CGRect] = []
        
        for x in 0...depth - 1 {
            for y in 0...depth - 1 {
                let frame = CGRect(x: CGFloat(x) * boxWidth, y: CGFloat(y) * boxHeight, width: boxWidth, height: boxHeight)
                frames.append(frame)
            }
        }
        return frames
    }
    
    /// Draws the selection boxes.
    private func drawBoxes() {
        selectionBoxFrames.forEach { frame in
            let box = Box(frame: frame)
            box.layer.borderColor = UIColor.white.cgColor
            box.layer.borderWidth = 1
            view.addSubview(box)
            selectionBoxes.append(box)
        }
    }
    
    /// Draws the image view.
    private func drawImageView() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        imageView.image = image
        view.addSubview(imageView)
    }
}

extension UIImage {
    
    /**
     Crops an image from a frame.
     - parameter frame: The frame.
     - parameter size: The size of the full image.
     - returns: The cropped image.
     */
    func crop(frame: CGRect, in size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: frame.size.width * scale, height: frame.size.height * scale), true, 0.0)
        draw(at: CGPoint(x: -frame.origin.x * scale, y: -frame.origin.y * scale))
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return croppedImage
    }
    
    /**
     Resizes an image to a set size.
     - parameter targetSize: The target size.
     - returns: The resized image.
     */
    func resized(targetSize: CGSize) -> UIImage {
        let image = copy() as! UIImage
        let widthRatio = (targetSize.width * UIScreen.main.scale) / size.width
        let heightRatio = (targetSize.height * UIScreen.main.scale) / size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
        image.draw(in: rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

extension DetectionView {
    
    /// The detected object colour.
    private static let objectColor = UIColor.systemRed.withAlphaComponent(0.5)
    
    /// The box selection colour.
    private static let boxSelectionColor = UIColor.systemGreen.withAlphaComponent(0.5)
}
