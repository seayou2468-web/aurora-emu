import SwiftUI
import MetalKit

struct MetalVideoView: UIViewRepresentable {
    let bridge: AuroraCoreBridge

    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.backgroundColor = .black
        return mtkView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(bridge: bridge)
    }

    class Coordinator: NSObject, MTKViewDelegate {
        let bridge: AuroraCoreBridge
        let device: MTLDevice?
        let commandQueue: MTLCommandQueue?
        var pipelineState: MTLRenderPipelineState?

        init(bridge: AuroraCoreBridge) {
            self.bridge = bridge
            self.device = MTLCreateSystemDefaultDevice()
            self.commandQueue = device?.makeCommandQueue()
            super.init()
            setupPipeline()
        }

        private func setupPipeline() {
            guard let device = device else { return }

            // Modern Swift-based Metal shader definition (iOS 26 compatible)
            let shaderSource = """
            #include <metal_stdlib>
            using namespace metal;

            struct VertexOut {
                float4 position [[position]];
                float2 texCoord;
            };

            vertex VertexOut vertex_main(uint vid [[vertex_id]]) {
                float2 positions[4] = { float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1) };
                float2 texCoords[4] = { float2(0, 1), float2(1, 1), float2(0, 0), float2(1, 0) };
                VertexOut out;
                out.position = float4(positions[vid], 0, 1);
                out.texCoord = texCoords[vid];
                return out;
            }

            fragment float4 fragment_main(VertexOut in [[stage_in]], texture2d<float> tex [[texture(0)]]) {
                sampler s(mag_filter::nearest, min_filter::nearest);
                return tex.sample(s, in.texCoord);
            }
            """

            do {
                let library = try device.makeLibrary(source: shaderSource, options: nil)
                let pipelineDescriptor = MTLRenderPipelineDescriptor()
                pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_main")
                pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_main")
                pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm // Standard MTKView format

                pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            } catch {
                print("Metal pipeline setup failed: \(error)")
            }
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let pipelineState = pipelineState,
                  let spec = bridge.getVideoSpec(),
                  let frameBuffer = bridge.getFrameBuffer(),
                  let commandQueue = commandQueue,
                  let renderPassDescriptor = view.currentRenderPassDescriptor else { return }

            // Advance emulation
            bridge.stepFrame()

            let width = Int(spec.width)
            let height = Int(spec.height)

            // Create texture from frame buffer
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm,
                                                                           width: width,
                                                                           height: height,
                                                                           mipmapped: false)
            textureDescriptor.usage = .shaderRead

            guard let texture = device?.makeTexture(descriptor: textureDescriptor) else { return }
            let region = MTLRegionMake2D(0, 0, width, height)
            texture.replace(region: region, mipmapLevel: 0, withBytes: frameBuffer, bytesPerRow: width * 4)

            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }

            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setFragmentTexture(texture, index: 0)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
            renderEncoder.endEncoding()

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}
