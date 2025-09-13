import SwiftUI
import ARKit
import RealityKit
import Vision

struct ARViewContainer: UIViewRepresentable {
    var geminiService: GeminiService
    var clearSignal: Int
    var isActive: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        arView.session.delegate = context.coordinator

        // Don't start the session here; let updateUIView manage it.

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.checkForClear(signal: clearSignal)

        if isActive {
            // Ensure the session is running when the view is active.
            let config = ARWorldTrackingConfiguration()
            config.planeDetection = [.horizontal]
            uiView.session.run(config)
        } else {
            // Pause the session when the view is inactive.
            uiView.session.pause()
        }
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
                            let image = imageFromPixelBuffer(frame.capturedImage)

                            // Place a placeholder card immediately
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self, let arView = self.arView else { return }
                                self.placeNewCard(for: observation, in: arView, frame: frame)
                            }

                            handDetectionTimestamp = nil

                            // Get response and update the card's texture
                            Task { [weak self] in
                                guard let self = self, let img = image else { return }
                                let response = await self.geminiService.generateResponse(for: img)

                                DispatchQueue.main.async {
                                    self.updateCardTexture(with: response)
                                }
                            }
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

        @MainActor
        private func placeNewCard(for observation: VNHumanHandPoseObservation, in arView: ARView, frame: ARFrame) {
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

                if let result = arView.raycast(from: viewPoint, allowing: .estimatedPlane, alignment: .any).first {
                    finalTransform = result.worldTransform
                } else {
                    if let ray = arView.ray(through: viewPoint) {
                        let distance: Float = 0.5
                        let worldPosition = ray.origin + ray.direction * distance
                        finalTransform = Transform(translation: worldPosition).matrix
                    }
                }

                guard let transform = finalTransform else { return }

                if let existingAnchor = self.cardAnchor {
                    arView.scene.removeAnchor(existingAnchor)
                }

                let newAnchor = AnchorEntity(world: transform)

                let cardWidth: Float = 0.25
                let cardHeight: Float = 0.25
                let cardPlane = MeshResource.generatePlane(width: cardWidth, height: cardHeight, cornerRadius: 0.02)
                let cardMaterial = UnlitMaterial(color: UIColor.darkGray.withAlphaComponent(0.8))
                let cardEntity = ModelEntity(mesh: cardPlane, materials: [cardMaterial])
                cardEntity.name = "geminiCard"

                cardEntity.components.set(BillboardComponent())
                cardEntity.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])

                newAnchor.addChild(cardEntity)
                arView.scene.addAnchor(newAnchor)
                self.cardAnchor = newAnchor

            } catch {
                print("Could not get wrist points: \(error)")
            }
        }

        @MainActor
        private func updateCardTexture(with markdownText: String) {
            guard let cardAnchor = self.cardAnchor,
                  let cardEntity = cardAnchor.findEntity(named: "geminiCard") as? ModelEntity else { return }

            guard let textureImage = MarkdownRenderer.render(markdown: markdownText),
                  let cgImage = textureImage.cgImage else { return }

            // Calculate the aspect ratio of the rendered image
            let imageSize = textureImage.size
            let aspectRatio = imageSize.height / imageSize.width

            // Define a fixed width for the card and calculate the height based on the aspect ratio
            let cardWidth: Float = 0.25
            let cardHeight = cardWidth * Float(aspectRatio)

            // Create a new plane mesh with the correct dimensions
            let newPlane = MeshResource.generatePlane(width: cardWidth, height: cardHeight, cornerRadius: 0.02)
            cardEntity.model?.mesh = newPlane

            do {
                let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
                var newMaterial = UnlitMaterial()
                newMaterial.color = .init(texture: .init(texture))

                cardEntity.model?.materials = [newMaterial]
            } catch {
                print("Failed to create texture for card: \(error)")
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
