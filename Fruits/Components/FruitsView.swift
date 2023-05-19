//
//  FruitsView.swift
//  Fruits
//
//  Created by Amgad ElNezamy on 04/05/2023.
//

import SwiftUI

struct FruitsView: View {
    
    var fruit : Fruits
    @State var isScaling : Bool = false
    var gradient : [Color] = [Color("Apple01"),Color("Apple02")]
    
    var body: some View {
        ZStack {
            
            VStack{
                Text(fruit.title)
                    .font(.system(size: 50))
                    .fontWeight(.black)
                    .foregroundColor(Color.white)
                //                    .padding(.top,30)
                
                Image(fruit.image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(isScaling ? 1 : 0.7)
                    .animation(.easeOut(duration: 2), value: isScaling)
                Button {
                    
                    playsound(sound: fruit.sound, type: "mp3")
                    
                } label: {
                    HStack{
                        //                    Text("Info")
                        Image(systemName: "speaker.wave.3.fill")
                    }// Hstack
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(Color.white)
                    
                }
            }
            
            
        }//: zstack
        .frame(width: 350 , height: 545 , alignment: .center)
        .background(LinearGradient(colors: fruit.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(20)
        .shadow(color: .black, radius: 3)
        .padding()
        .onAppear {
            isScaling = true
        }
        
    }
    
}



struct FruitsView_Previews: PreviewProvider {
    static var previews: some View {
        FruitsView(fruit: fruitsData[4])
    }
}
