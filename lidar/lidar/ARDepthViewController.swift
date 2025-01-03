//
//  ARDepthViewController.swift
//  lidar
//
//  Created by matt kazan on 10/29/24.
//

import UIKit
import ARKit

struct Point: Codable {
    let x: Float
    let y: Float
    let z: Float
}

class ARDepthViewController: UIViewController, ARSessionDelegate {
    var arView: ARSCNView!
    var capturedPointCloud: [SIMD3<Float>] = []
    var isScanning = false // Track the scanning state
    var scanningTimer: Timer?


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the ARSCNView
        arView = ARSCNView(frame: self.view.bounds)
        self.view.addSubview(arView)
        arView.session.delegate = self

        // Enable LiDAR depth data collection
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        arView.session.run(configuration)
    }

    func startScanning() {
        isScanning = true
        scanningTimer = Timer.scheduledTimer(withTimeInterval: 0.30, repeats: true) { _ in
            self.capturePointCloud()
        }
    }

    func stopScanning() {
        isScanning = false
        scanningTimer?.invalidate()
        scanningTimer = nil
    }

    func toggleScanning() {
        if isScanning {
            print("stop scanning")
            stopScanning()
        } else {
            print("start scanning")
            startScanning()
        }
    }

    func capturePointCloud() {
        if isScanning == false {
            return
        }
        guard let frame = arView.session.currentFrame,
              let depthData = frame.sceneDepth?.depthMap else {
            print("Depth data is unavailable.")
            return
        }
//        let pointCloud = savePointCloud(from: depthData, cameraIntrinsics: frame.camera.intrinsics, resolution: frame.camera.imageResolution)
////        print(frame.camera.intrinsics)
////        printDepthData(depthData)
//        uploadCSV()
        uploadPointCloud(from: depthData)
    }
    
    func uploadPointCloud(from depthData: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(depthData, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthData, .readOnly) }

        let width = Int(CVPixelBufferGetWidth(depthData))
        let height = Int(CVPixelBufferGetHeight(depthData))
        let depthPointer = unsafeBitCast(CVPixelBufferGetBaseAddress(depthData), to: UnsafeMutablePointer<Float32>.self)

        // Create the point cloud as raw tuples
        var pointCloud: [Point] = []
        for y in 0..<height {
            for x in 0..<width {
                let depth = depthPointer[y * width + x]
                if depth > 0 {
                    pointCloud.append(Point(x: Float(x), y: Float(y), z: depth))
                }
            }
        }

        // Prepare the JSON payload
        do {
            let jsonData = try JSONEncoder().encode(pointCloud)
            
            // Upload the JSON directly
            var request = URLRequest(url: URL(string: "http://10.0.0.169:8080")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error uploading point cloud: \(error)")
                    return
                }
                print("Point cloud uploaded successfully")
            }.resume()
        } catch {
            print("Failed to encode point cloud: \(error)")
        }
    }
    
}
