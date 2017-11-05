//
//  PulseMeasuringVC.swift
//  Pulser
//
//  Created by Kryg Tomasz on 01.11.2017.
//  Copyright © 2017 Kryg Tomek. All rights reserved.
//

import UIKit
import AVFoundation

class PulseMeasuringVC: UIViewController {

    @IBOutlet weak private var pulseView: PulseView! {
        didSet {
            pulseView.backgroundColor = .black
            pulseView.lineColor = .green
        }
    }
    private let CAMERA_FRAMES_PER_SECOND: Int = 30
    private let IMAGES_PER_SECOND: Int = 30
    private var frameShotsQuantity: Int = 0
    private var session: AVCaptureSession!
    private var lastImageBrightness: CGFloat = 0.0
    private var currentImage: UIImage? {
        didSet {
            let imageBrightness = calculateImageBrightness(currentImage)
            print(imageBrightness)
            let difference = (lastImageBrightness-imageBrightness).magnitude
            if imageBrightness < 0.4 && difference < 0.01 {
                pulseView.addNewPulseValue(imageBrightness)
                pulseView.isMeasuring = true
            } else {
                pulseView.isMeasuring = false
            }
            lastImageBrightness = imageBrightness
            pulseView.redraw()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureCamera()
        toggleFlash(true)
    }
    
    private func configureCamera() {
        session = AVCaptureSession()
        session.sessionPreset = .medium
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }
        do {
            let input = try AVCaptureDeviceInput.init(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print(error.localizedDescription)
        }
        
        let output = AVCaptureVideoDataOutput()
        
        output.alwaysDiscardsLateVideoFrames = true
//        let queue = DispatchQueue(label: "framesQueue")
//        let queue = dispatch_queue_create("myQueue", 0)
        output.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        output.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) as String: NSNumber(value: kCVPixelFormatType_32BGRA)]
        session.addOutput(output)
        session.startRunning()
    }
    
    private func calculateImageBrightness(_ image: UIImage?) -> CGFloat {
        guard
            let height = image?.size.height,
            let width = image?.size.width else {
                return 0.0
        }
        var imageBrightnessSum: CGFloat = 0.0
        var pixelsAnalyzed = 0
        for y in stride(from: 0, to: Int(height), by: 10) {
            for x in stride(from: 0, to: Int(width), by: 10) {
                let point = CGPoint(x: x, y: y)
                let pixel = Pixel(of: currentImage, at: point)
                imageBrightnessSum += pixel.brightness
                pixelsAnalyzed += 1
            }
        }
        let averageImageBrightness = imageBrightnessSum/CGFloat(pixelsAnalyzed)
        return averageImageBrightness
    }
    
    private func tryToCapture(_ image: UIImage?) {
        if frameShotsQuantity % (CAMERA_FRAMES_PER_SECOND/IMAGES_PER_SECOND) == 0 {
            currentImage = image
        }
    }
    
}

//MARK: Frame capturing delegate
extension PulseMeasuringVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameShotsQuantity += 1
        let capturedImage = imageFromSampleBuffer(sampleBuffer)
        tryToCapture(capturedImage)
    }
}

//MARK: Image conversion from CMSampleBuffer
extension PulseMeasuringVC {
    func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let baseAddress: UnsafeMutableRawPointer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, Int(0)) else {
            return nil
        }
        let bytesPerRow: Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width: Int = CVPixelBufferGetWidth(imageBuffer)
        let height: Int = CVPixelBufferGetHeight(imageBuffer)
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent: Int = 8
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue) as UInt32)
        guard let newContext: CGContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue),
            let imageRef: CGImage = newContext.makeImage()
            else {
                return nil
        }
        let resultImage = UIImage(cgImage: imageRef, scale: 1.0, orientation: .right)
        return resultImage
    }
}

//MARK: Flash handling
extension PulseMeasuringVC {
    func toggleFlash(_ turnOn: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                if turnOn == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                print("Error: Flash could not be used")
            }
        } else {
            print("Error: Flash is not available")
        }
    }
}
