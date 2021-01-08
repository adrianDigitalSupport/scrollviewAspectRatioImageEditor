//
//  ViewController.swift
//  YPImagePickerExample
//
//  Created by Adrian Piedra on 12/21/20.
//

import UIKit
//import YPImagePicker
//import AVFoundation
//import AVKit
//import Photos


//MARK: - ScrollView Demo
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate {

    enum HTAspectRatio: String {
        case portrait = "3:4"
        case landscape = "16:9"
        case square = "1:1"
    }

    var isSquare = false {
        didSet {
            aspectButton.setImage(UIImage(systemName: isSquare ? "aspectratio.fill" : "aspectratio"), for: .normal)
        }
    }
    
    var originalImageView = UIImageView()
    var scrollView: UIScrollView = {
        let scrollview = UIScrollView(frame: .zero)
        scrollview.translatesAutoresizingMaskIntoConstraints = false
        scrollview.showsHorizontalScrollIndicator = false
        scrollview.showsVerticalScrollIndicator = false
        scrollview.backgroundColor = .black

        return scrollview
    }()
    
    var gridContainer: UIView = {
        let uiview = UIView()
        uiview.translatesAutoresizingMaskIntoConstraints = false
        uiview.backgroundColor = .clear
        uiview.layer.borderColor = UIColor.white.cgColor
        uiview.layer.borderWidth = 1.0
        uiview.isUserInteractionEnabled = false
        
        return uiview
    }()
    
    @IBOutlet weak var aspectButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        createScrollView()
        initOriginalImageView()
    }

    private func createScrollView() {
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 250),
            scrollView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scrollView.widthAnchor.constraint(equalTo: view.widthAnchor),
            scrollView.heightAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 1.05)
        ])
        
        //Guide constraints configuration
        view.addSubview(gridContainer)
        NSLayoutConstraint.activate([
            gridContainer.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor),
            gridContainer.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            //TODO: Modify the constraints based on the aspect ratio of the image selected.
            //Guide size for 1:1
//            gridContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
//            gridContainer.heightAnchor.constraint(equalTo: gridContainer.widthAnchor),
            //Guide size for 4:3
//            gridContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.7),
//            gridContainer.heightAnchor.constraint(equalTo: gridContainer.widthAnchor, multiplier: 4/3),
            // Guide height for 16:9
            gridContainer.widthAnchor.constraint(equalTo: scrollView.widthAnchor, multiplier: 0.9),
            gridContainer.heightAnchor.constraint(equalTo: gridContainer.widthAnchor, multiplier: 9/16),
            
        ])
    }

    private func initOriginalImageView() {
        scrollView.addSubview(originalImageView)
    }

    @IBAction func pickImagesAction(_ sender: Any) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary

        self.present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage

        _ = getAspectRatio(for: image)

        originalImageView.image = image
        originalImageView.contentMode = .center

        originalImageView.frame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)

        scrollView.contentSize = image.size
        scrollView.contentInset = UIEdgeInsets(top: gridContainer.frame.minY - scrollView.frame.minY,
                                               left: gridContainer.frame.minX - scrollView.frame.minX,
                                               bottom: scrollView.frame.maxY - gridContainer.frame.maxY,
                                               right: scrollView.frame.maxX - gridContainer.frame.maxX)

        var scrollViewFrame = scrollView.frame
        let scaleWidth = gridContainer.frame.size.width / image.size.width
        let scaleHeight = gridContainer.frame.size.height / image.size.height
        let maxScale = max(scaleHeight, scaleWidth)

        scrollView.minimumZoomScale = maxScale
        scrollView.maximumZoomScale = 1
        scrollView.zoomScale = maxScale

        centerScrollViewContent()

        picker.dismiss(animated: true, completion: nil)
    }

    private func getAspectRatio(for image: UIImage) -> HTAspectRatio {
        let width = image.size.width
        let height = image.size.height

        let scale = height / width
        print("Image -> \(width) x \(height)")
        print(scale < 1.0 ? HTAspectRatio.landscape.rawValue : scale > 1.0 ? HTAspectRatio.portrait.rawValue : HTAspectRatio.square.rawValue)

        return scale < 1.0 ? HTAspectRatio.landscape : scale > 1.0 ? HTAspectRatio.portrait : HTAspectRatio.square
    }

    func centerScrollViewContent() {
        print(scrollView.contentSize)
        let guideFrame = gridContainer.frame
        let containerSize = scrollView.frame.size
        var newImagesFrame = originalImageView.frame
        
//        let differenceGuideWidth = containerSize.width - guideSize.width
//        let differenceGuideHeight = containerSize.height - guideSize.height

//        print("Previous Image frame origins \(newImagesFrame.origin)")
        if newImagesFrame.size.width < guideFrame.size.width {
            newImagesFrame.origin.x = ((guideFrame.size.width - newImagesFrame.size.width) / 2).nextUp
        } else {
            newImagesFrame.origin.x = 0
        }

        if newImagesFrame.size.height < guideFrame.size.height {
            newImagesFrame.origin.y = ((guideFrame.size.height - newImagesFrame.size.height) / 2).nextUp
        } else {
            newImagesFrame.origin.y = 0
        }
//
//        print("Finally Image frame \(newImagesFrame.origin)")
////        print("-------------------------------------------------")
//
        originalImageView.frame = newImagesFrame
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerScrollViewContent()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return originalImageView
    }

    @IBAction func cropAndSafe(_ sender: Any) {
        //TODO: Consider the grid area
        let gridFrame = gridContainer.frame
        let ratio = originalImageView.image!.size.height / scrollView.contentSize.height
        let origin = CGPoint(x: scrollView.contentOffset.x * ratio,
                             y: scrollView.contentOffset.y * ratio)
        let size = CGSize(width: scrollView.bounds.size.width * ratio,
                          height: scrollView.bounds.size.height * ratio)
        
        let cropFrame = CGRect(origin: origin, size: size)
        let croppedImage = originalImageView.image!.croppedInRect(rect: cropFrame)

        UIImageWriteToSavedPhotosAlbum(croppedImage, nil, nil, nil)
    }

    @IBAction func aspectPressed(_ sender: Any) {
        isSquare = !isSquare
    }
}

//MARK: - YPImagePickerDelegate
//class ViewController: UIViewController, YPImagePickerDelegate {
//
//    var selectedItems = [YPMediaItem]()
//
//    let selectedImageV = UIImageView()
//    let pickButton = UIButton()
//    let resultsButton = UIButton()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        self.view.backgroundColor = .white
//
//        selectedImageV.contentMode = .scaleAspectFit
//        selectedImageV.frame = CGRect(x: 0,
//                                      y: 0,
//                                      width: UIScreen.main.bounds.width,
//                                      height: UIScreen.main.bounds.height * 0.45)
//        view.addSubview(selectedImageV)
//
//        pickButton.setTitle("Pick", for: .normal)
//        pickButton.setTitleColor(.black, for: .normal)
//        pickButton.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
//        pickButton.addTarget(self, action: #selector(showPicker), for: .touchUpInside)
//        view.addSubview(pickButton)
//        pickButton.center = view.center
//
//        resultsButton.setTitle("Show selected", for: .normal)
//        resultsButton.setTitleColor(.black, for: .normal)
//        resultsButton.frame = CGRect(x: 0,
//                                     y: UIScreen.main.bounds.height - 100,
//                                     width: UIScreen.main.bounds.width,
//                                     height: 100)
//        resultsButton.addTarget(self, action: #selector(showResults), for: .touchUpInside)
//        view.addSubview(resultsButton)
//    }
//
//    @objc
//    func showResults() {
//        if selectedItems.count > 0 {
//            let gallery = YPSelectionsGalleryVC(items: selectedItems) { g, _ in
//                g.dismiss(animated: true, completion: nil)
//            }
//            let navC = UINavigationController(rootViewController: gallery)
//            self.present(navC, animated: true, completion: nil)
//        } else {
//            print("No items selected yet.")
//        }
//    }
//
//    // MARK: Configuration
//    @objc
//    func showPicker() {
//
//        var config = YPImagePickerConfiguration()
//
//        /* Uncomment and play around with the configuration 👨‍🔬 🚀 */
//
//        /* Set this to true if you want to force the  library output to be a squared image. Defaults to false */
//         config.library.onlySquare = false
//        config.library.isSquareByDefault = false
//        /* Set this to true if you want to force the camera output to be a squared image. Defaults to true */
//        // config.onlySquareImagesFromCamera = false
//        /* Ex: cappedTo:1024 will make sure images from the library or the camera will be
//           resized to fit in a 1024x1024 box. Defaults to original image size. */
//        // config.targetImageSize = .cappedTo(size: 1024)
//        /* Choose what media types are available in the library. Defaults to `.photo` */
//        config.library.mediaType = .photoAndVideo
//        config.library.itemOverlayType = .grid
//        /* Enables selecting the front camera by default, useful for avatars. Defaults to false */
//        // config.usesFrontCamera = true
//        /* Adds a Filter step in the photo taking process. Defaults to true */
//         config.showsPhotoFilters = false
//        /* Manage filters by yourself */
////        config.filters = [YPFilter(name: "Mono", coreImageFilterName: "CIPhotoEffectMono"),
////                          YPFilter(name: "Normal", coreImageFilterName: "")]
////        config.filters.remove(at: 1)
////        config.filters.insert(YPFilter(name: "Blur", coreImageFilterName: "CIBoxBlur"), at: 1)
//        /* Enables you to opt out from saving new (or old but filtered) images to the
//           user's photo library. Defaults to true. */
//        config.shouldSaveNewPicturesToAlbum = false
//
//        /* Choose the videoCompression. Defaults to AVAssetExportPresetHighestQuality */
//        config.video.compression = AVAssetExportPresetMediumQuality
//
//        /* Defines the name of the album when saving pictures in the user's photo library.
//           In general that would be your App name. Defaults to "DefaultYPImagePickerAlbumName" */
//        // config.albumName = "ThisIsMyAlbum"
//        /* Defines which screen is shown at launch. Video mode will only work if `showsVideo = true`.
//           Default value is `.photo` */
//        config.startOnScreen = .library
//
//        /* Defines which screens are shown at launch, and their order.
//           Default value is `[.library, .photo]` */
////        config.screens = [.library, .photo, .video]
//        config.screens = [.library]
//
//        /* Can forbid the items with very big height with this property */
////        config.library.minWidthForItem = UIScreen.main.bounds.width * 0.8
//        /* Defines the time limit for recording videos.
//           Default is 30 seconds. */
//        // config.video.recordingTimeLimit = 5.0
//        /* Defines the time limit for videos from the library.
//           Defaults to 60 seconds. */
//        config.video.libraryTimeLimit = 500
//
//        /* Adds a Crop step in the photo taking process, after filters. Defaults to .none */
//        config.showsCrop = .rectangle(ratio: 16/9)
//
//        /* Defines the overlay view for the camera. Defaults to UIView(). */
//        // let overlayView = UIView()
//        // overlayView.backgroundColor = .red
//        // overlayView.alpha = 0.3
//        // config.overlayView = overlayView
//        /* Customize wordings */
//        config.wordings.libraryTitle = "Gallery"
//
//        /* Defines if the status bar should be hidden when showing the picker. Default is true */
//        config.hidesStatusBar = false
//
//        /* Defines if the bottom bar should be hidden when showing the picker. Default is false */
//        config.hidesBottomBar = false
//
//        config.maxCameraZoomFactor = 2.0
//
//        config.library.maxNumberOfItems = 5
//        config.gallery.hidesRemoveButton = false
//
//        /* Disable scroll to change between mode */
//         config.isScrollToChangeModesEnabled = false
//        //config.library.minNumberOfItems = 2
//        /* Skip selection gallery after multiple selections */
//        // config.library.skipSelectionsGallery = true
//        /* Here we use a per picker configuration. Configuration is always shared.
//           That means than when you create one picker with configuration, than you can create other picker with just
//           let picker = YPImagePicker() and the configuration will be the same as the first picker. */
//
//        /* Only show library pictures from the last 3 days */
//        //let threDaysTimeInterval: TimeInterval = 3 * 60 * 60 * 24
//        //let fromDate = Date().addingTimeInterval(-threDaysTimeInterval)
//        //let toDate = Date()
//        //let options = PHFetchOptions()
//        // options.predicate = NSPredicate(format: "creationDate > %@ && creationDate < %@", fromDate as CVarArg, toDate as CVarArg)
//        //
//        ////Just a way to set order
//        //let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
//        //options.sortDescriptors = [sortDescriptor]
//        //
//        //config.library.options = options
//        config.library.preselectedItems = selectedItems
//
//
//        // Customise fonts
//        //config.fonts.menuItemFont = UIFont.systemFont(ofSize: 22.0, weight: .semibold)
//        //config.fonts.pickerTitleFont = UIFont.systemFont(ofSize: 22.0, weight: .black)
//        //config.fonts.rightBarButtonFont = UIFont.systemFont(ofSize: 22.0, weight: .bold)
//        //config.fonts.navigationBarTitleFont = UIFont.systemFont(ofSize: 22.0, weight: .heavy)
//        //config.fonts.leftBarButtonFont = UIFont.systemFont(ofSize: 22.0, weight: .heavy)
//        let picker = YPImagePicker(configuration: config)
//
//        picker.imagePickerDelegate = self
//
//        /* Change configuration directly */
//        // YPImagePickerConfiguration.shared.wordings.libraryTitle = "Gallery2"
//        /* Multiple media implementation */
//        picker.didFinishPicking { [unowned picker] items, cancelled in
//
//            if cancelled {
//                print("Picker was canceled")
//                picker.dismiss(animated: true, completion: nil)
//                return
//            }
//            _ = items.map { print("🧀 \($0)") }
//
//            self.selectedItems = items
//            if let firstItem = items.first {
//                switch firstItem {
//                case .photo(let photo):
//                    self.selectedImageV.image = photo.image
//                    picker.dismiss(animated: true, completion: nil)
//                case .video(let video):
//                    self.selectedImageV.image = video.thumbnail
//                    picker.dismiss(animated: true, completion: nil)
////                    let assetURL = video.url
////                    let playerVC = AVPlayerViewController()
////                    let player = AVPlayer(playerItem: AVPlayerItem(url:assetURL))
////                    playerVC.player = player
////
////                    picker.dismiss(animated: true, completion: { [weak self] in
////                        self?.present(playerVC, animated: true, completion: nil)
////                        print("😀 \(String(describing: self?.resolutionForLocalVideo(url: assetURL)!))")
////                    })
//                }
//            }
//        }
//
//        /* Single Photo implementation. */
//        // picker.didFinishPicking { [unowned picker] items, _ in
//        //     self.selectedItems = items
//        //     self.selectedImageV.image = items.singlePhoto?.image
//        //     picker.dismiss(animated: true, completion: nil)
//        // }
//        /* Single Video implementation. */
//        //picker.didFinishPicking { [unowned picker] items, cancelled in
//        //    if cancelled { picker.dismiss(animated: true, completion: nil); return }
//        //
//        //    self.selectedItems = items
//        //    self.selectedImageV.image = items.singleVideo?.thumbnail
//        //
//        //    let assetURL = items.singleVideo!.url
//        //    let playerVC = AVPlayerViewController()
//        //    let player = AVPlayer(playerItem: AVPlayerItem(url:assetURL))
//        //    playerVC.player = player
//        //
//        //    picker.dismiss(animated: true, completion: { [weak self] in
//        //        self?.present(playerVC, animated: true, completion: nil)
//        //        print("😀 \(String(describing: self?.resolutionForLocalVideo(url: assetURL)!))")
//        //    })
//        //}
//        present(picker, animated: true, completion: nil)
//    }
//
//    /* Gives a resolution for the video by URL */
//    func resolutionForLocalVideo(url: URL) -> CGSize? {
//        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
//        let size = track.naturalSize.applying(track.preferredTransform)
//        return CGSize(width: abs(size.width), height: abs(size.height))
//    }
//
//    func noPhotos() {}
//
//    func shouldAddToSelection(indexPath: IndexPath, numSelections: Int) -> Bool {
//        return true// indexPath.row != 2
//    }
//}

