//
//  ContentView.swift
//  metronome
//
//  Created by Jan Kříž on 20/02/2020.
//  Copyright © 2020 Jan Kříž. All rights reserved.
//

import SwiftUI

fileprivate struct Background: View {

	private var colorStart = Color("background_start")
	private var colorEnd = Color("background_end")

	var body: some View {
		LinearGradient(gradient: Gradient(colors: [colorStart, colorEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
	}
}

struct ContentView: View {

	@EnvironmentObject var audioController: AudioController

	var body: some View {
		ZStack {
			Background()
			.edgesIgnoringSafeArea(.all)

			VStack {
				Text("\(audioController.bpm)")
				.font(Font.custom("Futura", size: 50))
				.padding(.top, 25)
				.foregroundColor(Color("text"))

				BPMSlider()

				BottomControlsBar()
				.frame(height: 75)
				.padding(.bottom, 25)
				.padding(.top, 10)
				.padding(.horizontal, 25)
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}