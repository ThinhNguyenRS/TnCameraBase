//
//  CameraPreviewView+Metal.swift
//  tCamera
//
//  Created by Thinh Nguyen on 7/26/24.
//

import Foundation
import MetalKit
import SwiftUI
import Combine
import TnIosBase

public struct TnCameraPreviewViewMetal: TnLoggable {
    public class InternalView: MTKView, TnLoggable {
        /// The image that should be displayed next.
        private var ciImage: CIImage?
        private var cancelables = Set<AnyCancellable>()
        
        private lazy var commandQueue: MTLCommandQueue = self.device!.makeCommandQueue()!
        private lazy var context: CIContext = CIContext(mtlDevice: self.device!)
        
        init(device: MTLDevice) {
            super.init(frame: .zero, device: device)
            
            // setup view to only draw when we need it (i.e., a new pixel buffer arrived), not continuously
            self.isPaused = true
            self.enableSetNeedsDisplay = true
            self.autoResizeDrawable = true
            
            // we only need a wider gamut pixel format if the display supports it
            self.colorPixelFormat = (self.traitCollection.displayGamut == .P3) ? .bgr10_xr_srgb : .bgra8Unorm_srgb
            
            // this is important, otherwise Core Image could not render into the view's framebuffer directly
            self.framebufferOnly = false
            self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            
            logDebug("inited")
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        public override func draw(_ rect: CGRect) {
            guard let input = self.ciImage,
                  let currentDrawable = self.currentDrawable,
                  let commandBuffer = self.commandQueue.makeCommandBuffer() else {
                return
            }
            
            //            TnLogger.debug("draw", input.extent.width, input.extent.height)
            // scale to fit into view
            let drawableSize = self.drawableSize
            let scaleX = drawableSize.width / input.extent.width
            let scaleY = drawableSize.height / input.extent.height
            let scale = min(scaleX, scaleY)
            let scaledImage = input.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            
            // center in the view
            let originX = max(drawableSize.width - scaledImage.extent.size.width, 0) / 2
            let originY = max(drawableSize.height - scaledImage.extent.size.height, 0) / 2
            let centeredImage = scaledImage.transformed(by: CGAffineTransform(translationX: originX, y: originY))
            
            // Create a render destination that allows to lazily fetch the target texture
            // which allows the encoder to process all CI commands _before_ the texture is actually available.
            // This gives a nice speed boost because the CPU doesn't need to wait for the GPU to finish
            // before starting to encode the next frame.
            // Also note that we don't pass a command buffer here, because according to Apple:
            // "Rendering to a CIRenderDestination initialized with a commandBuffer requires encoding all
            // the commands to render an image into the specified buffer. This may impact system responsiveness
            // and may result in higher memory usage if the image requires many passes to render."
            let destination = CIRenderDestination(width: Int(drawableSize.width),
                                                  height: Int(drawableSize.height),
                                                  pixelFormat: self.colorPixelFormat,
                                                  commandBuffer: nil,
                                                  mtlTextureProvider: { () -> MTLTexture in
                return currentDrawable.texture
            })
            
            do {
                try self.context.startTask(toClear: destination)
                try self.context.startTask(toRender: centeredImage, to: destination)
            } catch {
                assertionFailure("Failed to render to preview view: \(error)")
            }
            
            commandBuffer.present(currentDrawable)
            commandBuffer.commit()
        }
        
        func setImagePublisher(imagePublisher: AnyPublisher<CIImage?, Never>) {
            // the key point here: this is combine. sink or subcribe the publisher
            imagePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] ciImage in
                    self?.ciImage = ciImage
                    self?.setNeedsDisplay()
                }
                .store(in: &cancelables)
        }
    }
    
    let internalView: InternalView = InternalView(device: MTLCreateSystemDefaultDevice()!)
    
    public init() {
        logDebug("inited")
    }
    
    public init(imagePublisher: Published<CIImage?>.Publisher) {
        internalView.setImagePublisher(imagePublisher: imagePublisher.eraseToAnyPublisher())
        logDebug("inited")
    }
    
    @discardableResult
    public func setImagePublisher(imagePublisher: @escaping () async -> Published<CIImage?>.Publisher) -> Self {
        Task { /*@MainActor in*/
            await internalView.setImagePublisher(imagePublisher: await imagePublisher().eraseToAnyPublisher())
            logDebug("listen image ...")
        }
        return self
    }
}

extension TnCameraPreviewViewMetal: UIViewRepresentable {
    public func makeUIView(context: Context) -> InternalView {
        internalView
    }

    public func updateUIView(_ uiView: InternalView, context: Context) {
    }
}
