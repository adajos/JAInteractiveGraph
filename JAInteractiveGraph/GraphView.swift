//
//  GraphQView.swift
//  JAInteractiveGraph
//
//  Created by Josh Adams on 3/17/16.
//  Copyright © 2016 Adams. All rights reserved.
//

import UIKit


@IBDesignable public class GraphView: UIView {
    
    static var dummyData: [GraphableDataPoint] = [SimpleGraphDataPoint(0, "2004"), SimpleGraphDataPoint(5, "2005"),
                                                  SimpleGraphDataPoint(4, "2006"), SimpleGraphDataPoint(-4, "2007"),
                                                  SimpleGraphDataPoint(-10, "2008"), SimpleGraphDataPoint(7, "2009"),
                                                  SimpleGraphDataPoint(5, "2010")]

    
    // MARK: Stored Properties
    public var delegate: GraphViewDataSourceDelegate? = nil {
        didSet {
            self.graphPoints = self.delegate!.getData()
        }
    }
    
    
    public var graphPoints:[GraphableDataPoint] = GraphView.dummyData {
        didSet {
            self.addPointsIfNeeded()
            self.setNeedsDisplay()
        }
    }
    
    lazy var tapGestureRecognizer: UITapGestureRecognizer = {
        let tapper = UITapGestureRecognizer(target: self, action: #selector(GraphView.tapped))
        tapper.numberOfTapsRequired = 1
        
        return tapper
    }()
    
    lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let panner = UIPanGestureRecognizer(target: self, action: #selector(GraphView.pan))
        return panner
    }()
    
    
    
    
    // MARK: Private Properties
    private var animationDestinationGraphPoints: [GraphableDataPoint]? = nil
    private var yAxisTopLabel: UILabel? = nil
    private var yAxisZeroLabel: UILabel? = nil
    private var yAxisBottomLabel: UILabel? = nil
    
    private var xAxisLabels: [UILabel] = []
    private var displayLink: CADisplayLink? = nil
    private var lastDisplayLinkTimestamp: NSTimeInterval = 0
    
    
    
    var lastLocation :CGPoint!
    var lastPannedGraphPoint: GraphPointView?
    
    
    // MARK: @IBInspectables
    @IBInspectable var maxPossibleValue: Int = 0
    @IBInspectable var minPossibleValue: Int = 0
    @IBInspectable var startColor: UIColor = UIColor(r: 240, g: 60, b: 140)
    @IBInspectable var endColor: UIColor = UIColor(r: 120, g: 210, b: 250)
    @IBInspectable var lineColor: UIColor = UIColor.whiteColor()
    @IBInspectable var pointColor: UIColor = UIColor(r: 10, g: 235, b: 180)
    @IBInspectable var graphLineWidth: CGFloat = 1
    @IBInspectable var verticalPadding: CGFloat = 30
    @IBInspectable var cornerRadii: CGFloat = 8
    @IBInspectable var pointHorizontalPadding: CGFloat = 35
    @IBInspectable var pointCircleSize : CGFloat = 22
    @IBInspectable var axesLineColor: UIColor = UIColor(white: 1.0, alpha: 1.0)
    @IBInspectable var axesLineWidth: CGFloat = 2
    @IBInspectable var lineStyle: Int = 0
    @IBInspectable var fillUnderCurve: Bool = true
    @IBInspectable var curveFillStartColor: UIColor = UIColor(r: 255, g: 255, b: 255, alpha: 0.3)
    @IBInspectable var curveFillEndColor: UIColor = UIColor(colorLiteralRed: 255.0, green: 255.0, blue: 255.0, alpha: 0.7)
    @IBInspectable var showYAxisLabels: Bool = true
    @IBInspectable var yAxisLabelTextColor: UIColor = UIColor.whiteColor()
    @IBInspectable var yAxisLabelFontSize: CGFloat = 15
    @IBInspectable var showXAxisLabels: Bool = true
    @IBInspectable var showXAxisLabelsLowestAndHighestOnly: Bool = false
    @IBInspectable var xAxisLabelTextColor: UIColor = UIColor.whiteColor()
    @IBInspectable var xAxisLabelFontSize: CGFloat = 15
    
    
    // MARK: UIView overrides/lifecycle stuff
    override public func addSubview(view: UIView) {
        super.addSubview(view)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.addGestureRecognizer(tapGestureRecognizer)
        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    override init(frame: CGRect) {
//        self.graphPoints = GraphView.dummyData
        super.init(frame: frame)
        
    }
    
    override public func prepareForInterfaceBuilder() {
        self.addPointsIfNeeded()
    }
    
    override public func awakeFromNib() {
        //Needed this to get dummy data to show in the simulator when running it
//        self.addPoints()
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.setNeedsDisplay()
    }

}

// MARK: Public funcs
extension GraphView {
    
    public func reloadData() {
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
        
        yAxisBottomLabel = .None
        yAxisTopLabel = .None
        yAxisZeroLabel = .None
        
        //TODO: have to clean out any xAxis labels that get added in the future.
        
        if let delegate = delegate {
            self.graphPoints = delegate.getData()
        }
        else {
            self.graphPoints = []
        }
    }
    
    func animateGraphPointsToValues(newGraphPoints: [GraphableDataPoint], duration: NSTimeInterval) {
        guard self.graphPoints.count == newGraphPoints.count else {
            return
        }
        //TODO: apparently CADisplayLink stops running if the user presses the Home button.
        //Need to find a way to detect that, remove the CADisplayLink and just go to the final values.
        self.animationDestinationGraphPoints = newGraphPoints
        self.displayLink = CADisplayLink(target: self, selector: #selector(GraphView.updateGraphPointLocationForAnimation))
        self.displayLink!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
}

//MARK: GestureRecognzier handlers
extension GraphView {
    //MARK: Gesture Recognizer stuff
    
    func tapped(gestureRecognizer: UITapGestureRecognizer) {
        
        
        let tapLocation = gestureRecognizer.locationInView(self)
        let nearestPointView = self.subviews.sort { view1, view2 in
            return abs(view1.center.x - tapLocation.x) < abs(view2.center.x - tapLocation.x)
            }.first
        
        NSLog("tappedLocation: \(tapLocation) nearestPointView.center.y \(nearestPointView?.center.y)")
        
        if let nearestPointView = nearestPointView as? GraphPointView {
            var yValueToUse :CGFloat = tapLocation.y
            
            if tapLocation.y > self.bounds.height - verticalPadding {
                yValueToUse = self.bounds.height - verticalPadding
            }
            else if tapLocation.y < self.bounds.origin.y + (2 * verticalPadding ){
                yValueToUse = 0
            }
            
            nearestPointView.center = CGPoint(x: nearestPointView.center.x, y: yValueToUse)
            pointMoved(nearestPointView)
        }
        
    }
    
    func pan(gestureRecognizer: UIPanGestureRecognizer) {
        NSLog("pan:")
        
        if gestureRecognizer.state == .Began {
            lastLocation = gestureRecognizer.locationInView(self)
            lastPannedGraphPoint = self.subviews.sort {view1, view2 in
                return abs(view1.center.x - lastLocation.x) < abs(view2.center.x - lastLocation.x)
                }.first as? GraphPointView
            
            return
        }
        else if gestureRecognizer.state == .Changed {
            
            let currentLocation = self.GetNewBoundaryRestrictedPointForGraphPoint(gestureRecognizer)
            if let thePoint = lastPannedGraphPoint {
                thePoint.frame = CGRect(x:thePoint.frame.origin.x, y:currentLocation.y, width:thePoint.frame.width, height:thePoint.frame.height)
                lastLocation.y = currentLocation.y
            }
            
        }
        else if gestureRecognizer.state == .Ended || gestureRecognizer.state == .Cancelled {
            let stopLocation = self.GetNewBoundaryRestrictedPointForGraphPoint(gestureRecognizer)
            if let thePoint = lastPannedGraphPoint {
                thePoint.frame = CGRect(x:thePoint.frame.origin.x, y:stopLocation.y, width:thePoint.frame.width, height:thePoint.frame.height)
                
            }
        }
        
        pointMoved(lastPannedGraphPoint!)
    }
    
    
    func GetNewBoundaryRestrictedPointForGraphPoint(gestureRecognizer: UIPanGestureRecognizer) -> CGPoint {
        var newLocation = gestureRecognizer.locationInView(self)
        
        if newLocation.y < 0
        {
            newLocation.y = 0
        }
        
        if newLocation.y > self.bounds.height - verticalPadding //self.frame.height - (2 * self.verticalPadding)
        {
            newLocation.y = self.bounds.height - verticalPadding//self.frame.height - (2 * self.verticalPadding)
        }
        return newLocation
    }
}

extension GraphView {
    //MARK: Drawing stuff
    override public func drawRect(rect: CGRect) {
        clipGraphCorners(rect)
        
        //2 - get the current context
        let context = UIGraphicsGetCurrentContext()
        drawGradientBackground(rect, context!)
        
        
        if (showXAxisLabels) {
            drawXAxisLabels(rect)
        }
        
        let graphPath = drawGraphLine(rect)
        drawGradientUnderCurve(context!, graphPath, rect)
        
        
        //draw the line on top of the clipped gradient
        graphPath.lineWidth = graphLineWidth
        graphPath.stroke()
        drawPoints(rect)
        drawGraphAxes(rect)
    }
    
    func drawGraphAxes(rect: CGRect) {
        let height = rect.height
        let width = rect.width
        let margin: CGFloat = pointHorizontalPadding
        let topBorder: CGFloat = verticalPadding
        let bottomBorder: CGFloat = verticalPadding
        
        lineColor.setFill()
        lineColor.setStroke()
        //Draw horizontal graph lines on the top of everything
        let linePath = UIBezierPath()
        
        //top line
        linePath.moveToPoint(CGPoint(x:margin, y: topBorder))
        linePath.addLineToPoint(CGPoint(x: width - margin, y:topBorder))
        
        //draw line for zero if it makes sense.
        if minPossibleValue < 0 {
            linePath.moveToPoint(CGPoint(x:margin, y: calculateYPoint(0, self.frame) ))
            linePath.addLineToPoint(CGPoint(x:width - margin, y: calculateYPoint(0, self.frame)))
        }
        
        //bottom line
        linePath.moveToPoint(CGPoint(x:margin, y:height - bottomBorder))
        linePath.addLineToPoint(CGPoint(x:width - margin, y:height - bottomBorder))
        
        
        axesLineColor.setStroke()
        
        linePath.lineWidth = axesLineWidth
        linePath.stroke()
        
        drawYAxisLabelsIfNeeded()
    }
    
    private func drawYAxisLabelsIfNeeded() {
        guard showYAxisLabels else {
            return
        }
        
        if yAxisTopLabel == nil {
            yAxisTopLabel = configureYAxisLabel("\(maxPossibleValue)")
        }
        
        yAxisTopLabel!.frame = CGRect(x: -10, y: verticalPadding - 15, width: 30, height: 30)
        
        if minPossibleValue < 0 {
            if yAxisZeroLabel == nil {
                yAxisZeroLabel = configureYAxisLabel("0")
            }
            
            yAxisZeroLabel!.frame = CGRect(x: -10, y: calculateYPoint(0, self.frame) - 15, width: 30, height: 30)
        }
        
        if yAxisBottomLabel == nil {
            yAxisBottomLabel = configureYAxisLabel("\(minPossibleValue)")
        }
        
        yAxisBottomLabel!.frame = CGRect(x: -10, y: self.bounds.height - verticalPadding - 15, width: 30, height: 30)
    }
    
    private func configureYAxisLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = yAxisLabelTextColor
        label.font = UIFont.systemFontOfSize(yAxisLabelFontSize)
        label.textAlignment = .Right
        self.addSubview(label)
        return label
    }
    
    
    func calculateXPoint(column: Int, _ rect: CGRect) -> CGFloat {
        let width = rect.width
        let margin:CGFloat = self.pointHorizontalPadding
        //Calculate gap between points
        let spacer = (width - margin * 2 - 4) / CGFloat((self.graphPoints.count - 1))
        var x:CGFloat = CGFloat(column) * spacer
        x += margin + 2
        
        return x
    }
    
    func calculateYPoint(graphPoint: Int, _ rect: CGRect) -> CGFloat {
        let height = rect.height
        let topBorder: CGFloat = self.verticalPadding
        let bottomBorder: CGFloat = self.verticalPadding
        let graphHeight = height - topBorder - bottomBorder
        let halfGraphHeight: CGFloat = CGFloat(graphHeight) / 2
        
        var retVal: CGFloat = 0
        
        switch (self.maxPossibleValue, self.minPossibleValue) {
        case (_, let min) where min == 0:
            retVal = graphHeight - (CGFloat(graphPoint) * (graphHeight / CGFloat(self.maxPossibleValue))) + topBorder
            
        case (let max, let min) where min < 0 && abs(max) == abs(min):
            retVal = halfGraphHeight - (CGFloat(graphPoint) * halfGraphHeight / CGFloat(self.maxPossibleValue)) + topBorder
            
        default:
            let graphValueSpan = CGFloat(self.maxPossibleValue) - CGFloat(self.minPossibleValue)
            let valueIsPctOfRange = (1.0 - ((CGFloat(graphPoint) + abs(CGFloat(self.minPossibleValue))) / graphValueSpan)) * graphValueSpan
            let screenPointsPerGraphValue = graphHeight / graphValueSpan
            
            retVal = (valueIsPctOfRange * screenPointsPerGraphValue) + topBorder
        }
        
        if retVal > self.bounds.height - verticalPadding {
            retVal = self.bounds.height - verticalPadding
        }
        
        //        NSLog("in calculateYPoint, retVal is \(retVal)")
        return retVal
    }
    
    func convertScreenPointsToGraphPointValue(graphPoint: GraphPointView) -> Int {
        return convertScreenCoordinateToGraphPointValue(graphPoint.center)
    }
    
    func convertScreenCoordinateToGraphPointValue(point: CGPoint) -> Int {
        let topBorder:CGFloat = verticalPadding
        let bottomBorder:CGFloat = verticalPadding
        let graphHeight = self.bounds.height - topBorder - bottomBorder
        let halfGraphHeight : Int = Int(graphHeight) / 2
        var retVal = 0
        
        switch (self.maxPossibleValue, self.minPossibleValue) {
        case (_, let min) where min == 0:
            retVal = Int(round((graphHeight - point.y) / graphHeight * CGFloat(maxPossibleValue)))
        case (let max, let min) where min < 0 && abs(max) == abs(min):
            retVal =  -((Int(round(point.y)) * maxPossibleValue) / halfGraphHeight) + maxPossibleValue
        default:
            let graphValueSpan = CGFloat(self.maxPossibleValue) - CGFloat(self.minPossibleValue)
            retVal =  Int(round(-(point.y * (graphValueSpan / (self.bounds.height - verticalPadding)) - graphValueSpan + CGFloat(abs(self.minPossibleValue)))))
        }
        
        NSLog("in convertScreenPointsToGraphPointValue, retVal is \(retVal)")
        
        return retVal
    }
    
    func drawXAxisLabels(rect: CGRect) {
        for (index, point) in self.graphPoints.enumerate() {
            if showXAxisLabelsLowestAndHighestOnly && (index != 0 && index != self.graphPoints.count - 1) {
                continue
            }
            let label = createXAxisLabelIfNeeded(index, point)
            setPositionForXAxisLabel(index, point, label, rect)
        }
    }
    
    func createXAxisLabelIfNeeded(index: Int, _ point: GraphableDataPoint) -> UILabel {
        
        
       if self.xAxisLabels.count < index + 1 {
            return createAxisLabel(point)
        }
        
        return self.xAxisLabels[index]
        
    }
    
    func createAxisLabel(point: GraphableDataPoint) -> UILabel {
        let axisLabelFont : UIFont = UIFont(descriptor: UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody), size: self.xAxisLabelFontSize)
        
        let label = UILabel()
        label.text = point.description
        label.numberOfLines = 0
        label.textAlignment = .Center
        label.textColor = xAxisLabelTextColor
        label.font = axisLabelFont
        self.addSubview(label)
        label.sizeToFit()
        
        self.xAxisLabels.append(label)
        return label
    }
    
    func setPositionForXAxisLabel(index: Int, _ point: GraphableDataPoint, _ label: UILabel, _ rect: CGRect) {
        label.setNewViewPositionWithSameSize(CGPoint(x: labelXCoordinateForPointAtIndex(index, label, rect), y: self.bounds.size.height - self.verticalPadding + self.pointCircleSize / 2))
    }
    
    func labelXCoordinateForPointAtIndex(indexOfPoint: Int, _ label: UILabel, _ rect: CGRect) -> CGFloat {
        
        let graphPointX = calculateXPoint(indexOfPoint, rect)
        return graphPointX - label.frame.width / 2
    }
    
    func GetMidpoint(point: CGPoint, _ nextPoint: CGPoint) -> CGPoint {
        return CGPoint(x: (point.x + nextPoint.x) / 2.0, y: (point.y + nextPoint.y) / 2.0)
    }
    
    func controlPointForPoints(p1: CGPoint, _ p2: CGPoint) -> CGPoint {
        var controlPoint = GetMidpoint(p1, p2)
        let diffY = abs(p2.y - controlPoint.y)
        
        if p1.y < p2.y {
            controlPoint.y += diffY
        }
        else if p1.y > p2.y {
            controlPoint.y -= diffY
        }
        
        return controlPoint
    }
    
    func clipGraphCorners(rect: CGRect) {
        //set up background clipping area
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: UIRectCorner.AllCorners,
                                cornerRadii: CGSize(width: cornerRadii, height: cornerRadii))
        path.addClip()
    }
    
    func drawGradientBackground(rect: CGRect, _ context: CGContextRef) {
        let colors = [startColor.CGColor, endColor.CGColor]
        
        //set up the color space
        let colorSpace = getColorSpaceForGradient()
        
        //set up the color stops
        let colorLocations = getColorStopsForGradient()
        
        //create the gradient
        let gradient = CGGradientCreateWithColors(colorSpace,
                                                  colors,
                                                  colorLocations)
        
        //draw the gradient
        let startPoint = CGPoint.zero
        let endPoint = CGPoint(x:0, y:self.bounds.height)
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, [])
        
    }
    
    func getColorSpaceForGradient() -> CGColorSpace? {
        return CGColorSpaceCreateDeviceRGB()
    }
    
    func getColorStopsForGradient() -> [CGFloat] {
        return [0.0, 1.0]
    }
    
    func drawGraphLine(rect: CGRect) -> UIBezierPath {
        
        // draw the line graph
        
        lineColor.setFill()
        lineColor.setStroke()
        
        //set up the points line
        let graphPath = UIBezierPath()
        //go to start of line
        let firstPoint = CGPoint(x:calculateXPoint(0, rect), y:calculateYPoint(self.graphPoints[0].value, rect))
        graphPath.moveToPoint(firstPoint)
        
        //add points for each item in the graphPoints array
        //at the correct (x, y) for the point
        var previousPoint = firstPoint
        for i in 1..<self.graphPoints.count {
            let currentPoint = CGPoint(x:calculateXPoint(i, rect), y:calculateYPoint(self.graphPoints[i].value, rect))
            
            if GraphLineStyle.init(rawValue: lineStyle) == GraphLineStyle.Curved {
                let midPoint = GetMidpoint(previousPoint, currentPoint)
                
                graphPath.addQuadCurveToPoint(midPoint, controlPoint: controlPointForPoints(midPoint, previousPoint))
                graphPath.addQuadCurveToPoint(currentPoint, controlPoint: controlPointForPoints(midPoint, currentPoint))
            }
            else {
                graphPath.addLineToPoint(currentPoint)
            }
            
            previousPoint = currentPoint
        }
        
        return graphPath
    }
    
    func drawGradientUnderCurve(context: CGContextRef, _ graphPath: UIBezierPath, _ rect: CGRect) {
        if fillUnderCurve {
            let margin:CGFloat = pointHorizontalPadding
            //Create the clipping path for the graph gradient
            
            context.performContextSafeDrawing {[unowned self] in
                //2 - make a copy of the path
                let clippingPath = graphPath.copy() as! UIBezierPath
                
                
                //3 - add lines to the copied path to complete the clip area
                clippingPath.addLineToPoint(CGPoint(x: self.calculateXPoint(self.graphPoints.count - 1, rect), y:self.calculateYPoint( 0, rect)))
                clippingPath.addLineToPoint(CGPoint(x:self.calculateXPoint(0, rect), y:self.calculateYPoint(0, rect)))
                clippingPath.closePath()
                
                //4 - add the clipping path to the context
                clippingPath.addClip()
                
                
                let maxValue = max(self.graphPoints.maxElement().value, 0)
                let highestYPoint = self.calculateYPoint( maxValue, rect)
                let startPoint = CGPoint(x:margin, y: highestYPoint)
                let endPoint = CGPoint(x:margin, y:self.bounds.height)
                
                
                let colorSpace = self.getColorSpaceForGradient()
                let colorLocations = self.getColorStopsForGradient()
                
                let curveFillGradientColors = [self.curveFillStartColor.CGColor, self.curveFillEndColor.CGColor]
                
                let curveFillgradient = CGGradientCreateWithColors(colorSpace,
                    curveFillGradientColors,
                    colorLocations)
                
                CGContextDrawLinearGradient(context,
                    curveFillgradient,
                    startPoint,
                    endPoint,
                    [])
            }
            
            
        }
    }
    
    func drawPoints(rect: CGRect) {
        let circleSize: CGFloat = pointCircleSize
        pointColor.setFill()
        
        //Draw the circles on top of graph stroke
        for i in 0..<self.graphPoints.count {
            var point = CGPoint(x:calculateXPoint(i, rect), y:calculateYPoint(self.graphPoints[i].value, rect))
            
            point.x -= circleSize/2
            point.y -= circleSize/2
            
            self.subviews[i].frame = CGRect(origin: point, size: self.subviews[i].frame.size)
            
            let graphPoint = self.subviews[i] as! GraphPointView
            graphPoint.pointColor = pointColor
            graphPoint.pointStroke = lineColor
        }
        
    }
}

// MARK: Utility funcs
extension GraphView {
    func addPointsIfNeeded()
    {
        guard self.subviews.filter({$0 is GraphPointView}).count == 0 else {
            return
        }
        
        //User either explicitly sets a maxPossibleValue and a minPossibleValue which gets used,
        //or we attempt to intelligently do it ourselves. If we set the scale and there's both positive
        //and negative numbers then make the axis symmetric. Otherwise make it start at 0.
        
        //TODO: implicit unwrapping == BAD
        if self.maxPossibleValue == 0 && self.minPossibleValue == 0 {
            if self.graphPoints.minElement().value < 0 {
                self.maxPossibleValue = max(abs(self.graphPoints.maxElement().value), abs(self.graphPoints.minElement().value))
                self.minPossibleValue = -self.maxPossibleValue
                
            }
            else {
                self.maxPossibleValue = self.graphPoints.maxElement().value
                self.minPossibleValue = 0
            }
        }
        
        assert(!(self.maxPossibleValue == 0 && self.minPossibleValue == 0), "Cannot Infer Graph Range With Min and Max Data of 0")
        
        
        for index in 0..<self.graphPoints.count {
            let graphPoint = GraphPointView(index: index)
            graphPoint.backgroundColor = UIColor.clearColor()
            graphPoint.pointColor = pointColor
            graphPoint.pointStroke = lineColor
            graphPoint.frame = CGRect(x: 0, y: 0, width: pointCircleSize, height: pointCircleSize)
            graphPoint.tag = index
            self.addSubview(graphPoint)
        }
        
        print("added points: \(self.graphPoints)")
    }
    
    func getGraphPointViewByIndex(index: Int) -> GraphPointView? {
        return self.subviews.filter {subview in
            guard let gpv = subview as? GraphPointView else {
                return false
            }
            return gpv.index == index
            }.first as? GraphPointView
    }
    
    func pointMoved(graphPoint: GraphPointView) {
        let newValue = convertScreenPointsToGraphPointValue(graphPoint)
        NSLog("in pointMoved, newValue is \(newValue)")
        self.graphPoints[graphPoint.index].value = newValue
        self.setNeedsDisplay()
        
        self.delegate?.dataUpdated(self.graphPoints)
    }
}




// MARK: CADisplayLink Selector stuff.
extension GraphView {
    
    func updateGraphPointLocationForAnimation() {
        
        //Dumb animation for now, that ignores the duration passed in by the user.
        let elapsedTime = self.displayLink!.timestamp - self.lastDisplayLinkTimestamp
        self.lastDisplayLinkTimestamp = self.displayLink!.timestamp
        
        
        
        print("update \(elapsedTime) \(self.displayLink!.timestamp)")
        
        
        for (index, item) in self.animationDestinationGraphPoints!.enumerate() {
            let difference = item.value - self.graphPoints[index].value
            
            if self.graphPoints[index].value != item.value {
                self.graphPoints[index].value = difference > 0 ? self.graphPoints[index].value + 1 : self.graphPoints[index].value - 1
            }
        }
        
        for (index, item) in self.animationDestinationGraphPoints!.enumerate() {
            if self.graphPoints[index].value != item.value {
                return
            }
        }
        
        NSLog("Cleaning up CADisplayLink")
        self.lastDisplayLinkTimestamp = 0
        self.animationDestinationGraphPoints = nil
        self.displayLink!.invalidate()
        self.displayLink!.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        
        self.delegate?.dataUpdated(self.graphPoints)
    }
}


