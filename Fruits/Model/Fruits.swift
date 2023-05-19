//
//  Fruits.swift
//  Fruits
//
//  Created by Amgad ElNezamy on 05/05/2023.
//

import SwiftUI

struct Fruits : Identifiable{
    var id = UUID()
    var title : String
    var image : String
    var massage : String
    let gradientColors : [Color]
    var sound : String
    
}


let fruitsData : [Fruits] = [
    
Fruits(title: "Apple", image: "Apple", massage: "Apple", gradientColors: [Color("Apple01"),Color("Apple02")],sound: "apple"),

Fruits(title: "Banana", image: "Banana", massage: "Apple", gradientColors: [Color("Banana01"),Color("Banana02")],sound: "Banana"),

Fruits(title: "Strawberry", image: "Strawberry", massage: "Apple", gradientColors: [Color("Straberry01"),Color("Straberry02")],sound: "Strawberry"),

Fruits(title: "Orange", image: "Orange", massage: "Apple", gradientColors: [Color("Orange01"),Color("Orange02")],sound: "Orange"),

Fruits(title: "Pinapple", image: "Pinapple", massage: "Apple", gradientColors: [Color("Pinapple02"),Color("Pinapple02")],sound: "apple"),

Fruits(title: "peach", image: "peach", massage: "peach", gradientColors: [Color("peach01"),Color("peach02")],sound: "apple"),

Fruits(title: "grape", image: "grape", massage: "grape", gradientColors: [Color("grape01"),Color("grape02")],sound: "apple"),

Fruits(title: "fig", image: "fig", massage: "fig", gradientColors: [Color("fig01"),Color("fig02")],sound: "apple"),

Fruits(title: "watermelon", image: "watermelon", massage: "watermelon", gradientColors: [Color("watermelon01"),Color("watermelon02")],sound: "apple"),

Fruits(title: "kiwi", image: "kiwi", massage: "kiwi", gradientColors: [Color("kiwi01"),Color("kiwi02")],sound: "apple"),

Fruits(title: "pomegranate", image: "pomegranate", massage: "pomegranate", gradientColors: [Color("pomegranate01"),Color("pomegranate02")],sound: "apple")



]
