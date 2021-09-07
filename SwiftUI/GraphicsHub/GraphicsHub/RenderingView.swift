//
//  RenderingView.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 9/7/21.
//

import SwiftUI
import MetalKit

struct MetalView: View {
    
    var rendererDelegate: RendererDelegate
    
    var body: some View {
        RenderingView(delegate: rendererDelegate)
    }
    
}

protocol RenderHandler {
    
    var renderer: Renderer { get set }
    
}

extension RenderHandler {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.mtkView(view, drawableSizeWillChange: size)
    }
    
    func draw(in view: MTKView) {
        renderer.iterate(in: view)
    }
    
}

class RendererDelegate: MTKView {
    
    var renderer: Renderer
    
    init(renderer: Renderer) {
        self.renderer = renderer
        super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: iOS
#if os(iOS)
import UIKit
struct RenderingView: UIViewRepresentable {
    
    var delegate: RendererDelegate
    
    func makeUIView(context: Context) -> some RendererDelegate {
        return delegate
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        delegate.renderer.iterate(in: delegate)
    }
    
}
#else
//MARK: MacOS
import Cocoa

struct RenderingView: NSViewRepresentable {
    
    var delegate: RendererDelegate
    
    func makeNSView(context: Context) -> some RendererDelegate {
        return delegate
    }
    
    func updateNSView(_ uiView: NSViewType, context: Context) {
        delegate.renderer.iterate(in: delegate)
    }
    
}
#endif


struct MeatlView_Previews: PreviewProvider {
    
    static var previews: some View {
        MetalView(rendererDelegate: RendererDelegate(renderer: Renderer(size: CGSize(width: 512, height: 512))))
    }
    
}
