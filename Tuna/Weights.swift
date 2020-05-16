//
//  Weights.swift
//  Tuna
//
//  Created by Andrew Hocking on 2020-05-15.
//  Copyright © 2020 Andrew Hocking. All rights reserved.
//

import SwiftUI

//The shape of the standard weight
struct Trapezoid: Shape {
    var inset: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.minX+inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY)) //top left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)) //top right
        path.addLine(to: CGPoint(x: rect.maxX-inset, y: rect.maxY)) //bottom right
        path.addLine(to: CGPoint(x: rect.minX+inset, y: rect.maxY)) //bottom left
        
        let w = (rect.maxX - rect.minX)/5
        var newx = rect.midX/2 + (inset/4)
        path.addEllipse(in: CGRect(x: newx - (w/2), y: rect.midY - (w/2), width: w, height: w))
        
        newx = rect.midX + (rect.midX/2) - (inset/4)
        path.addEllipse(in: CGRect(x: newx - (w/2), y: rect.midY - (w/2), width: w, height: w))
        
        return path
    }
}

//The standard weight with all view modifiers attached
struct Weight: View {
    var body: some View {
        Trapezoid(inset: 10)
        .fill(Color.gray, style: FillStyle(eoFill: true))
        .frame(width: 75, height: 50)
    }
}

struct DraggableWeight: View {
    @EnvironmentObject var env: Settings
    @State var loc = 0.0
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if self.env.weightType == .gnome {
                    Image("gnome")
                        .scaleEffect(0.625)
                        .offset(y: CGFloat(self.env.bpm/1.2 - 150))
                        .animation(.linear)
                        .shadow(radius: 5)
                        .gesture(DragGesture(minimumDistance: 5)
                        .onChanged({ value in
                            if !self.env.isOn {
                                self.env.bpm = Double(Int(min(max(1, Double((value.location.y) + 75)*(1.2)), 300)))
                                self.loc = Double(value.location.y)
                            }
                        }))
                } else if self.env.weightType == .standard {
                    Weight()
                        .offset(y: CGFloat(self.env.bpm/1.2 - 150))
                        .animation(.linear)
                        .shadow(radius: 5)
                        .gesture(DragGesture(minimumDistance: 5)
                        .onChanged({ value in
                            if !self.env.isOn {
                                self.env.bpm = Double(Int(min(max(1, Double((value.location.y) + 125)*(1.2)), 300)))
                                self.loc = Double(value.location.y)
                            }
                        }))
                } else {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.gray)
                        .background(Circle().fill(Color.white))
                        .offset(y: CGFloat(self.env.bpm/1.2 - 150))
                        .animation(.linear)
                        .shadow(radius: 5)
                        .gesture(DragGesture(minimumDistance: 5)
                        .onChanged({ value in
                            if !self.env.isOn {
                                self.env.bpm = Double(Int(min(max(1, Double((value.location.y) + 125)*(1.2)), 300)))
                                self.loc = Double(value.location.y)
                            }
                        }))
                }
            }
        }
    }
}

struct Weights_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello world!")
    }
}
