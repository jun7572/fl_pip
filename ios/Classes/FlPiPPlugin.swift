import AVKit
import Flutter
import Foundation
import UIKit




public class FlPiPPlugin: NSObject, FlutterPlugin, AVPictureInPictureControllerDelegate {
    private var registrar: FlutterPluginRegistrar
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var pipController: AVPictureInPictureController?


    
    
    
    private var flutterController: FlutterViewController?

    private var createNewEngine: Bool = false
    private var isEnable: Bool = false
//    private var enabledWhenBackground: Bool = false
    private var rootWindow: UIWindow?
    
    private var audioPlayer: AVAudioPlayer?
    

    private var channel: FlutterMethodChannel
//    private var viewController: ViewController?
    var customView: UIView!
    var textView: UITextView!
    var textViewNum: UITextView!
    var textViewCurrentNum: UITextView!
    

    
    

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl_pip", binaryMessenger: registrar.messenger())
        let instance = FlPiPPlugin(channel, registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }

    init(_ channel: FlutterMethodChannel, _ registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        self.channel = channel
//        viewController = ViewController(registrar: registrar)
        super.init()
    }
    // 配置自定义view
    private func setupCustomView() {
        customView = UIView()
        customView.backgroundColor = .black
        
        
        let v = UIView()
        v.frame =  CGRect(x: 0, y: 0, width: 20, height: 80)
        //名字
        textView = UITextView()
        //百分比
        textViewNum = UITextView()
        //当前值
        textViewCurrentNum = UITextView()
        //logo
        let imageView = UIImageView()
        let image = UIImage(named: "logo")
        imageView.backgroundColor = .black
        imageView.image = image
        let textViewlogo = UITextView()
        textViewlogo.text = "交易侠"
        textViewlogo.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textViewlogo.textColor = .white
        textViewlogo.backgroundColor = .black
        textView.text = ""
        textView.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textViewNum.text = ""
        textViewNum.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        textViewCurrentNum.font = UIFont.systemFont(ofSize: 14, weight: .regular)

        textView.backgroundColor = .black
        textViewNum.backgroundColor = .black
        textViewCurrentNum.backgroundColor = .black
        textView.textColor = .white
        
        textView.frame = CGRect(x: v.frame.maxX, y: 0, width: 90, height: 80)
        textViewCurrentNum.frame = CGRect(x: textView.frame.maxX, y: 0, width: 70, height: 80)
        textViewNum.frame = CGRect(x: textViewCurrentNum.frame.maxX-10, y: 0, width: 80, height: 80)
        
        imageView.frame = CGRect(x: textViewNum.frame.maxX+20, y: 9, width: 15, height: 15)
        textViewlogo.frame = CGRect(x: imageView.frame.maxX, y: 0, width: 60, height: 80)

        textView.textColor = .white
        textView.isUserInteractionEnabled = false
       
        customView.addSubview(v)
        customView.addSubview(textView)
        customView.addSubview(textViewCurrentNum)
        customView.addSubview(textViewNum)
        customView.addSubview(imageView)
        customView.addSubview(textViewlogo)
//        textView.snp.makeConstraints { (make) in
//            make.edges.eq
//        }
    }

    private var enableArgs: [String: Any?] = [:]

    private var isCallDisable: Bool = false

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enable":
//            if isAvailable(), !isEnable {
                enableArgs = call.arguments as! [String: Any?]
//                createNewEngine = enableArgs["createNewEngine"] as! Bool
//                enabledWhenBackground = enableArgs["enabledWhenBackground"] as! Bool
////                rootWindow = windows()?.filter { window in
////                    window.isKeyWindow
////                }.first
                 enable()
                result(isEnable)
                return
//            }
            result(false)
        case "disable":
//            isCallDisable = true
            dispose()
//            enableArgs = [:]
//            setPiPStatus(1)
            result(true)
        case "playerStart":
            playerStart()
            result(true)
        case "updateData":
            if(textView != nil&&textViewNum != nil&&textViewCurrentNum != nil&&call.arguments != nil){
                let args = call.arguments as! [String: Any?]
                textView.text = args["data"] as! String
                textViewNum.text = args["numPercent"] as! String
                textViewCurrentNum.text = args["numStr"] as! String
                let bbb=args["color"] as! Bool;
                let color = bbb ? colorWithHexString("#FF4C5C",alpha: 1) : colorWithHexString("#00AF92",alpha: 1)
                textViewNum.textColor = color
                textViewCurrentNum.textColor = color
                
            }
            result(true)
        case "isActive":
//            var map = ["createNewEngine": createNewEngine, "enabledWhenBackground": enabledWhenBackground] as [String: Any]
//            if isAvailable() {
//                map["status"] = (pipController?.isPictureInPictureActive ?? false) ? 0 : 1
//            } else {
//                map["status"] = 2
//            }
            print("")
//            result()
        case "toggle":
            let value = call.arguments as! Bool
            if value {
                /// 切换前台
            } else {
                /// 切换后台
//                background()
            }
            result(nil)
        case "available":
            result(isAvailable())
        case "stopPip":
            stopPip()
            
        default:
            result(nil)
        }
    }
    

    func enable() -> Bool {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            print("FlPiP error : AVAudioSession.sharedInstance()")
            return false
        }
        let path = enableArgs["path"] as! String
        let packageName = enableArgs["packageName"] as? String
        let assetPath: String
//        if packageName != nil {
//            assetPath = registrar.lookupKey(forAsset: path, fromPackage: packageName!)
//        } else {
            assetPath = registrar.lookupKey(forAsset: path)
//        }
        let bundlePath = Bundle.main.path(forResource: assetPath, ofType: nil)
        if bundlePath == nil {
            print("FlPiP error : Unable to load video resources, \(path) in \(packageName ?? "current")")
            return false
        }
        if isAvailable() {
            if rootWindow == nil {
                print("FlPiP error : rootWindow is null")
                return false
            }

//            playerLayer = AVPlayerLayer()
          

            let x = enableArgs["left"] as? CGFloat ?? UIScreen.main.bounds.size.width/2
            let y = enableArgs["top"] as? CGFloat ?? UIScreen.main.bounds.size.height/2
            let width = enableArgs["width"] as? CGFloat ?? 1
            let height = enableArgs["height"] as? CGFloat ?? 1

//            playerLayer!.frame = .init(x: x, y: y, width: 854, height: 80)
//            player = AVPlayer(playerItem: AVPlayerItem(asset: AVURLAsset(url: URL(fileURLWithPath: bundlePath!))))
//            playerLayer!.player = queuePlayer!
//            player!.isMuted = true
//            player!.allowsExternalPlayback = true
//            player!.accessibilityElementsHidden = true
           
            
//            playerLayer = AVPlayerLayer()
//            playerLayer!.frame = .init(x: x, y: y, width: 1, height: 1)
//
////
//            let playerItem =   getAssets()
//            let player = AVPlayer.init(playerItem: playerItem)
//            playerLayer!.player = player
//            player.isMuted = true
//            player.allowsExternalPlayback = true
//            player.play()
//            pipController = AVPictureInPictureController(playerLayer: playerLayer!)
//            pipController!.delegate = self
//
//            let enableControls = enableArgs["enableControls"] as! Bool
//            pipController!.setValue(enableControls ? 0 : 1, forKey: "controlsStyle")
//
//            let enablePlayback = enableArgs["enablePlayback"] as! Bool
//            pipController!.setValue(enablePlayback ? 0 : 1, forKey: "requiresLinearPlayback")
//            if #available(iOS 14.0, *) {
//                    pipController!.requiresLinearPlayback = true
//                }
//            if #available(iOS 14.2, *) {
//                pipController!.canStartPictureInPictureAutomaticallyFromInline = true
//            }
            
            //设置自定义布局
//            setupCustomView();
            
//            player.play()
            
          
//            rootWindow!.rootViewController?.view?.layer.addSublayer(playerLayer!)
            
//            rootWindow!.rootViewController?=ViewController(registrar: registrar)
//            if !enabledWhenBackground {
//                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.4) {
//                    self.pipController!.startPictureInPicture()
//                }
//            if(pipController != nil){
                self.pipController?.startPictureInPicture()
//            }
            
//            }
            return true
        }
        return false
    }
    
    public func playerStart(){
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch {
            print("FlPiP error : AVAudioSession.sharedInstance()")
            
        }
        print("ios-play-start")
        playerLayer = AVPlayerLayer()
        playerLayer!.frame = .init(x: UIScreen.main.bounds.size.width/2, y: UIScreen.main.bounds.size.height/2, width: 1, height: 1)
        let playerItem =   getAssets()
        let player = AVPlayer.init(playerItem: playerItem)
        playerLayer!.player = player
        player.isMuted = true
        player.allowsExternalPlayback = true
        player.play()
        
        pipController = AVPictureInPictureController(playerLayer: playerLayer!)
        pipController!.delegate = self
        

        pipController!.setValue(1, forKey: "controlsStyle")


        pipController!.setValue(0, forKey: "requiresLinearPlayback")
        if #available(iOS 14.0, *) {
                pipController!.requiresLinearPlayback = true
            }
        if #available(iOS 14.2, *) {
            pipController!.canStartPictureInPictureAutomaticallyFromInline = true
        }
        if( rootWindow == nil){
            rootWindow = windows()?.filter { window in
                window.isKeyWindow
            }.first
        }
        rootWindow!.rootViewController?.view?.layer.addSublayer(playerLayer!)
        setupCustomView()
       
        
        

        
        
    }
    
   
 
    public func getAssets() -> AVPlayerItem{
      let  assetPath = registrar.lookupKey(forAsset: "assets/landscape.mp4", fromPackage: "fl_pip")
        let bundlePath = Bundle.main.path(forResource: assetPath, ofType: nil)
        let avitem = AVPlayerItem(asset: AVURLAsset(url: URL(fileURLWithPath: bundlePath!)))
        return avitem;

    }
    public func getAudioAssets() -> AVPlayerItem{
      let  assetPath = registrar.lookupKey(forAsset: "assets/slience.mp3", fromPackage: "fl_pip")
        let bundlePath = Bundle.main.path(forResource: assetPath, ofType: nil)
        let avitem = AVPlayerItem(asset: AVURLAsset(url: URL(fileURLWithPath: bundlePath!)))
        return avitem;

    }




    public func isAvailable() -> Bool {
        AVPictureInPictureController.isPictureInPictureSupported()
    }

    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {

        if let window = UIApplication.shared.windows.first {
            // 把自定义view加到画中画上
            window.addSubview(customView)
            // 使用自动布局
            customView.snp.makeConstraints { (make) -> Void in
                make.edges.equalToSuperview()
            }
        }
    }



    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//        if !isCallDisable {
//            dispose()
//        }
//        if(pipController != nil){
            print("reset===> pip")
            playerStart()
//        }
       
    }
   public func stopPip(){
        if(pipController != nil){
            print("ios===>stop pip")
            pipController?.stopPictureInPicture()
            

        }
    }
    

    public func dispose() {
        playerLayer = nil
        
        player = nil
        pipController?.stopPictureInPicture()
       

        pipController = nil
        
        
        
        
        
        
        
    }

//    public func applicationWillEnterForeground(_ application: UIApplication) {
//        if enabledWhenBackground {
//            // print("app will enter foreground")
//        }
//    }
//
//    public func applicationDidEnterBackground(_ application: UIApplication) {
//        if enabledWhenBackground {
//            if createNewEngine {
//                createFlutterEngine()
//            }
//            pipController?.startPictureInPicture()
//        }
//    }

    public func windows() -> [UIWindow]? {
        return UIApplication.shared.windows
        //        if #available(iOS 13.0, *) {
        //            let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene)
        //            return windowScene?.windows
        //        } else {
        //            return UIApplication.shared.windows
        //        }
    }
    
    public  func colorWithHexString(_ hex: String, alpha: CGFloat) -> UIColor {
        var color = UIColor.black
        var cStr: String = hex.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()

        if cStr.hasPrefix("#") {
            let index = cStr.index(after: cStr.startIndex)
            cStr = String(cStr[index...])
        }
        if cStr.count != 6 {
            return UIColor.black
        }

        let rRange = cStr.startIndex ..< cStr.index(cStr.startIndex, offsetBy: 2)
        let rStr = String(cStr[rRange])

        let gRange = cStr.index(cStr.startIndex, offsetBy: 2) ..< cStr.index(cStr.startIndex, offsetBy: 4)
        let gStr = String(cStr[gRange])

        let bIndex = cStr.index(cStr.endIndex, offsetBy: -2)
        let bStr = String(cStr[bIndex...])

        var r: CUnsignedInt = 0, g: CUnsignedInt = 0, b: CUnsignedInt = 0
        Scanner(string: rStr).scanHexInt32(&r)
        Scanner(string: gStr).scanHexInt32(&g)
        Scanner(string: bStr).scanHexInt32(&b)

        color = UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(1))

        return color
    }
    
}
