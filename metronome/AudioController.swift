//
//  AudioController.swift
//  metronome
//
//  Created by Jan Kříž on 01/03/2020.
//  Copyright © 2020 Jan Kříž. All rights reserved.
//

import AVFoundation

final class AudioController: ObservableObject {

	@Published public var isPlaying = false
	@Published public var bpm = 100

	private let audioSession = AVAudioSession.sharedInstance()

	private let soundFileURL: URL
	private let originalAiffBuffer: Array<UInt8>
	private var aiffBuffer: Array<UInt8>
	private var soundData: Data
	private var player: AVAudioPlayer!

	public init() {
		if let path = Bundle.main.path(forResource: "rimshot.aif", ofType: nil) {
			self.soundFileURL = URL(fileURLWithPath: path)
		} else {
			fatalError("Could not create url for rimshot.aif")
		}

		do {
			self.soundData = try Data(contentsOf: soundFileURL)
			originalAiffBuffer = Array(soundData[0..<soundData.endIndex])
			aiffBuffer = originalAiffBuffer
		} catch {
			fatalError("DATA READING ERROR: \(error)")
		}

		self.setUpAudioSession()
		self.prepareBuffer()
	}

	deinit {
		player.stop()
		do {
			try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
		} catch {
			debugPrint("Could not deactivate audioSession:", error)
		}
	}

	public func play() {
		do {
			try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
		} catch {
			debugPrint("Could not activate audioSession:", error)
		}
		player.play()
	}

	public func stop() {
		player.stop()
	}

	public func prepareBuffer() {
		aiffBuffer = originalAiffBuffer

		var index = 0
		// 529_208 is the size of the sound chunk (in bytes).
		// Since we know that those bytes represent 20 bpm, we can get the number of bytes
		// to subtract from it with this formula to get the sound of desired length.
		var sizeToSubtract = Int32(529_208 - (529_208 * 20 / self.bpm))

 		if sizeToSubtract % 2 != 0 { sizeToSubtract += 1 }

		// Divide by 4 because one sample frame is 32-bits wide (Two 16-bit floats, one for each channel)
		let numSampleFramesToSubtract = UInt32(sizeToSubtract / 4)

		while self.bpm != 20 && index < aiffBuffer.count {
			// To figure out what's going on here, read through the AIFF specification:
			// http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/AIFF/Docs/AIFF-1.3.pdf
			guard let ckID = String(bytes: aiffBuffer[index...(index + 3)], encoding: .utf8) else {
				fatalError("Could not read ckID. current index: \(index)")
			}
			index += 4

			if ckID == "FORM" {
				let ptr = UnsafeMutableRawPointer(&aiffBuffer[index])
				let safePtr = ptr.assumingMemoryBound(to: Int32.self)
				// Update ckSize to reflect the new length of the sound chunk
				let ckSize = Int32(bigEndian: safePtr.pointee) - sizeToSubtract
				safePtr.pointee = Int32(bigEndian: ckSize)
				// Skip right to the beginning of the next chunk
				index += 8
				continue
			} else if ckID == "COMM" {
				let ptr = UnsafeMutableRawPointer(&aiffBuffer[index + 6])
				let safePtr = ptr.assumingMemoryBound(to: UInt32.self)
				// update numSampleFrames to reflect new length of the sound chunk
				let numSampleFrames = UInt32(bigEndian: safePtr.pointee) - numSampleFramesToSubtract
				safePtr.pointee = UInt32(bigEndian: numSampleFrames)
			} else if ckID == "SSND" {
				let ptr = UnsafeMutableRawPointer(&aiffBuffer[index])
				let safePtr = ptr.assumingMemoryBound(to: Int32.self)
				let originalSize = Int32(bigEndian: safePtr.pointee)
				// Update ckSize to reflect the new length of the sound chunk
				let ckSize = originalSize - sizeToSubtract
				safePtr.pointee = Int32(bigEndian: ckSize)

				let lowerBound = index + 8 + Int(ckSize)
				let upperBound = index + 8 + Int(originalSize)
				aiffBuffer.removeSubrange(lowerBound..<upperBound)
				break
			}

			let ptr = UnsafeRawPointer(&aiffBuffer[index])
			let ckSize = Int32(bigEndian: ptr.assumingMemoryBound(to: Int32.self).pointee)
			index += 4 + Int(ckSize)
		}

		do {
			self.soundData = Data(aiffBuffer)
			self.player = try AVAudioPlayer(data: soundData, fileTypeHint: "public.aiff-audio")
			player.numberOfLoops = -1
			player.prepareToPlay()
		} catch {
			fatalError("Could not init AVAudioPlayer: \(error)")
		}
	}

	func setUpAudioSession() {
		do {
			try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
			try audioSession.setCategory(.playback, mode: .default, options: [])
		} catch {
			debugPrint("Could not set-up audioSession:", error)
		}
	}

}
