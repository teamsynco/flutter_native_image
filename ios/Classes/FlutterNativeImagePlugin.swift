import Flutter
import UIKit
import ImageIO
import MobileCoreServices

@objc(FlutterNativeImagePlugin)
public class FlutterNativeImagePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_native_image", binaryMessenger: registrar.messenger())
    let instance = FlutterNativeImagePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "compressImage":
      guard let args = call.arguments as? [String: Any],
            let filePath = args["file"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT",
                          message: "File path cannot be null",
                          details: nil))
        return
      }
      
      let quality = args["quality"] as? Int ?? 70
      let percentage = args["percentage"] as? Int ?? 70
      let targetWidth = args["targetWidth"] as? Int ?? 0
      let targetHeight = args["targetHeight"] as? Int ?? 0
      
      do {
        let compressedPath = try compressImage(filePath: filePath,
                                             quality: quality,
                                             percentage: percentage,
                                             targetWidth: targetWidth,
                                             targetHeight: targetHeight)
        result(compressedPath)
      } catch {
        result(FlutterError(code: "COMPRESSION_ERROR",
                          message: error.localizedDescription,
                          details: nil))
      }
      
    case "getImageProperties":
      guard let args = call.arguments as? [String: Any],
            let filePath = args["file"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT",
                          message: "File path cannot be null",
                          details: nil))
        return
      }
      
      do {
        let properties = try getImageProperties(filePath: filePath)
        result(properties)
      } catch {
        result(FlutterError(code: "PROPERTIES_ERROR",
                          message: error.localizedDescription,
                          details: nil))
      }
      
    case "cropImage":
      guard let args = call.arguments as? [String: Any],
            let filePath = args["file"] as? String,
            let originX = args["originX"] as? Int,
            let originY = args["originY"] as? Int,
            let width = args["width"] as? Int,
            let height = args["height"] as? Int else {
        result(FlutterError(code: "INVALID_ARGUMENT",
                          message: "Invalid arguments",
                          details: nil))
        return
      }
      
      do {
        let croppedPath = try cropImage(filePath: filePath,
                                      originX: originX,
                                      originY: originY,
                                      width: width,
                                      height: height)
        result(croppedPath)
      } catch {
        result(FlutterError(code: "CROP_ERROR",
                          message: error.localizedDescription,
                          details: nil))
      }
      
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func compressImage(filePath: String,
                            quality: Int,
                            percentage: Int,
                            targetWidth: Int,
                            targetHeight: Int) throws -> String {
    guard let image = UIImage(contentsOfFile: filePath) else {
      throw NSError(domain: "FlutterNativeImage",
                   code: 1,
                   userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
    }
    
    var newImage = image
    
    if targetWidth > 0 && targetHeight > 0 {
      let size = CGSize(width: targetWidth, height: targetHeight)
      UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
      image.draw(in: CGRect(origin: .zero, size: size))
      newImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
      UIGraphicsEndImageContext()
    } else if percentage < 100 {
      let scale = CGFloat(percentage) / 100.0
      let size = CGSize(width: image.size.width * scale,
                       height: image.size.height * scale)
      UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
      image.draw(in: CGRect(origin: .zero, size: size))
      newImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
      UIGraphicsEndImageContext()
    }
    
    let compressionQuality = CGFloat(quality) / 100.0
    let data = newImage.jpegData(compressionQuality: compressionQuality)
    
    let fileName = "compressed_\(Int(Date().timeIntervalSince1970)).jpg"
    let outputPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
    
    try data?.write(to: URL(fileURLWithPath: outputPath))
    return outputPath
  }
  
  private func getImageProperties(filePath: String) throws -> [String: Any] {
    guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: filePath) as CFURL, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
      throw NSError(domain: "FlutterNativeImage",
                   code: 2,
                   userInfo: [NSLocalizedDescriptionKey: "Failed to get image properties"])
    }
    
    let width = properties[kCGImagePropertyPixelWidth as String] as? Int ?? 0
    let height = properties[kCGImagePropertyPixelHeight as String] as? Int ?? 0
    let orientation = properties[kCGImagePropertyOrientation as String] as? Int ?? 1
    
    return [
      "width": width,
      "height": height,
      "orientation": orientation
    ]
  }
  
  private func cropImage(filePath: String,
                        originX: Int,
                        originY: Int,
                        width: Int,
                        height: Int) throws -> String {
    guard let image = UIImage(contentsOfFile: filePath) else {
      throw NSError(domain: "FlutterNativeImage",
                   code: 3,
                   userInfo: [NSLocalizedDescriptionKey: "Failed to load image"])
    }
    
    let cropRect = CGRect(x: originX,
                         y: originY,
                         width: width,
                         height: height)
    
    guard let croppedCGImage = image.cgImage?.cropping(to: cropRect) else {
      throw NSError(domain: "FlutterNativeImage",
                   code: 4,
                   userInfo: [NSLocalizedDescriptionKey: "Failed to crop image"])
    }
    
    let croppedImage = UIImage(cgImage: croppedCGImage)
    let data = croppedImage.jpegData(compressionQuality: 1.0)
    
    let fileName = "cropped_\(Int(Date().timeIntervalSince1970)).jpg"
    let outputPath = (NSTemporaryDirectory() as NSString).appendingPathComponent(fileName)
    
    try data?.write(to: URL(fileURLWithPath: outputPath))
    return outputPath
  }
} 