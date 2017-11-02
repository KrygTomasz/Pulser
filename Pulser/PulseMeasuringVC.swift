//
//  ViewController.swift
//  Pulser
//
//  Created by Kryg Tomasz on 01.11.2017.
//  Copyright © 2017 Kryg Tomek. All rights reserved.
//

import UIKit
import AVFoundation

class PulseMeasuringVC: UIViewController {

    @IBOutlet weak var pulseView: PulseView! {
        didSet {
            pulseView.backgroundColor = .black
            pulseView.lineColor = .green
        }
    }
    var session: AVCaptureSession!
    var currentImage: UIImage? {
        didSet {
            let imageBrightness = calculateImageBrightness(currentImage)
            pulseView.valuesArray.append(imageBrightness)
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
        var imageBrightness: CGFloat = 0.0
        for y in stride(from: 0, to: Int(height), by: 10) {
            for x in stride(from: 0, to: Int(width), by: 10) {
                let point = CGPoint(x: x, y: y)
                let pixel = Pixel(of: currentImage, at: point)
                imageBrightness += pixel.brightness
            }
        }
        return imageBrightness
    }
    
}

//MARK: Frame capturing delegate
extension PulseMeasuringVC: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Captured frame")
        currentImage = imageFromSampleBuffer(sampleBuffer)
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
