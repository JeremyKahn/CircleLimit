//
//
//  CircleViewController.swift
//  CircleLimit
//
//  Created by Jeremy Kahn on 7/19/15.
//  Copyright (c) 2015 Jeremy Kahn. All rights reserved.
//

import UIKit

enum TouchType {
    case began
    case moved
    case ended
}

struct LocatedObject {
    var object: HDrawable
    var location: LocationData
    
    func copy() -> LocatedObject {
        return LocatedObject(object: object.copy(), location: location)
    }
}

/// Holds the data for a point matched (clicked on) in a polyline
struct MatchedPoint {
    
    /// The index of the point in the array of points in the polyline
    var index: Int
    
    var polyline: HyperbolicPolyline
    
    /// The mask *being applied* to the point in the polygon
    var mask: HyperbolicTransformation
    
    /// Moves the point *as it appears* to the point z
    func moveTo(_ z: HPoint) {
        polyline.movePointAtIndex(index, to: mask.inverse.appliedTo(z))
    }
    
    /// The matching point **as it appears**
    var matchingPoint: HPoint {
        return mask.appliedTo(polyline.points[index])
    }
    
    func cleanUp() {
        polyline.removeRepeatedPoints()
        polyline.updateAndComplete()
    }
}


class CircleViewController: UIViewController, PoincareViewDataSource, UIGestureRecognizerDelegate, ColorPickerDelegate, EnterGroupDelegate {
    
    var enterGroupString: String = "" {
        didSet {
            print("enterGroupString: \(enterGroupString)")
            do {
                let newPants = try placeholders(conway: enterGroupString)
                surface = surfaceFromPlaceholders(newPants)
                setUpGroupAndGuidelinesForTheSurface()
                poincareView.setNeedsDisplay()
            } catch BadConway.badParse {
                print("Bad Conway string: " + enterGroupString)
            } catch BadConway.nonNegativeEuler {
                print("Orbifold must have negative Euler characteristic")
            } catch {
                print("Unknown error: \(error)")
                fatalError()
            }
        }
    }
    
    enum Mode {
        case usual
        case drawing
        case moving
        case cuffEditing
    }
    
    // MARK: Basic overrides
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: Flags
    var drawing = true
    
    var suppressTouches: Bool {
        return !drawing || changingColor || formingPolygon
    }
    
    var formingPolygon: Bool {
        return newCurve != nil
    }
    
    // MARK: Guidelines
    var guidelines: [LocatedObject] {
        return surface.generalGuidelines + surface.cuffGuidelines
    }
    
    var drawGuidelines = true
    
    // MARK: Arrays of objects
    var drawObjects: [LocatedObject] = []
    
    var oldDrawObjects: [LocatedObject] = [] {
        didSet {
            //            print("There are now \(oldDrawObjects.count) old draw objects")
        }
    }
    
    var undoneObjects: [LocatedObject] = []
    
    // MARK: For moving the points
    // TODO: Initialize these properly from the fixed points in the hexagons
    var fixedPoints: [LocatedObject] = []
    
    var touchDistance: Double {
        let m = Double(multiplier)
        let baseTouchDistance = 0.2
        let exponent = 0.25
        return baseTouchDistance/pow(m, 1 - exponent)
    }
    
    // MARK: Stuff to edit pants
    /// The surface that determines the group
    var surface: Surface!
    
    var canEditPants: Bool {
        return drawGuidelines
    }
    
    var editingPants: Bool {
        return cuffToEdit != nil
    }
    
    // We need this in order to maintain the parallel arrays of cuffGuidelines and cuffArray
    var cuffEditIndex: Int? {
        didSet {
            if let i = cuffEditIndex {
                surface.cuffGuidelines[i].object.lineColor = UIColor.red
            } else if let i = oldValue {
                surface.cuffGuidelines[i].object.lineColor = UIColor.black
            }
        }
    }
    
    var cuffToEdit: Cuff? {
        if let i = cuffEditIndex {
            return surface.cuffArray[i]
        } else {
            return nil
        }
    }
    
    var cuffLengths = Array<Double>(repeating: acosh(2.0), count: 3)
    
    var minLogScaleChange = 0.025
    
    // MARK: Parameters for making the group
    let shortGroupGenerationTimeLimit = 75
    
    let longGroupGenerationTimeLimit = 250
    
    var groupGenerationTimeLimit = 250
    
    // MARK: For PoincareViewDataSource
    var objectsToDraw: [LocatedObject] {
        var fullDrawObjects = drawGuidelines ? guidelines : []
        fullDrawObjects += drawObjects
        if newCurve != nil {
            fullDrawObjects.append(LocatedObject(object: newCurve!, location: location))
        }
        return fullDrawObjects
    }
    
    var groupSystemToDraw: GroupSystem {
        var result: GroupSystem = []
        for object in objectsToDraw {
            var actions: [Action] = []
            let masks = surface.visibleMasks(object: object.object, location: object.location, radius: cutoffDistance)
            for M in masks {
                actions.append(Action(M: M))
            }
            result.append((object.object, actions))
        }
        if showComputationLines {
            for line in surface.baseHexagon.computationLines {
                result.append((line, [Action(M: mask)]))
            }
        }
        return result
    }
    
    var multiplier = CGFloat(1.0)
    
    var mode : Mode = .usual {
        didSet {
            print("Mode changed to \(mode)", when: tracingGroupMaking)
        }
    }
    
    func cutOffDistanceForAbsoluteCutoff(_ cutoffAbs: Double) -> Double {
        let scaleCutoff = Double(2/multiplier)
        let lesserAbs = min(scaleCutoff, cutoffAbs)
        return absToDistance(lesserAbs)
    }
    
    var cutoffDistance: Double {
        return cutOffDistanceForAbsoluteCutoff(cutoff[mode]!)
    }
    
    // MARK: Stuff from the poincareView
    var toPoincare : CGAffineTransform {
        return poincareView.tf.inverted()
    }
    
    var scale: CGFloat {
        return poincareView.scale
    }
    
    // MARK: From the surface
    // It seems that we just want to plot the points with respect to the base hexagon
    var location: LocationData {
        return surface.baseHexagon.location
    }
    
    var mask: HTrans {
        return surface.mask
    }
    
    // MARK: - Get the group you want
    func selectElements(_ group: [Action], cutoff: Double) -> [Action] {
        let a = group.filter { (M: Action) in M.motion.a.abs < cutoff }
        print("Selected \(a.count) elements at distance " + absToDistance(cutoff).nice, when: tracingGroupMaking)
        return a
    }
    
    // Change these values to determine the size of the various groups
    var cutoff : [Mode : Double] = [.usual : 0.98, .moving : 0.8, .drawing : 0.9, .cuffEditing: 0.8]
    
    func groupSystem(cutoffDistance distance: Double, objects: [LocatedObject]) -> GroupSystem {
        return groupSystem(cutoffDistance: distance, center: HPoint(), objects: objects, useMask: true)
    }
    
    // This one is intended for touch matching
    func groupSystem(cutoffDistance distance: Double, center: HPoint, objects: [LocatedObject]) -> GroupSystem {
        return groupSystem(cutoffDistance: distance, center: center, objects: objects, useMask: false)
    }
    
    func groupSystem(cutoffDistance distance: Double, center: HPoint, objects: [LocatedObject], useMask: Bool) -> GroupSystem {
        var result: GroupSystem = []
        for object in objects {
            let masks = surface.visibleMasks(object: object.object, location: object.location, radius: distance, center: center, useMask: useMask)
            result.append((object.object, masks.map() {Action(M: $0)}))
        }
        return result
    }
    
    
    // MARK: - Undo and redo
    // TODO: Undo with a shake, clear picture...with what?
    struct State {
        var completedObjects: [LocatedObject]?
        var newCurve: HyperbolicPolyline?
    }
    
    var stateStack: [State] = []
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            undo()
        }
    }
    
    func undo() {
        print("undo!")
        mode = .usual
        guard stateStack.count > 0 else { return }
        let lastState = stateStack.removeLast()
        if let previousObjects = lastState.completedObjects {
            drawObjects = previousObjects
        }
        newCurve = lastState.newCurve
        poincareView.setNeedsDisplay()
    }
    
    func redo() {
        print("redo")
        mode = .usual
        guard undoneObjects.count > 0 else {return}
        drawObjects.append(undoneObjects.removeLast())
        poincareView.setNeedsDisplay()
    }
    
    
    func clearPicture() {
        print("In clearPicture with \(guidelines.count) guidelines")
        drawObjects = []
        newCurve = nil
        poincareView.setNeedsDisplay()
    }
    
    
    // MARK: - Adding points and drawing
    let drawRadius = 0.99
    
    
    func hPoint(_ rawLocation: CGPoint) -> HPoint? {
        var thing = rawLocation
        thing = thing.applying(toPoincare)
        let (x, y) = (Double(thing.x), Double(thing.y))
        //        print("New point: " + x.nice() + " " + y.nice())
        if x * x + y * y < drawRadius * drawRadius {
            let z = HPoint(x + y.i)
            return mask.inverse.appliedTo(z)
        }
        else {
            return nil
        }
    }
    
    
    func makeDot(_ rawLocation: CGPoint) {
        if let p = hPoint(rawLocation) {
            drawObjects.append(LocatedObject(object: HyperbolicDot(center: p), location: location))
            poincareView.setNeedsDisplay()
        }
    }
    
    var touchPoints : [CGPoint] = []
    
    var newCurve : HyperbolicPolyline?
    
    func returnToUsualMode() {
        guard drawing else { return }
        mode = .usual
        undoneObjects = []
        guard let curve = newCurve else { return }
        curve.complete()
        print("Appending a curve with \(curve.points.count) points")
        stateStack = stateStack.filter {$0.completedObjects != nil}
        stateStack.append(State(completedObjects: drawObjects, newCurve: nil))
        newCurve = nil
        drawObjects.append(LocatedObject(object: curve, location: location))
        poincareView.setNeedsDisplay()
    }
    
    var printingTouches = true
    
    func nearbyPointsTo(_ point: HPoint, withinDistance distance: Double) -> [MatchedPoint] {
        let objects = drawObjects.filter() { $0.object is HyperbolicPolyline }
        let g = groupSystem(cutoffDistance: distance, center: point, objects: objects)
        var matchedPoints: [MatchedPoint] = []
        for (object, group)  in g {
            let polyline = object as! HyperbolicPolyline
            
            for a in group {
                let indices = polyline.pointsNear(point, withMask: a.motion, withinDistance: distance)
                let matched = indices.map { MatchedPoint(index: $0, polyline: polyline, mask: a.motion) }
                matchedPoints += matched
            }
        }
        return matchedPoints
    }
    
    var matchedPoints: [MatchedPoint] = []
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan", when: tracingGesturesAndTouches)
        super.touchesBegan(touches, with: event)
        guard touches.count == 1 else {return}
        if suppressTouches {return}
        print("Saving objects", when: tracingGesturesAndTouches)
        oldDrawObjects = drawObjects.map { $0.copy() }
        mode = .moving
        if let touch = touches.first {
            if let z = hPoint(touch.location(in: poincareView)) {
                let distance = touchDistance
                matchedPoints = nearbyPointsTo(z, withinDistance: distance)
                
                if matchedPoints.count == 0 {
                    addPointToArcs(z)
                }
            }
        }
        touchesMoved(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //        if printingTouches { print("touchesMoved") }
        super.touchesMoved(touches, with: event)
        guard touches.count == 1 else {return}
        if suppressTouches {return}
        if let touch = touches.first {
            if let z = hPoint(touch.location(in: poincareView)) {
                for m in matchedPoints {
                    m.moveTo(z)
                }
            }
        }
        poincareView.setNeedsDisplay()
    }
    
    // TODO: Make points nearby the last touch jump to it
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesEnded", when:  tracingGesturesAndTouches)
        guard touches.count == 1 else {return}
        super.touchesEnded(touches, with: event)
        if suppressTouches {return}
        touchesMoved(touches, with: event)
        if let touch = touches.first {
            if var z = hPoint(touch.location(in: poincareView)) {
                let g = groupSystem(cutoffDistance: touchDistance, center: z, objects: fixedPoints)
                // THIS WILL BE UNDEFINED if g has more than one element
                for (object, group) in g {
                    for action in group {
                        z = action.motion.appliedTo(object.centerPoint)
                        for m in matchedPoints {
                            m.moveTo(z)
                        }
                    }
                }
                
                let nearbyPointsToEndpoint = nearbyPointsTo(z, withinDistance: touchDistance)
                for m in nearbyPointsToEndpoint {
                    m.moveTo(z)
                }
            }
        }
        for m in matchedPoints {
            m.cleanUp()
        }
        mode = .usual
        stateStack.append(State(completedObjects: oldDrawObjects, newCurve: nil))
        oldDrawObjects = []
        poincareView.setNeedsDisplay()
    }
    
    
    // MARK: Adding a point to a line
    func addPointToArcs(_ z: HPoint) {
        let objects = drawObjects.filter() { $0.object is HyperbolicPolyline }
        
        let g = groupSystem(cutoffDistance: touchDistance, center: z, objects: objects)
        
        for (object, group) in g {
            let polyline = object as! HyperbolicPolyline
            
            var instructions: [(Int, HPoint, HyperbolicTransformation)] = []
            for a in group {
                let indices = polyline.sidesNear(z, withMask: a.motion, withinDistance: touchDistance)
                if indices.count == 0 { continue }
                if indices.count > 1 {
                    print("Matched more than one side in a single polyline: \(indices)")
                }
                for index in indices {
                    instructions.append((index, a.motion.inverse.appliedTo(z), a.motion))
                }
            }
            polyline.insertPointsAfterIndices(instructions.map({($0.0, $0.1)}))
            instructions.sort() { $0.0 < $1.0 }
            for i in 0..<instructions.count {
                let (index, _ , pointMask) = instructions[i]
                matchedPoints.append(MatchedPoint(index: index + i + 1, polyline: polyline, mask: pointMask))
            }
        }
    }
    
    // MARK: - Color Picker Preview Source and Delegate
    var colorToStartWith: UIColor = UIColor.blue
    
    var changingColor = false
    
    struct ColorChangeInformation {
        var polygon: HyperbolicPolygon
        var colorNumber: ColorNumber
        var changeColorTableEntry: Bool
    }
    
    // Slightly naughty to use an implicitly unwrapped optional
    var colorChangeInformation: ColorChangeInformation!
    
    func applyColor(_ color: UIColor) {
        let polygon = colorChangeInformation.polygon
        if colorChangeInformation.changeColorTableEntry {
            polygon.fillColorTable[colorChangeInformation.colorNumber] = color
        } else {
            polygon.fillColor = color
        }
    }
    
    func applyColorAndReturn(_ color: UIColor) {
        applyColor(color)
        dismiss(animated: true, completion: nil)
        cancelEffectOfTouches()
        changingColor = false
        poincareView.setNeedsDisplay()
    }
    
    // TODO: Fix the problem with the segue
    func setColor(_ polygon: HyperbolicPolygon, withAction action: Action) {
        changingColor = true
        cancelEffectOfTouches()
        let colorNumber = action.action.mapping[ColorNumber.baseNumber]!
        colorToStartWith = polygon.fillColorTable[colorNumber]!
        colorChangeInformation = ColorChangeInformation(polygon: polygon, colorNumber: colorNumber, changeColorTableEntry: true)
        performSegue(withIdentifier: "chooseColor", sender: self)
    }
    
    // MARK: - Gesture recognition
    
    @IBOutlet var singleTapRecognizer: UITapGestureRecognizer!
    
    @IBOutlet var doubleTapRecognizer: UITapGestureRecognizer!
    
    @IBOutlet var panRecognizer: UIPanGestureRecognizer!
    
    @IBOutlet var pinchRecognizer: UIPinchGestureRecognizer!
    
    @IBOutlet var longPressRecognizer: UILongPressGestureRecognizer!
    
    @IBOutlet var twoTouchLongPress: UILongPressGestureRecognizer!
    
    
    //    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    //        return otherGestureRecognizer === swipeRecognizer
    //    }
    
    //    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    //        return gestureRecognizer === swipeRecognizer
    //    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == longPressRecognizer {
            return gestureRecognizer.numberOfTouches == 1
        } else {
            return true
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        switch gestureRecognizer {
        case singleTapRecognizer:
            switch otherGestureRecognizer {
            case doubleTapRecognizer, pinchRecognizer, panRecognizer:
                return true
            default: return false
            }
        case longPressRecognizer:
            switch otherGestureRecognizer {
            case pinchRecognizer, panRecognizer:
                return true
            default: return false
            }
        default:
            return false
        }
    }
    
    
    
    @IBAction func simplePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            drawing = false
            //            newCurve = nil
            mode = mode == .drawing ? .drawing :  .moving
            cancelEffectOfTouches()
            if let cuff = cuffToEdit {
                prepareCuffForChanges(cuff)
            }
        case .changed:
            let translation = gesture.translation(in: poincareView)
            if translation == CGPoint.zero { return }
            gesture.setTranslation(CGPoint.zero, in: poincareView)
           //            println("Raw translation: \(translation.x, translation.y)")
            if let cuff = cuffToEdit {
                let d = Double(translation.y/scale)
                cuff.twist += d
                recordChangesForCuff(cuff)
            } else {
                var a = Complex64(Double(translation.x/scale), Double(translation.y/scale))
                a = a/(a.abs+1) // This prevents bad transformations
                let M = HyperbolicTransformation(a: -a)
                //            println("Moebius translation: \(M)")
                surface.applyToMask(M: M)
            }
            poincareView.setNeedsDisplay()
        case .ended:
            mode = mode == .drawing ? .drawing : .usual
            if canRecomputeMask {
                surface.recomputeMask()
            }
            drawing = true
            if cuffToEdit != nil {
                turnOffChangingForCuff()
            }
            poincareView.setNeedsDisplay()
        default: break
        }
    }
    
    @IBAction func singleTap(_ sender: UITapGestureRecognizer) {
        //        print("tapped")
        let z = hPoint(sender.location(in: poincareView))
        if z == nil {
            print("toggling guidelines")
            drawGuidelines = !drawGuidelines
            mode = .usual
        } else if newCurve != nil {
            stateStack.append(State(completedObjects: nil, newCurve: (newCurve!.copy() as! HyperbolicPolyline)))
            newCurve!.addPoint(z!)
        } else if canEditPants && !editingPants {
            let g = groupSystem(cutoffDistance: touchDistance, center: z!, objects: surface.cuffGuidelines)
            SEARCH: for i in 0..<surface.cuffArray.count {
                let (object, group) = g[i]
                if let line = object as? HyperbolicPolyline {
                    for action in group {
                        if line.sidesNear(z!, withMask: action.motion, withinDistance: touchDistance).count > 0 {
//                            mask = mask.following(action.motion)
                            cuffEditIndex = i
                            // Once we match one cuff we no longer look for the others
                            break SEARCH
                        }
                    }
                }
            }
        }
        poincareView.setNeedsDisplay()
    }
    
    
    @IBAction func doubleTap(_ sender: UITapGestureRecognizer) {
        if newCurve == nil {
            let z = hPoint(sender.location(in: poincareView))
            guard z != nil else { return }
            newCurve = HyperbolicPolygon(z!)
            stateStack.append(State(completedObjects: nil, newCurve: nil))
            mode = .drawing
            poincareView.setNeedsDisplay()
        } else  {
            switch newCurve!.points.count {
            case 0, 1:
                newCurve = nil
            case 2:
                newCurve = HyperbolicPolyline(newCurve!.points)
            default:
                newCurve!.addPoint(newCurve!.points[0])
            }
            returnToUsualMode()
            poincareView.setNeedsDisplay()
        }
    }
    
    
    @IBAction func threeTouchLongPress(_ sender: UILongPressGestureRecognizer) {
        print("Three touch long press")
        print("Enjoy your day!")
    }
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer) {
        let z = hPoint(sender.location(in: poincareView))
        if let point = z {
            if tracingGesturesAndTouches {
                drawObjects.append(LocatedObject(object: HyperbolicDot(center: point, radius: touchDistance), location: location))
            }
            cancelEffectOfTouches()
            //            addPointToArcs(point)
            let polylines = drawObjects.filter({$0.object is HyperbolicPolyline})
            let g = groupSystem(cutoffDistance: touchDistance, center: point, objects: polylines).reversed()
            // As constructed this just sets the color of the first polygon that matches
            // So if you touch overlapping polygons, or between two polygons, the result is unpredictable
            // It makes some effort to change the highest polygon
            for (object, group) in g {
                let polyline = object as! HyperbolicPolyline
                for action in group {
                    if polyline.sidesNear(point, withMask: action.motion, withinDistance: touchDistance).count > 0 {
                        return
                    }
                }
            }
            OUTER: for (object, group) in g.filter({$0.0 is HyperbolicPolygon}) {
                let polygon = object as! HyperbolicPolygon
                for action in group {
                    if polygon.containsPoint(point, withMask: action.motion) {
                        setColor(polygon, withAction: action)
                        break OUTER
                    }
                }
            }
        }
    }
    
    var canRecomputeMask: Bool {
        return !formingPolygon && !editingPants
    }
    
    
    func prepareCuffForChanges(_ cuff: Cuff) {
        groupGenerationTimeLimit = shortGroupGenerationTimeLimit
    }
    
    func recordChangesForCuff(_ cuff: Cuff) {
        setUpGroupAndGuidelinesForTheSurface()
    }
    
    func turnOffChangingForCuff() {
        groupGenerationTimeLimit = longGroupGenerationTimeLimit
        setUpGroupAndGuidelinesForTheSurface()
        cuffEditIndex = nil
    }
    
    // Should this be split into two separate functions?
    @IBAction func zoom(_ gesture: UIPinchGestureRecognizer) {
        //        println("Zooming")
        switch gesture.state {
        case .began:
            mode = .moving
            drawing = false
            //            newCurve = nil
            cancelEffectOfTouches()
            if let cuff = cuffToEdit {
                prepareCuffForChanges(cuff)
            }
        case .changed:
            if let cuff = cuffToEdit {
                // This prevents repeated requests to make long calculations
                //                if pants.timeToMakeGroup > 3 * abs(log(Double(gesture.scale))) {
                //                    break
                //                }
                if abs(log(Double(gesture.scale))) < minLogScaleChange {
                    break
                }
                print("Rescaling cuff by " + gesture.scale.nice, when: tracingZoom)
                // This changes everything
                cuff.halfLength = cuff.halfLength * gesture.scale.double
                gesture.scale = 1
                recordChangesForCuff(cuff)
            } else {
                let newMultiplier = multiplier * gesture.scale
                multiplier = newMultiplier >= 1 ? newMultiplier : 1
                gesture.scale = 1
            }
        case .ended:
            drawing = true
            mode = .usual
            if editingPants {
                turnOffChangingForCuff()
            }
        default: break
        }
        poincareView.setNeedsDisplay()
    }
    
    
    func cancelEffectOfTouches() {
        if oldDrawObjects.count > 0 {
            print("Restoring objects and cancelling move points", when: tracingGesturesAndTouches)
            drawObjects = oldDrawObjects
            oldDrawObjects = []
            matchedPoints = []
        }
    }
    // MARK: Outlets to other views
    
    @IBOutlet weak var poincareView: PoincareView! {
        didSet {
            poincareView.dataSource = self
        }
    }
    
    
    //      MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "chooseColor":
            changingColor = true
            let triangleViewController = segue.destination as! TriangleViewController
            triangleViewController.delegate = self
        case "enterGroup":
            let enterGroupViewController = segue.destination as! EnterGroupViewController
            enterGroupViewController.delegate = self
        default:
            break
        }
    }
    
    // MARK: Debugging variables
    var drawOnlyHexagonTesselation = false
    
    static var testing = false
    
    var tracingGroupMaking = false
    
    var tracingZoom = true
    
    var tracingGesturesAndTouches = false
    
    var trivialGroup = false
    
    var testType = TestType.t2223
    
    var serious = true
    
    var trivial = false
    
    var showComputationLines = true
}
