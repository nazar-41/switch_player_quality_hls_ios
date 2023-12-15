//
//  VideoViewModel.swift
//  VideoPlayer
//
//  Created by Belet Developer on 12.12.2023.
//  Copyright © 2023 Ivano Bilenchi. All rights reserved.
//

import AVKit
import SwiftUI


extension Home{
    class ViewModel: ObservableObject, StreamProxyDelegate  {
        let factory: AppFactory
        static var count = 0
        @Published var player =  AVPlayer()
        init(factory: AppFactory) {
            self.factory = factory
            if let url = factory.proxy.localPlaylistUrl {
                let playerItem = AVPlayerItem(url: url)
                self.player.replaceCurrentItem(with: playerItem)
                self.player.currentItem?.preferredForwardBufferDuration = 60.0
                factory.proxy.proxyDelegate = self
            }
            ViewModel.count += 1
            print(ViewModel.count)
        }
        @Published var showPlayerControllers: Bool =  false
        @Published var isPlaying: Bool =  false
        @Published var isSeeking: Bool =  false
        @Published var isFinishingPlaying: Bool =  false
        @Published var timeoutTask: DispatchWorkItem?
        @GestureState var isDragging: Bool = false
        @Published var bufferProgress: CGFloat = 0
        @Published var progress: CGFloat = 0
        @Published var lastDraggedProgress: CGFloat = 0
        @Published var lastBufferProgress: CGFloat = 0
        @Published var isObserverAdded: Bool =  false
        @Published var thumbnailFrames: [UIImage] =  []
        @Published var draggingImage: UIImage?
        @Published var playerStatusObserver: NSKeyValueObservation?
        @Published var playerObserver: Any?
        @Published var audioIndex: Int = 1
        
//        func playVideo(url: URL) {
//            let playerItem = AVPlayerItem(url: url)
//            player = AVPlayer(playerItem: playerItem)
//            player?.play()
//        }
//        
//        func stopVideo() {
//            player?.pause()
//            player = nil
//        }
//        
//        func togglePlayerControllers(){
//            showPlayerControllers.toggle()
//        }
        
//        func doubleTab(isForward:Bool){
//            if let seconds = player?.currentTime().seconds {
//                player?.seek(to: .init(seconds: seconds + (isForward ? 10 : -10) , preferredTimescale: 600))
//            }
//        }
        func listen(){
            self.player.addPeriodicTimeObserver(forInterval: .init(seconds: 1, preferredTimescale: 600), queue: .main, using: { time in
                if let currentPlayerItem = self.player.currentItem{
                    let totalDuration = currentPlayerItem.duration.seconds
//                    self.player.currentItem?.preferredForwardBufferDuration = 120  // 3 min limit
//                    self.player.currentItem?.preferredPeakBitRate = 1000  // limit
//                        player?.currentItem?.preferredMaximumResolution = .init(width: 640, height: 360)
//                        player?.currentItem?.preferredMaximumResolution = .init(width: 640, height:  480 )
//                        player?.currentItem?.preferredMaximumResolution = .init(width: 1280, height: 720)
//                    self.player.currentItem?.preferredMaximumResolution = .init(width: 1920, height: 1080)
//                        print(player?.currentItem?.preferredPeakBitRate.binade.bitPattern)
//                        print(player?.currentItem?.accessibilityFrame)
//
                    print(self.player.currentItem?.presentationSize)// limit
                    let loadedTimeRanges: [NSValue] = currentPlayerItem.loadedTimeRanges

                    guard let timeRange = loadedTimeRanges.first?.timeRangeValue else { return }

//                           let startTime = CMTimeGetSeconds(timeRange.start)
//                           let loadedDuration = CMTimeGetSeconds(timeRange.duration)
                       let end = CMTimeGetSeconds(timeRange.end)
                    let currentDuration = self.player.currentTime().seconds
                    let calculationProgress = currentDuration / totalDuration
                    let calculationBufferProgress = end / totalDuration
                    if !self.isSeeking {
                        self.progress = calculationProgress
                        self.bufferProgress = calculationBufferProgress
                        self.lastDraggedProgress = self.progress
                    }
                    
                    if calculationProgress == 1 {
                        self.isFinishingPlaying = true
                        self.isPlaying = false
                        
                    }
                }
            })
        }
        
//        func onChangedDragGesture(value:){
//            if let timeoutTask{
//                timeoutTask.cancel()
//            }
//            
//            let translationX: CGFloat = value.translation.width
//            let calculatedProgress = (translationX / videoSize.width) + lastDraggedProgress
//            
//            progress = max(min(calculatedProgress, 1), 0)
////                            bufferProgress = max(min(calculatedProgress, 1), 0)
//            isSeeking = true
//            let dragIndex = Int(progress / 0.01)
//            if thumbnailFrames.indices.contains(dragIndex){
//                draggingImage = thumbnailFrames[dragIndex]
//            }
//        }
        // MARK: Resolution
        
        @Published var resolutions: [Resolution] = [.zero]
        
        @Published var selectedResolution: Resolution = .zero
        
        var resolutionTapHandler: ((_ newResolution: Resolution) -> Void)?
        
        
        
        func changedResolution() {
            print(selectedResolution)
            resolutionTapHandler?(selectedResolution)
        }
        
        func streamProxy(_ proxy: StreamProxy, didReceiveMainPlaylist playlist: Playlist) {
            guard let playlist = playlist as? MasterPlaylist else { return }
            let resolutions = Array<Resolution>(playlist.mediaPlaylists.values.compactMap({ $0.resolution })).sorted()
            print(resolutions)
            if !resolutions.isEmpty {
                proxy.policy = FixedQualityPolicy(quality: .withResolution(resolutions[0]))
                //  let control = ResolutionSelectionControl(frame: .zero)
                //  control.resolutions = resolutions
                //
                //  control.resolutionTapHandler = { (res) in
                //      proxy.policy = FixedQualityPolicy(quality: .withResolution(res))
                //  }
                //
                //  selectionControl = control
                self.isPlaying = true
                print(ViewModel.count)
                self.resolutions = resolutions
                self.resolutionTapHandler = { (res) in
                    proxy.policy = FixedQualityPolicy(quality: .withResolution(res))
                }
            }
        }
    }
}
