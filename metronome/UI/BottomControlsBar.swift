//
//  BottomControlsBar.swift
//  metronome
//
//  Created by Jan Kříž on 22/02/2020.
//  Copyright © 2020 Jan Kříž. All rights reserved.
//

import SwiftUI

struct CustomButtonStyle: ButtonStyle {

	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
 			.foregroundColor(Color("highlight"))
	}
}

struct BottomControlsBar: View {

	@EnvironmentObject var audioController: AudioController
	@State private var isShowingSettingsView = false

	var body: some View {

		HStack {
			Button(action: {
				self.isShowingSettingsView = true
			}) { Image(systemName: "gear") }
				.sheet(isPresented: $isShowingSettingsView) { SettingsView(selectedSound: self.$audioController.selectedSound, isOnScreen: self.$isShowingSettingsView) }
			.buttonStyle(CustomButtonStyle())
			.font(Font.custom("System", size: 40))

			Spacer()

			Button(action: {
				if self.audioController.isPlaying {
					self.audioController.stop()
					self.audioController.prepareBuffer()
				} else {
					self.audioController.play()
				}

				self.audioController.isPlaying.toggle()
			}) {
				Image(systemName: audioController.isPlaying ? "pause" : "play")
				.offset(x: audioController.isPlaying ? 0 : 3)
				}
				.buttonStyle(CustomButtonStyle())
				.font(Font.custom("System", size: 60))

			Spacer()

			Button(action: {
				print("setlist tapped")
			}) { Image(systemName: "music.note.list") }
			.buttonStyle(CustomButtonStyle())
			.font(Font.custom("System", size: 40))
		}

	}
}
