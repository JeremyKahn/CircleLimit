//
//  GradientColorTriangle.swift
//  ColorStudent
//
//  Created by Jeremy Kahn on 10/10/15.
//  Copyright © 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

class ColorTriangle  {
    
    var colorVertices: [UIColor]
    var spatialVertices: [CGPoint]
    
    init(colorVertices: [UIColor], spatialVertices: [CGPoint]) {
        self.colorVertices = colorVertices
        self.spatialVertices = spatialVertices
    }
    
    func weightedAverageVertex(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        let a = x * spatialVertices[0]
        let b = y * spatialVertices[1]
        let c = (1 - x - y) * spatialVertices[2]
        return a + b + c
    }
    
    func weightedAverageColor(_ x: CGFloat, _ y: CGFloat) -> UIColor {
        let weights = [x, y, 1 - x - y]
        return weightedColor(weights, colors: colorVertices)
    }
}


func drawColorBar(fromPoint startPoint: CGPoint, toPoint endPoint: CGPoint, withColor color: UIColor) {
    drawGradient(fromPoint: startPoint, toPoint: endPoint, fromColor: color, toColor: color)
}

func drawGradient(fromPoint startPoint: CGPoint, toPoint endPoint: CGPoint, fromColor: UIColor, toColor: UIColor) {
    let context = UIGraphicsGetCurrentContext()
    
    let color0 = fromColor.cgColor
    let color1 = toColor.cgColor
    
    let colorspace = CGColorSpaceCreateDeviceRGB()
    
    let gradient = CGGradient(colorsSpace: colorspace,
        colors: [color0, color1] as CFArray, locations: nil)
    
    context?.drawLinearGradient(gradient!,
        start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
}


class GradientColorTriangle: ColorTriangle {
    
    func addClipToTriangle(_ vertices: [CGPoint]) {
        let path = UIBezierPath()
        path.move(to: vertices.first!)
        for v in vertices[1..<vertices.count] {
            path.addLine(to: v)
        }
        path.close()
        path.lineWidth = 0
        path.addClip()
    }
    
    // Returns c parallel to the line through a and b to c', so that a, b, and c' form a right triangle with a right angle at a.
    func toRightTriangle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGPoint {
        let e = b - a
        let ee = dotProduct(c - a, e) / e.abs2
        return c - ee * e
        
    }
        
    // Draws a gradient from the side through ab to c, with axis orthogonal to ab, clipped to lie only in abc
    func drawTriangleGradient(_ a: CGPoint, b: CGPoint, c: CGPoint, abColor: UIColor, cColor: UIColor) {
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        addClipToTriangle([a, b, c])
        drawGradient(fromPoint: a, toPoint: toRightTriangle(a, b, c), fromColor: abColor, toColor: cColor)
        context?.restoreGState()
    }
    
    func drawTriangleGradientFromZeroToOneAndTwo(_ v: [CGPoint], fromColor: UIColor, toColor: UIColor) {
        let (c, a, b) = (v[0], v[1], v[2])
        drawTriangleGradient(a, b: b, c: c, abColor: toColor, cColor: fromColor)
    }
    
    // works by dividing the triangle into 4 smaller triangles (by the lines throught the midpoints) and then drawing each in turn
    func draw() {
        var centerVertices: Array<CGPoint> = Array<CGPoint>(repeating: CGPoint(), count: 3)
        var centerColors: Array<UIColor> = Array<UIColor>(repeating: UIColor(), count: 3)
        for i in 0...2 {
            let x:CGFloat = (i == 0) ? 0 : 0.5
            let y:CGFloat = (i == 1) ? 0 : 0.5
            centerVertices[i] = weightedAverageVertex(x, y)
            centerColors[i] = weightedAverageColor(x, y)
        }
        // draw the middle triangle as an average of three linear gradients
        for i in 0...2 {
            let vertices = centerVertices.rotatedBy(i)
            let colors = colorVertices.rotatedBy(i)
            let laterColors = Array(colors[1...2])
            let averageColor = weightedColor([0.5, 0.5], colors: laterColors)
            let alpha = 1/(i.cg + 1)
            drawTriangleGradientFromZeroToOneAndTwo(vertices, fromColor: averageColor.withAlpha(alpha), toColor: colors[0].withAlpha(alpha))
        }
    
        var vertexTriangle = centerVertices
        var colorTriangle = centerColors
        // draw the three outer triangles
        for i in 0...2 {
            vertexTriangle[i] = spatialVertices[i]
            colorTriangle[i] = colorVertices[i]
            let triangle2 = GradientColorTriangle2(colorVertices: colorTriangle.rotatedBy(i), spatialVertices: vertexTriangle.rotatedBy(i))
            triangle2.draw()
            vertexTriangle[i] = centerVertices[i]
            colorTriangle[i] = centerColors[i]
        }
    }
    
    
}


// This class draws a color triangle by doubling colors 1 and 2 out from color 0 and then drawing two (linear) triangle gradients and averaging them
class GradientColorTriangle2 : GradientColorTriangle {
    
    func thisColorTimesTwo(_ color: UIColor) -> UIColor {
        let (r, g, b, a) = color.rgba
        let (r0, g0, b0, _) = center.rgba
        let (r1, g1, b1) = (2 * r - r0, 2 * g - g0, 2 * b - b0)
        return UIColor(red: r1, green: g1, blue: b1, alpha: a)
    }
    
    var center: UIColor {
        return colorVertices[0]
    }
    
    override func draw() {
        drawTriangleGradient(spatialVertices[0], b: spatialVertices[1], c: spatialVertices[2], abColor: colorVertices[0], cColor: thisColorTimesTwo(colorVertices[2]))
        drawTriangleGradient(spatialVertices[0], b: spatialVertices[2], c: spatialVertices[1], abColor: colorVertices[0].withAlpha(0.5), cColor: thisColorTimesTwo(colorVertices[1].withAlpha(0.5)))
    }
}


