//
//  PDFSearchViewController.swift
//
//  Created by Nitin Bhatia on 3/2/21.

import Foundation
import UIKit
import PDFKit

protocol PDFSearchViewControllerDelegate: class {
    func pdfSearchViewControllerDidSelect(pdfSelection: PDFSelection)
}


class PDFSearchViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    var isVoiceListeningStopped : Bool = true
    var searchString : String = String()
    var speechRecognizerUtility: SpeechRecognitionUtility?
    var pdfDocument: PDFDocument?
    var searchResultArray: [PDFSelection] = [PDFSelection]()
    weak var delegate: PDFSearchViewControllerDelegate?
    let imagesArray = [
           UIImage(named: "voice_loader_frame_1")!,
           UIImage(named: "voice_loader_frame_2")!,
           UIImage(named: "voice_loader_frame_3")!,
           UIImage(named: "voice_loader_frame_4")!,
           UIImage(named: "voice_loader_frame_5")!,
           UIImage(named: "voice_loader_frame_6")!,
           UIImage(named: "voice_loader_frame_7")!,
           UIImage(named: "voice_loader_frame_8")!,
           UIImage(named: "voice_loader_frame_9")!,
           UIImage(named: "voice_loader_frame_10")!,
           UIImage(named: "voice_loader_frame_11")!,
           UIImage(named: "voice_loader_frame_12")!,
           UIImage(named: "voice_loader_frame_13")!
       ]
    
    @IBOutlet weak var backgroundAnimationImage: UIImageView!
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var clearTextButton: CustomButton!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var clearTextButtonWidthConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.addTarget(self, action: #selector(startSearchingWithinPDF), for: .editingChanged)
        setupBackgroundImageView()
    }
    
    @IBAction func closeButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.searchTextField?.becomeFirstResponder()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ( searchResultArray.count == 0 ) {
            self.tableView.isHidden = true
        } else {
            self.tableView.isHidden = false
        }
        return self.searchResultArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PDFSearchCell = tableView.dequeueReusableCell(
            withIdentifier: "PDFSearchCell",
            for: indexPath) as! PDFSearchCell
        let pdfSelection: PDFSelection = self.searchResultArray[indexPath.row]
        if let pdfOutline: PDFOutline = self.pdfDocument?.outlineItem(for: pdfSelection) {
            cell.outlineLabel.text = pdfOutline.label
        }
        
        if let pdfPage: PDFPage = pdfSelection.pages.first {
            cell.pageNumberLabel.text = "Page:" + (pdfPage.label ?? "")
        }
        let extendSelection: PDFSelection = pdfSelection.copy() as! PDFSelection
        extendSelection.extend(atStart: 10)
        extendSelection.extend(atEnd: 90)
        extendSelection.extendForLineBoundaries()
        
        let pdfSelectionString: NSString = pdfSelection.string as! NSString
        let extendedSelectionString: NSString = extendSelection.string as! NSString
        let range: NSRange = extendedSelectionString.range(of: pdfSelectionString as String,
                                                           options: .caseInsensitive)
        
        let attributedString: NSMutableAttributedString = NSMutableAttributedString(
            string: extendSelection.string!)
        attributedString.addAttribute(.backgroundColor,
                                      value: UIColor.yellow,
                                      range: range)
        attributedString.addAttribute(.foregroundColor,
                                      value: UIColor.gray,
                                      range: range)
        cell.searchResultTextLabel.attributedText = attributedString
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pdfSelection: PDFSelection = self.searchResultArray[indexPath.row]
        self.delegate?.pdfSearchViewControllerDidSelect(pdfSelection: pdfSelection)
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func voiceSearchButtonClicked(_ sender: Any) {
        gradientView.isHidden = false
        startListeningVoice()
        backgroundImageViewAnimation(startAnimation: true)
    }
    @IBAction func clearTextButtonAction(_ sender: Any) {
        searchTextField.text = ""
        clearTextButtonWidthConstraint.constant = 0
        self.pdfDocument?.cancelFindString()
        
        //        self.pdfDocument?.cancelFindString()
        //        self.navigationItem.setRightBarButton(nil, animated: true)
        //        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func searchButtonAction(_ sender: Any) {
        startSearchingWithinPDF()
    }
    
    @IBAction func closeVoiceSearchView(_ sender: Any) {
        gradientView.isHidden = true
        backgroundImageViewAnimation(startAnimation: false)
    }
    
   
    
    func backgroundImageViewAnimation(startAnimation: Bool) {
        if startAnimation {
            backgroundAnimationImage.startAnimating()
        } else {
            backgroundAnimationImage.stopAnimating()
        }
    }
    
    private func setupBackgroundImageView() {
        backgroundAnimationImage.animationImages = imagesArray
        backgroundAnimationImage.animationDuration = 2.0
    }
}

extension PDFSearchViewController: UITextFieldDelegate {
    
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    
    @objc private func startSearchingWithinPDF() {
        
        if searchTextField.text!.count < 2 {
            self.searchResultArray.removeAll()
            self.tableView.reloadData()
            self.pdfDocument?.cancelFindString()
            return
        }
        if ( !gradientView.isHidden ) {
            gradientView.isHidden = true
        }
        self.searchResultArray.removeAll()
        self.tableView.reloadData()
        self.pdfDocument?.cancelFindString()
        self.pdfDocument?.delegate = self
        self.pdfDocument?.beginFindString(searchTextField.text!, withOptions: .caseInsensitive)
    }
    
}

extension PDFSearchViewController: PDFDocumentDelegate {
    func didMatchString(_ instance: PDFSelection) {
        self.searchResultArray.append(instance)
        self.tableView.reloadData()
    }
}

extension PDFSearchViewController {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.searchTextField?.resignFirstResponder()
        
        if isVoiceListening() {
            speechRecognizerUtility?.stopAudioRecognition()
        }
    }
}

extension PDFSearchViewController {
    func startListeningVoice() {
        isVoiceListeningStopped = false
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
                    AlertWrapper.showBasicAlert(on: self!, with: "Error", message: "Unauthorized", completion: {})
                    
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
        searchTextField.text = searchString
        speechRecognizerUtility?.stopAudioRecognition()
        startSearchingWithinPDF()
    }
    func isVoiceListening() -> Bool {
        return speechRecognizerUtility?.isSpeechRecognitionOn() ?? false
    }
    
}
