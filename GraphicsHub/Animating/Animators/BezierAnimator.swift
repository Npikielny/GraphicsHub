//
//  BezierAnimator.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/6/21.
//

import Foundation

class QuadraticAnimator: LinearAnimator {
    
    override class var name: String { "Quadratic Animator" }
    
    override func getFrame(_ frame: Int) -> Double {
        let frames = input.keyFrames[index]
        if input.keyFrames[index].count >= 3 {
            var a: Int!
            var b: Int!
            var c: Int!
            if frame < frames[2].0 {
                a = 0
                b = 1
                c = 2
            } else {
                c = frames.firstIndex(where: { $0.0 >= frame }) ?? frames.count - 1
                b = c - 1
                a = b - 1
            }
//            if frame >= frames.last!.0 {
//                a = frames.count - 1 - 2
//                b = frames.count - 1 - 1
//                c = frames.count - 1
//            } else if frame <= frames.first!.0 {
//                a = 0
//                b = 1
//                c = 2
//            } else {
//                c = frames.firstIndex(where: { $0.0 >= frame })
//                if c == frames.count - 1 {
//                    b = b - 1
//                }
//                c = b + 1
//                a = b - 1
//            }
            let points = [a, b, c].map { frames[$0] }
            
            let coefficients = Matrix<Double>(Rows: points.map({[pow(Double($0.0), 2), Double($0.0), 1, $0.1]}) ).solve()
            return coefficients[0] * pow(Double(frame), 2) + coefficients[1] * Double(frame) + coefficients[2]
//            return frames[b].1 + pow(1 - t, 2) * (frames[a].1 - frames[b].1) + pow(t, 2) * (frames[c].1 - frames[b].1)
            
        } else {
            return super.getFrame(frame)
        }
    }
    
}
