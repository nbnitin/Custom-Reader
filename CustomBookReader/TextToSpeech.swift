//
//  TextToSpeech.swift
//  CustomBookReader
//
//  Created by Nitin Bhatia on 3/2/21.
//

import Foundation
import AVKit

class TextToSpeechWrapper {
    let synthesizer: AVSpeechSynthesizer? =  AVSpeechSynthesizer()
    private var utterance: AVSpeechUtterance!
    
    //Creating this singleton and selectedRow property to handle Bookmark TextToSpeech functionality.
    static let shared =  TextToSpeechWrapper()
    var selectedRow: Int = -1
    
    private init() {
        
    }
    
    func configure(string: String) {
        utterance = nil
        utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
    }

    func isSpeaking() -> Bool {
        return synthesizer?.isSpeaking ?? false
    }
    
    func isPaused() -> Bool {
        return  synthesizer?.isPaused ?? false
    }
    
    func startSpeaking() {
        while true {
            if !isSpeaking() {
                break
            }
            stopSpeaking()
        }
        synthesizer?.speak(utterance)
    }
    
    func pauseSpeaking() {
        synthesizer?.pauseSpeaking(at: .immediate)
    }
    
    func continueSpeaking() {
        synthesizer?.continueSpeaking()
    }
    
    func stopSpeaking() {
        synthesizer?.stopSpeaking(at: .immediate)
    }
    
    func toggleSpeaking () {
        guard let synthesizer = synthesizer else {
            return
        }
        if !synthesizer.isSpeaking {
            startSpeaking()
        } else if synthesizer.isPaused {
            continueSpeaking()
        } else {
            pauseSpeaking()
        }
    }
    
    func deinitialize() {
        utterance = nil
//        TextToSpeechWrapper.synthesizer = nil
    }
    
    deinit {
        deinitialize()
        debugPrint("TextToSpeechWrapper Deinit called")
    }
}
