//
//  QuadraticAnimator.swift
//  GraphicsHub
//
//  Created by Noah Pikielny on 7/6/21.
//

import Cocoa

class QuadraticAnimator: LinearAnimator {
    
    override class var name: String { "Quadratic Animator" }
    
    override func getFrame(_ frame: Int) -> Double {
        let frames = input.keyFrames[index]
        let closest = frames.firstIndex(where: { $0.0 > frame }) ?? frames.count - 1
        if input.keyFrames[index].count >= 4 && closest > 0 && closest < frames.count - 1 {
            var a: Int!
            var b: Int!
            var c: Int!
            var d: Int!
            if (frame > frames[closest].0) {
                a = closest - 1
                b = closest
                c = closest + 1
                d = closest + 2
            } else if closest == 1{
                return quadratic(a: 0, b: 1, c: 2, frame: frame)
            } else {
                a = closest - 2
                b = closest - 1
                c = closest
                d = closest + 1
            }
            return lerpQuadratic(a: a, b: b, c: c, d: d, frame: frame)
        } else if input.keyFrames[index].count >= 3 {
            var a: Int!
            var b: Int!
            var c: Int!
            if frame < frames[2].0 {
                a = 0
                b = 1
                c = 2
            } else {
                c = closest
                b = c - 1
                a = b - 1
            }
            return quadratic(a: a, b: b, c: c, frame: frame)
        } else {
            return super.getFrame(frame)
        }
    }
    
    func lerpQuadratic(a: Int, b: Int, c: Int, d: Int, frame: Int) -> Double {
        let t = Double(frame - input.keyFrames[index][b].0) / Double(input.keyFrames[index][c].0 - input.keyFrames[index][b].0)
        return quadratic(a: a, b: b, c: c, frame: frame) * (1 - t) + quadratic(a: b, b: c, c: d, frame: frame) * t
    }
    
    func quadratic(a: Int, b: Int, c: Int, frame: Int) -> Double {
        let points = [a, b, c].map { input.keyFrames[index][$0] }
        let matrix = Matrix<Double>(Rows: points.map({[pow(Double($0.0), 2), Double($0.0), 1, $0.1]}) )
        let coefficients = matrix.solve()
        return coefficients[0] * pow(Double(frame), 2) + coefficients[1] * Double(frame) + coefficients[2]
    }
    
}
