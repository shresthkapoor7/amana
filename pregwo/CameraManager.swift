import AVFoundation
import UIKit
import Vision

class CameraManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var session = AVCaptureSession()
    private var videoOutput = AVCaptureVideoDataOutput()
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    private var handDetectionTimestamp: Date?

    var geminiService: GeminiService?

    override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        session.beginConfiguration()

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            print("Failed to get camera device")
            session.commitConfiguration()
            return
        }

        session.addInput(videoDeviceInput)

        if session.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            session.addOutput(videoOutput)
        }

        session.commitConfiguration()
    }

    func start() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func stop() {
        session.stopRunning()
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard geminiService?.inProgress == false else {
            handDetectionTimestamp = nil
            return
        }

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])

        do {
            try handler.perform([handPoseRequest])

            if let observation = handPoseRequest.results?.first, observation.confidence > 0.8 {
                if handDetectionTimestamp == nil {
                    handDetectionTimestamp = Date()
                }

                if let timestamp = handDetectionTimestamp, Date().timeIntervalSince(timestamp) >= 2 {
                    if let image = imageFromSampleBuffer(sampleBuffer) {
                        Task {
                            await geminiService?.sendImage(image)
                        }
                    }
                    handDetectionTimestamp = nil
                }
            } else {
                handDetectionTimestamp = nil
            }
        } catch {
            print("Failed to perform hand pose request: \(error)")
            handDetectionTimestamp = nil
        }
    }

    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
