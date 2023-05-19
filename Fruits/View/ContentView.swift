
//  ContentView.swift
//  Fruits
//  Created by Amgad ElNezamy on 04/05/2023.





import SwiftUI
struct ContentView: View {
    var fruit : [Fruits] = fruitsData
    var body: some View {
        
        
        ScrollView(.vertical){
            
            ForEach(fruit) { item in
                FruitsView(fruit : item)
            }
        }
    }
}

// for canvas
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
