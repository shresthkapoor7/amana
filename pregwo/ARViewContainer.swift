import SwiftUI
import ARKit
import RealityKit
import Vision

struct ARViewContainer: UIViewRepresentable {
    var geminiService: GeminiService
    var clearSignal: Int

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        arView.session.delegate = context.coordinator

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.checkForClear(signal: clearSignal)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(geminiService: geminiService, initialClearSignal: clearSignal)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        weak var arView: ARView?
        var geminiService: GeminiService

        private var handPoseRequest = VNDetectHumanHandPoseRequest()
        private var handDetectionTimestamp: Date?
        private var isProcessingFrame = false
        private var cardAnchor: AnchorEntity?
        private var lastClearSignal: Int

        init(geminiService: GeminiService, initialClearSignal: Int) {
            self.geminiService = geminiService
            self.lastClearSignal = initialClearSignal
        }

        func checkForClear(signal: Int) {
            if signal > lastClearSignal {
                removeCard()
                lastClearSignal = signal
            }
        }

        private func removeCard() {
            if let anchor = cardAnchor {
                arView?.scene.removeAnchor(anchor)
                cardAnchor = nil
            }
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard !isProcessingFrame else { return }

            isProcessingFrame = true

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }

                defer {
                    DispatchQueue.main.async {
                        self.isProcessingFrame = false
                    }
                }

                self.processFrame(frame)
            }
        }

        private func processFrame(_ frame: ARFrame) {
            let pixelBuffer = frame.capturedImage
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

            do {
                try handler.perform([handPoseRequest])

                if let observation = handPoseRequest.results?.first, observation.confidence > 0.8 {
                    if !geminiService.inProgress {
                        if handDetectionTimestamp == nil {
                            handDetectionTimestamp = Date()
                        }

                        if let timestamp = handDetectionTimestamp, Date().timeIntervalSince(timestamp) >= 2 {
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self, let arView = self.arView else { return }
                                self.placeAnchor(for: observation, in: arView, frame: frame)
                            }

                            if let image = imageFromPixelBuffer(frame.capturedImage) {
                                Task {
                                    await geminiService.sendImage(image)
                                }
                            }
                            handDetectionTimestamp = nil
                        }
                    }
                } else {
                    handDetectionTimestamp = nil
                }
            } catch {
                print("Failed to perform hand pose request: \(error)")
                handDetectionTimestamp = nil
            }
        }

        private func placeAnchor(for observation: VNHumanHandPoseObservation, in arView: ARView, frame: ARFrame) {
            do {
                let allPoints = try observation.recognizedPoints(.all).filter { $0.value.confidence > 0.3 }
                guard !allPoints.isEmpty else { return }

                let locations = allPoints.values.map { $0.location }
                let minX = locations.map { $0.x }.min() ?? 0
                let maxX = locations.map { $0.x }.max() ?? 0
                let minY = locations.map { $0.y }.min() ?? 0
                let maxY = locations.map { $0.y }.max() ?? 0
                let centerX = (minX + maxX) / 2
                let centerY = (minY + maxY) / 2

                let viewPoint = CGPoint(x: centerX, y: 1 - centerY)

                var finalTransform: simd_float4x4?

                // Prioritize finding a real-world plane
                if let result = arView.raycast(from: viewPoint, allowing: .estimatedPlane, alignment: .any).first {
                    finalTransform = result.worldTransform
                } else {
                    // Fallback to placing the object at a fixed distance if no plane is found
                    if let ray = arView.ray(through: viewPoint) {
                        let distance: Float = 0.5 // 50cm in front of the camera
                        let worldPosition = ray.origin + ray.direction * distance
                        finalTransform = Transform(translation: worldPosition).matrix
                    }
                }

                guard let transform = finalTransform else { return }

                if let existingAnchor = self.cardAnchor {
                    arView.scene.removeAnchor(existingAnchor)
                }

                // Create an anchor at the determined position
                let newAnchor = AnchorEntity(world: transform)

                // Create the card entity
                let cardWidth: Float = 0.2
                let cardHeight: Float = 0.07
                let cardPlane = MeshResource.generatePlane(width: cardWidth, height: cardHeight, cornerRadius: 0.01)
                let cardMaterial = UnlitMaterial(color: UIColor.black.withAlphaComponent(0.75))
                let cardEntity = ModelEntity(mesh: cardPlane, materials: [cardMaterial])

                // Create the text entity
                let textMesh = MeshResource.generateText("user hand was here",
                                                         extrusionDepth: 0.001,
                                                         font: .systemFont(ofSize: 0.015))
                let textMaterial = UnlitMaterial(color: .white)
                let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])

                // Position the text relative to the card
                let textBounds = textEntity.visualBounds(relativeTo: nil)
                let textWidth = textBounds.max.x - textBounds.min.x
                textEntity.position = SIMD3<Float>(-textWidth / 2, -0.015 / 2, 0.001)

                // Add text as a child of the card
                cardEntity.addChild(textEntity)

                // Add a billboard component to make the card always face the camera
                cardEntity.components.set(BillboardComponent())

                // The plane's front face is +Z, but billboard faces -Z to the camera.
                // Rotate the card 180 degrees so its front is visible.
                cardEntity.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])

                // Add the card to the anchor
                newAnchor.addChild(cardEntity)

                arView.scene.addAnchor(newAnchor)
                self.cardAnchor = newAnchor

            } catch {
                print("Could not get wrist points: \(error)")
            }
        }

        private func imageFromPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
            return UIImage(cgImage: cgImage)
        }
    }
}
