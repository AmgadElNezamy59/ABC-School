//
//  PlaySound.swift
//  Fruits
//
//  Created by Amgad ElNezamy on 05/05/2023.
//

import Foundation
import AVFoundation


var audioPlayer : AVAudioPlayer?

func playsound(sound: String ,type: String){
    if let path = Bundle.main.path(forResource: sound, ofType: type){
        
        do{
        audioPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            audioPlayer?.play()
        }catch{
            print("couldnot find the file")
        }
    }
}
