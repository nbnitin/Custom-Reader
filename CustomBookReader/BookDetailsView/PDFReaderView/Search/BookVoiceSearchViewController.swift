//
//  BookVoiceSearchViewController.swift
//
//  Created by Nitin Bhatia on 3/2/21.

import Foundation
import UIKit
import Lottie

//constants
let speechRecognitionTimeout: Double = 1.5
let maximumAllowedTimeDuration = 5

class BookVoiceSearchViewController : UIViewController {
    @IBOutlet weak var voiceSearchBackgroundView: GradientView!
    @IBOutlet var animationView: UIView!
    var animationSubView : AnimationView!
    @IBOutlet var micButton: UIButton!
    @IBOutlet var voiceSearchTitle: UILabel!
    
    @IBOutlet weak var backgroundAnimationImageView: UIImageView!
    @IBOutlet weak var voiceSearchButton: UIButton!
    @IBOutlet weak var voiceClearTextButton: CustomButton!
    @IBOutlet weak var voiceSearchTextField: UITextField!
    
    @IBOutlet weak var searchIconContainerView: UIView!
    
    @IBOutlet weak var clearTextVoiceWidthConstraint: NSLayoutConstraint!
    @IBOutlet var textClearImage: UIImageView!

    var isVoiceListeningStopped : Bool = true
    var speechRecognizerUtility: SpeechRecognitionUtility?
    var searchString : String = String()
    var parentVC : SearchController!
    var timer : Timer?
    private var totalTime: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        voiceSearchTextField.isEnabled = false
        startListeningVoice()
        searchIconContainerView.isHidden = true
    }
    
    private func setupBackgroundImageView() {
        backgroundAnimationImageView.animationDuration = 2.0
        backgroundImageViewAnimation(startAnimation: true)
    }
    
    func backgroundImageViewAnimation(startAnimation: Bool) {
        if startAnimation {
            animationSubView.play()
            micButton.isHidden = true
            voiceSearchTitle.text = ""
        } else {
            animationSubView.stop()
            micButton.isHidden = false
//            voiceSearchTitle.text = "Tap microphone to try again"
        }
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let animation = Animation.named("lottie_file_listening")
        animationSubView = AnimationView()
        animationSubView.animation = animation
        animationSubView.frame = animationView.bounds
        animationSubView.contentMode = .center
        self.animationView.addSubview(animationSubView)
        animationSubView.loopMode = .loop
        backgroundImageViewAnimation(startAnimation: true)
        startListeningVoice()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchIconContainerView.layer.cornerRadius = searchIconContainerView.frame.width / 2
    }
    
    func displaySearchString(viewModel: String) {
        voiceSearchTextField.text = viewModel
        if !viewModel.isEmpty {
            
            if AppUtility.isPad() {
                self.clearTextVoiceWidthConstraint.constant  = CLEAR_TEXT_BUTTON_WIDTH_IPAD_PORTRAIT
            } else {
                self.clearTextVoiceWidthConstraint.constant  = CLEAR_TEXT_BUTTON_WIDTH_IPHONE_PORTRAIT
            }
            textClearImage.isHidden = false
            self.searchIconContainerView.isHidden = false
        } else {
            //voiceSearchTextField.placeholder = "Click Mic to Search Again."
        }
    }
    
    
    @IBAction func searchButtonAction(_ sender: UIButton) {
        backgroundImageViewAnimation(startAnimation: false)
        if let searchText = voiceSearchTextField.text, searchText != "" {
            self.parentVC.searchTextField.text = searchText
            self.parentVC.doSearch()
            self.removeFromParent()
            speechRecognizerUtility?.stopAudioRecognition()
            self.parentVC.removeVoiceSearch()
        } else {
            //Play audio when search text is empty.
        }
        
    }
    
    @IBAction func voiceViewMicButtonAction(_ sender: UIButton) {
        startListeningVoice()
        if isVoiceListening() ?? false {
            backgroundImageViewAnimation(startAnimation: true)
            voiceSearchTextField.text = ""
            voiceSearchTextField.placeholder = "Say Something..."
        } else {
            backgroundImageViewAnimation(startAnimation: false)
            voiceSearchTextField.text = ""
            //voiceSearchTextField.placeholder = "Click Mic to Search Again."
        }
    }
    
    @IBAction func clearSearchTextButtonAction(_ sender: UIButton) {
        startListeningVoice()
        backgroundImageViewAnimation(startAnimation: true)
        self.voiceSearchTextField.text = ""
        self.clearTextVoiceWidthConstraint.constant = 0
        self.searchIconContainerView.isHidden = true
        textClearImage.isHidden = true
    }
    
    @IBAction func closeSearchButtonAction(_ sender: UIButton) {
        stopTimeCounter()
        backgroundImageViewAnimation(startAnimation: false)
        speechRecognizerUtility?.stopAudioRecognition()
        parentVC.removeVoiceSearch()
    }
    
    private func startTimeCounter() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            guard let weakSelf = self else { return }

            guard weakSelf.totalTime < maximumAllowedTimeDuration else {
                weakSelf.speechRecognizerUtility?.stopAudioRecognition()
                //weakSelf.speechRecognitionDone()
                weakSelf.backgroundImageViewAnimation(startAnimation: false)
                weakSelf.voiceSearchTitle.text = "Tap microphone to try again"
                debugPrint("Timeout Called.")
                return
            }
             weakSelf.totalTime += 1
        })
    }
    
    private func stopTimeCounter() {
        self.timer?.invalidate()
        self.timer = nil
    }
}


extension BookVoiceSearchViewController {
    func startListeningVoice() {
        isVoiceListeningStopped = false
        totalTime = 0
        //backgroundImageViewAnimation(startAnimation: false)
        if speechRecognizerUtility == nil {
            // Initialize the speech recognition utility here
            speechRecognizerUtility = SpeechRecognitionUtility(speechRecognitionAuthorizedBlock: { [weak self] in
                self?.toggleSpeechRecognitionState()
                }, stateUpdateBlock: { [weak self] (currentSpeechRecognitionState, finalOutput) in
                    // A block to update the status of speech recognition. This block will get called every time Speech framework recognizes the speech input
                    self?.stateChangedWithNew(state: currentSpeechRecognitionState)
                    // We won't perform search until final input is ready. We will usually wait for users to finish speaking their input until search request is sent
                    if finalOutput {
                        self?.toggleSpeechRecognitionState()
                        self?.speechRecognitionDone()
                    }
            }, timeoutPeriod: speechRecognitionTimeout) { [weak self] (authorized) in
                if !authorized {
                    AlertWrapper.showBasicAlert(on: self!, with: "Error", message: "Something went wrong", completion: {})
                    
                }
            } // We will set the Speech recognition Timeout to make sure we get the full string output once user has stopped talking. For example, if we specify timeout as 2 seconds. User initiates speech recognition, speaks continuously (Hopegully way less than full one minute), and if pauses for more than 2 seconds, value of finalOutput in above block will be true. Before that you will keep getting output, but that won't be the final one.
        } else {
            // We will call this method to toggle the state on/off of speech recognition operation.
            self.toggleSpeechRecognitionState()
        }
        
    }
    // A method to toggle the speech recognition state between on/off
    private func toggleSpeechRecognitionState() {
        do {
            try self.speechRecognizerUtility?.toggleSpeechRecognitionActivity()
        } catch SpeechRecognitionOperationError.denied {
            print("Speech Recognition access denied")
            AlertWrapper.showBasicAlert(on: self, with: "Error", message: "Mic permission missing", completion: {})
        } catch SpeechRecognitionOperationError.notDetermined {
            print("Unrecognized Error occurred")
        } catch SpeechRecognitionOperationError.restricted {
            print("Speech recognition access restricted")
        } catch SpeechRecognitionOperationError.audioSessionUnavailable {
            print("Audio session unavailable")
        } catch SpeechRecognitionOperationError.invalidRecognitionRequest {
            print("Recognition request is null. Expected non-null value")
        } catch SpeechRecognitionOperationError.audioEngineUnavailable {
            print("Audio engine is unavailable. Cannot perform speech recognition")
        } catch {
            print("Unknown error occurred")
        }
    }
    
    private func stateChangedWithNew(state: SpeechRecognitionOperationState) {
        switch state {
        case .authorized:
            print("State: Speech recognition authorized")
        case .audioEngineStart:
            self.startTimeCounter()
            print("State: Audio Engine Started")
        case .audioEngineStop:
            isVoiceListeningStopped = true
            speechRecognizerUtility?.stopAudioRecognition()
            print("State: Audio Engine Stopped")
        case .recognitionTaskCancelled:
            print("State: Recognition Task Cancelled")
        case .speechRecognized(let recognizedString):
            print("State: Recognized String \(recognizedString)")
            if !isVoiceListeningStopped {
                stopTimeCounter()
                searchString = recognizedString
            }
        case .speechNotRecognized:
            print("State: Speech Not Recognized")
        case .availabilityChanged(let availability):
            print("State: Availability changed. New availability \(availability)")
        case .speechRecognitionStopped(let finalRecognizedString):
            speechRecognizerUtility?.stopAudioRecognition()
            print("State: Speech Recognition Stopped with final string \(finalRecognizedString)")
        }
    }
    
    
    
    
    func speechRecognitionDone() {
        debugPrint("Printing Search String \(String(describing: searchString))")
        //If search string empty play error message
        voiceSearchTextField.text = searchString
        speechRecognizerUtility?.stopAudioRecognition()
        searchIconContainerView.isHidden = false
        
        if AppUtility.isPad() {
            clearTextVoiceWidthConstraint.constant = CLEAR_TEXT_BUTTON_WIDTH_IPAD_PORTRAIT
        } else {
            clearTextVoiceWidthConstraint.constant = CLEAR_TEXT_BUTTON_WIDTH_IPHONE_PORTRAIT
        }
        textClearImage.isHidden = false
        // startSearchingWithinPDF()
    }
    func isVoiceListening() -> Bool {
        return speechRecognizerUtility?.isSpeechRecognitionOn() ?? false
    }
    
}
