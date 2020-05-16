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

//func dismissKeyboard() {
//    UIApplication.shared.endEditing()
//}

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

enum WeightType: Int {
    case standard = 0
    case gnome = 1
    case other = 2
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

class Settings: ObservableObject {
    @Published var bpm: Double = 120
    @Published var beat: Int = 1
    @Published var isOn: Bool = false
    @Published var weightType = WeightType.gnome
}

struct WeightSelectionButton: View {
    var text: String
    var weightType: WeightType
    var animation: Animation? = Animation.easeInOut
    
    @EnvironmentObject var env: Settings
    
    var body: some View {
        Button(
            action: {
                self.env.weightType = self.weightType
            },
            label: {
                Text(self.text)
                    .frame(width: 100, height: 40)
                    .foregroundColor(Color.white)
                    .background(self.env.weightType == self.weightType ? Color.green : Color.gray)
                    .clipShape(Capsule())
                    .scaleEffect(self.env.weightType == self.weightType ? 1 : 0.7)
                    .shadow(radius: 5)
                    .opacity(self.env.weightType == self.weightType ? 1 : 0.7)
                    .animation(self.animation)
            }
        )
    }
}

struct ContentView: View {
    @EnvironmentObject var env: Settings
    @State private var selectedWeight = 1 {
        willSet {
            self.env.weightType = WeightType(rawValue: newValue) ?? .standard
        }
    }
        
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
        return Timer.publish(every: 60/self.env.bpm, tolerance: 0.001, on: .main, in: .common).autoconnect()
    }
    
    private func beep() {
        if self.env.isOn {
            switch self.env.weightType {
                case .gnome:
                    playSound(sound: "gnomeSound", type: "wav")
                    break
                default:
                    AudioServicesPlaySystemSound(1057)
                    break
            }
            self.env.beat = (self.env.beat + 1) % 2
        }
    }
    
    private func titleText() -> String {
        switch self.env.weightType {
            case .gnome:
                return "Metrognome!"
            case .standard:
                return "Metronome!"
            default:
                return "Metronome?"
        }
    }
    
    var body: some View {
//        ZStack {
//            LinearGradient(gradient: Gradient(colors: [.white, .black]), startPoint: .top, endPoint: .bottom)
            VStack {
                Text(self.titleText())
                    .fontWeight(.black)
                    .underline()
//                    .foregroundColor(.green)
                    .font(.largeTitle)
                    .padding()
                    .padding(.top, 20)
             
                HStack {
                    WeightSelectionButton(text: "Weight", weightType: .standard)
                    WeightSelectionButton(text: "Gnome", weightType: .gnome)
                    WeightSelectionButton(text: "?", weightType: .other)
                }
                .padding(6)
                .background(Capsule().fill(Color(UIColor.systemGray5)))
                .padding(.bottom)
                
                Text("\(self.env.bpm, specifier: "%.0f") bpm")
                    .font(.title)
                    .onReceive(timer) { time in
                        self.beep()
                    }
                ZStack {
                    Rectangle()
                        .frame(width: 15, height: 310)
                        .foregroundColor(.gray)
                        .shadow(radius: 5)
                    DraggableWeight()
                        .animation(nil)
                }
                    .rotationEffect(.degrees(self.env.isOn ? (self.env.beat % 2 == 0 ? 30 : -30) : 0), anchor: UnitPoint(x: 0.5, y: 1))
                .animation(self.env.isOn ? Animation.easeInOut(duration: 60/self.env.bpm) : Animation.easeInOut(duration: 0.5))
                Button(
                    action: {
                        self.env.beat = 1
                        self.env.isOn.toggle()
                    },
                    label: {
                        Text(self.env.isOn ? "Stop" : "Start")
                            .frame(width: 150, height: 40)
                            .foregroundColor(Color.white)
                            .background(self.env.isOn ? Color.red : Color.green)
                            .clipShape(Capsule())
                    }
                )
                    .shadow(radius: 5)
                    .padding(20)
            }
        }
//    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
