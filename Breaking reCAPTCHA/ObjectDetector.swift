//
//  ObjectDetector.swift
//  Road Sign Detector
//
//  Created by James Burriss on 25/02/2020.
//  Copyright © 2020 James Burriss. All rights reserved.
//

import UIKit
import CoreML
import Vision
import ImageIO

/// An object detector.
class ObjectDetector {
    
    /// The model.
    private var model: VNCoreMLModel
    
    init(model: VNCoreMLModel) {
        self.model = model
    }
    
    /**
     Detect objects within the image frame.
     - parameter category: The category of object.
     - parameter image: The image.
     - parameter frame: The frame of the image.
     - parameter completion: A completion handler called once the detections have been made.
     */
    func detectObjects(_ category: ObjectCategory, in image: UIImage, frame: CGRect, completion: @escaping (Result<[CGRect], ObjectDetectorError>) -> Void) {
        // Create new request.
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let allDetections = request.results as? [VNRecognizedObjectObservation] else {
                DispatchQueue.main.async {
                    completion(.failure(.failedToIdentifyObjects))
                }
                return
            }
            let detections = allDetections.filter { detection in
                detection.labels.max { $0.confidence < $1.confidence }?.identifier == category.rawValue
            }
            let allIdentifiers = Set(allDetections.compactMap { $0.labels.max { $0.confidence < $1.confidence }?.identifier })
            print(allIdentifiers)
            
            // Determine the rects of each detection.
            let objectRects = detections.map {
                CGRect(x: $0.boundingBox.minX * frame.size.width, y: (1 - $0.boundingBox.minY - $0.boundingBox.height) * frame.size.height, width: $0.boundingBox.width * frame.size.width, height: $0.boundingBox.height * frame.size.height)
            }
            DispatchQueue.main.async {
                completion(.success(objectRects))
            }
        }
        request.imageCropAndScaleOption = .scaleFit
        
        // Determine the image orientation.
        let imageOrientation = UInt32(image.imageOrientation.rawValue)
        guard let ciImage = CIImage(image: image), let cgImageOrientation = CGImagePropertyOrientation(rawValue: imageOrientation) else {
            DispatchQueue.main.async {
                completion(.failure(.failedToIdentifyObjects))
            }
            return
        }
        
        // Perform the request.
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: cgImageOrientation)
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.failedToIdentifyObjects))
                }
            }
        }
    }
}

extension ObjectDetector {
    
    /// An object detection error.
    enum ObjectDetectorError: Error {
        case failedToIdentifyObjects
    }
}
