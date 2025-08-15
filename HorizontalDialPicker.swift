import SwiftUI

struct HorizontalDialPickerDemo: View {
    @State private var value: Double = 50
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Selected Value: \(String(format: "%.2f", value))")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HorizontalDialPicker(value: $value, range: 0...100, step: 0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(.yellow.opacity(0.1))
            .navigationTitle("Horizontal Dial!")
        }
    }
}

struct HorizontalDialPicker<V>: View where V : BinaryFloatingPoint, V.Stride : BinaryFloatingPoint {
    
    @Binding var value: V
    var range: ClosedRange<V>
    var step: V
    
    var tickSpacing: CGFloat = 8.0
    var tickSegmentCount: Int = 10
    var showSegmentValueLabel: Bool = true
    var labelSignificantDigit: Int = 1
    
    @State private var scrollPosition: Int? = nil
    @State private var viewSize: CGSize? = nil
    
    // to avoid haptic effects on initialization,
    // ie: when setting self.scrollPosition in onAppear
    @State private var initialized: Bool = false

    
    var body: some View {
        ScrollView(.horizontal, content: {
            let totalTicks = Int((range.upperBound - range.lowerBound) / step) + 1
            
            HStack(spacing: tickSpacing) {
                ForEach(0..<totalTicks, id: \.self) { index in
                    let isSegment = index % tickSegmentCount == 0
                    let isTarget = index == scrollPosition
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isTarget ? .yellow : isSegment ? .black : .gray)
                        .frame(width: 2, height: 24)
                        .id(index)
                        .scaleEffect(x: isTarget ? 1.2 : 1, y: isTarget ? 1.5 : 0.8, anchor: .bottom)
                        .animation(.default.speed(1.2), value: isTarget)
                        .sensoryFeedback(.selection, trigger: isTarget && initialized)
                        .overlay(alignment: .bottom, content: {
                            if isSegment, self.showSegmentValueLabel {
                                let value = Double(range.lowerBound + V(index) * step)
                                Text("\(String(format: "%.\(labelSignificantDigit)f", value))")
                                    .font(.system(size: 12))
                                    .fontWeight(.semibold)
                                    .fixedSize() // required to avoid being cutoff horizontally
                                    .offset(y: 16)
                            }
                        })
                }
                
            }
            .padding(.vertical, 16) // to extend the scrollable area vertically
            .scrollTargetLayout()
            
        })
        .onAppear {
            self.scrollPosition = Int(value / step - range.lowerBound)
            
            // make sure scroll finishes before enabling haptic (Sensory feedback)
            // because those feedbacks can get into the way of scrolling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                self.initialized = true
            })
        }
        // using initial: true cannot replace onAppear
        // ie: will not set the correct initial position
        .onChange(of: value) {
            self.scrollPosition = Int(value / step - range.lowerBound)
        }
        .scrollTargetBehavior(.viewAligned(anchor: .center))
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrollPosition, anchor: .center)
        .defaultScrollAnchor(.center, for: .alignment)
        .defaultScrollAnchor(.center, for: .initialOffset)
        .defaultScrollAnchor(.center, for: .sizeChanges)
        .onChange(of: scrollPosition, {
            guard let scrollPosition = self.scrollPosition else { return }
            value = range.lowerBound + V(scrollPosition) * step
        })
        .safeAreaPadding(.horizontal, (viewSize?.width ?? 0)/2 ) // so that the start and end ends at center
        .overlay(content: {
            GeometryReader { geometry in
                if geometry.size != self.viewSize {
                    DispatchQueue.main.async {
                        self.viewSize = geometry.size
                    }
                }
                return Color.clear
            }
        })
    }
}
