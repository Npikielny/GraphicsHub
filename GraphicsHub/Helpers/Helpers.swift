//
//  Helpers.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 6/12/21.
//

import Cocoa

extension NSView {
    // https://www.youtube.com/channel/UCuP2vJ6kRutQBfRmdcI92mA
    func addConstraintsWithFormat(format: String, views: NSView...) {
        
        var viewsDictionary = [String: NSView]()
        for (index, view) in views.enumerated(){
            let key = "v\(index)"
            view.translatesAutoresizingMaskIntoConstraints = false
            viewsDictionary[key] = view
        }
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
}

extension NSColor {
    
    convenience init(color: SIMD4<Float>) {
        self.init(red: CGFloat(color.x),
                  green: CGFloat(color.y),
                  blue: CGFloat(color.z),
                  alpha: CGFloat(color.w))
    }
    
    convenience init(vector: SIMD3<Float>) {
        self.init(red: CGFloat(vector.x),
                  green: CGFloat(vector.y),
                  blue: CGFloat(vector.z),
                  alpha: 1)
    }
    
    func toVector() -> SIMD4<Float> {
        return SIMD4<Float>(Float(redComponent),
                            Float(greenComponent),
                            Float(blueComponent),
                            Float(alphaComponent))
    }
    
    func toVector() -> SIMD3<Float> {
        return SIMD3<Float>(Float(redComponent),
                            Float(greenComponent),
                            Float(blueComponent))
    }
    
    convenience init(seed: Int) {
        // Legacy random color generator from:
        // https://github.com/Npikielny/Final-Project/blob/master/finalproject.py
        self.init(vector: SIMD3<Float>(
                    abs(sin(0.89 * Float(seed) + 2.3)),
                    abs(sin(0.44 * Float(seed) + 1.5)),
                    abs(sin(0.25 * Float(seed) + 0.75))))
    }
    
}

extension CGColor {
    
    func toVector() -> SIMD3<Float> {
        if numberOfComponents >= 3 {
            guard let components = components else {
                return SIMD3<Float>(1,1,1)
            }
            return SIMD3<Float>(Float(components[0]),Float(components[1]),Float(components[2]))
        }
        return SIMD3<Float>(1,1,1)
    }
    
}

extension CGPoint {
    
    func toVector() -> SIMD2<Float> {
        return SIMD2<Float>(Float(x),Float(y))
    }
    
    func toInverseVector() -> SIMD2<Float> {
        return SIMD2<Float>(Float(y),Float(x))
    }
    
}


extension CGSize {
    
    static func clamp(value: CGSize, minValue: CGSize, maxValue: CGSize) -> CGSize {
        return Min(size1: maxValue, size2: Max(size1: value, size2: minValue))
    }
    
    static func Min(size1: CGSize, size2: CGSize) -> CGSize {
        return CGSize(width: min(size1.width, size2.width), height: min(size1.height, size2.height))
    }
    
    static func Max(size1: CGSize, size2: CGSize) -> CGSize {
        return CGSize(width: max(size1.width, size2.width), height: max(size1.height, size2.height))
    }
    
}
