//
//  ContentView.swift
//  Tuna
//
//  Created by Andrew Hocking on 2020-01-01.
//  Copyright © 2020 Andrew Hocking. All rights reserved.
//

import SwiftUI
import Combine
import AVFoundation
import Foundation

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

func dismissKeyboard() {
    UIApplication.shared.endEditing()
}

var audioPlayer: AVAudioPlayer!

func playSound(sound: String, type: String) {
    if let path = Bundle.main.path(forResource: sound, ofType: type) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path), fileTypeHint: AVFileType.mp3.rawValue)
            audioPlayer!.play()
        } catch {
            AudioServicesPlaySystemSound(1057)
            print("Sound not found")
        }
    }
}

enum WeightType {
    case standard
    case gnome
}

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

func roundDownToNearest2(number: Int) -> Int {
    var num = number
    while (!(num % 2 == 0)) {
        num -= 1
    }
    return num
}

extension View {
    func isHidden(_ hidden: Bool) -> some View {
        Group {
            if hidden {
                self.hidden()
            } else {
                self
            }
        }
    }
}

struct DraggableWeight: View {
    var weightType: WeightType
    @Binding var bpm: Double
    @Binding var isOn: Bool
    @State var loc = 0.0
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Weight()
                .offset(y: CGFloat(self.bpm/1.2 - 150))
                .animation(.linear)
                .shadow(radius: 5)
                .gesture(DragGesture(minimumDistance: 5)
                .onChanged({ value in
                    if !self.isOn {
                        self.bpm = Double(roundDownToNearest2(number: Int(min(max(2, Double((value.location.y) + 125)*(1.2)), 300))))
                        self.loc = Double(value.location.y)
                    }
                }))
                if self.weightType == WeightType.gnome {
                    Image("gnome")
                    .scaleEffect(0.625)
                    .offset(y: CGFloat(self.bpm/1.2 - 150))
                    .animation(.linear)
                    .shadow(radius: 5)
                    .gesture(DragGesture(minimumDistance: 5)
                    .onChanged({ value in
                        if !self.isOn {
                            self.bpm = Double(roundDownToNearest2(number: Int(min(max(2, Double((value.location.y) + 75)*(1.2)), 300))))
                            self.loc = Double(value.location.y)
                        }
                    }))
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var bpm: Double = 120
    @State private var beat = 1

    @State private var isOn = false
    @State private var weightType = WeightType.gnome
    @State private var selectedWeight = 0 {
        willSet {
            if newValue == 1 {
                self.weightType = WeightType.gnome
            }
            else {
                self.weightType = WeightType.standard
            }
        }
    }
    
    @State private var isGnome = true {
        willSet {
            if newValue == true {
                self.weightType = WeightType.gnome
            }
            else {
                self.weightType = WeightType.standard
            }
        }
    }
    
    func beep() {
        if self.isOn {
//            switch self.weightType {
//            case .gnome:
//                playSound(sound: "gnomeSound", type: "wav")
//                break
//            default:
//                AudioServicesPlaySystemSound(1057)
//                break
//            }
            if self.isGnome {
                playSound(sound: "gnomeSound", type: "wav")
            } else {
                AudioServicesPlaySystemSound(1057)
            }
            self.beat = (self.beat + 1) % 2
        }
    }
    
    private func titleText() -> String {
        if self.isGnome {
            return "Metrognome!"
        } else {
            return "Metronome!"
        }
    }
    
    private func timer() -> Publishers.Autoconnect<Timer.TimerPublisher> {
        if self.isOn {
            return Timer.publish(every: 60/self.bpm, on: .main, in: .common).autoconnect()
        } else {
            return Timer.publish(every: 1000000, on: .main, in: .common).autoconnect()
        }
    }
        
    var body: some View {
        VStack {
            Text(self.titleText())
                .fontWeight(.black)
                .underline()
                .foregroundColor(.red)
                .font(.largeTitle)
                .padding(50)
            
            Toggle(isOn: $isGnome) {
                Text("Gnome mode")
            }
                .padding([.leading, .trailing], 100)
            
            Text("\(bpm, specifier: "%.0f") bpm")
                .font(.title)
                .onReceive(timer()) { time in
                    self.beep()
                }
            ZStack {
                Rectangle()
                    .frame(width: 15, height: 310)
                    .foregroundColor(.gray)
                    .shadow(radius: 5)
                DraggableWeight(weightType: self.isGnome ? .gnome : .standard, bpm: self.$bpm, isOn: self.$isOn)
                    .animation(nil)
            }
                .rotationEffect(.degrees(self.isOn ? (self.beat % 2 == 0 ? 30 : -30) : 0), anchor: UnitPoint(x: 0.5, y: 1))
                .animation(self.isOn ? Animation.easeInOut(duration: 60/self.bpm) : Animation.easeInOut(duration: 0.5))
                .drawingGroup()
            Button(
                action: {
                    self.isOn.toggle()
                    self.beat = 1
                },
                label: {
                    Text(self.isOn ? "Stop" : "Start")
                        .frame(width: 150, height: 40)
                        .foregroundColor(.white)
                        .background(self.isOn ? Color.red : Color.green)
                        .clipShape(Capsule())
                        .shadow(radius: 5)
                        .padding(20)
                }
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
