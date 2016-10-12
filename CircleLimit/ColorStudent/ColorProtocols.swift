//
//  Protocols.swift
//  ColorStudent
//
//  Created by Jeremy Kahn on 11/7/15.
//  Copyright © 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

protocol ColorPickerPreviewSource {
    
    var preview: UIView { get }
    
    func applyColorToPreview(_ color: UIColor)
    
}

protocol ColorPickerDelegate {
    
    var colorToStartWith: UIColor { get }
    
    func applyColorAndReturn(_ color: UIColor)
    
}

protocol ZoomingColorPickerDelegate: ColorPickerDelegate {
    
    var zoomToStartWith: CGFloat { get }
    
}

class DefaultColorPickerPreviewSource: ColorPickerPreviewSource {
    
    var preview = UIView()
    
    func applyColorToPreview(_ color: UIColor) {
        preview.backgroundColor = color
    }
    
}

class DefaultColorPickerDelegate: ColorPickerDelegate {
    
    var colorToStartWith = UIColor.white
    
    func applyColorAndReturn(_ color: UIColor) {
        print("Chosen color \(color)")
    }
    
}

