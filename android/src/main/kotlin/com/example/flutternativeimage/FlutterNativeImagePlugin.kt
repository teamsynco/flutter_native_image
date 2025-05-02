package com.example.flutternativeimage

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream

class FlutterNativeImagePlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_native_image")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "compressImage" -> {
        val filePath = call.argument<String>("file")
        val quality = call.argument<Int>("quality") ?: 70
        val percentage = call.argument<Int>("percentage") ?: 70
        val targetWidth = call.argument<Int>("targetWidth") ?: 0
        val targetHeight = call.argument<Int>("targetHeight") ?: 0

        if (filePath == null) {
          result.error("INVALID_ARGUMENT", "File path cannot be null", null)
          return
        }

        try {
          val compressedFile = compressImage(filePath, quality, percentage, targetWidth, targetHeight)
          result.success(compressedFile.absolutePath)
        } catch (e: Exception) {
          result.error("COMPRESSION_ERROR", e.message, null)
        }
      }
      "getImageProperties" -> {
        val filePath = call.argument<String>("file")
        if (filePath == null) {
          result.error("INVALID_ARGUMENT", "File path cannot be null", null)
          return
        }

        try {
          val properties = getImageProperties(filePath)
          result.success(properties)
        } catch (e: Exception) {
          result.error("PROPERTIES_ERROR", e.message, null)
        }
      }
      "cropImage" -> {
        val filePath = call.argument<String>("file")
        val originX = call.argument<Int>("originX") ?: 0
        val originY = call.argument<Int>("originY") ?: 0
        val width = call.argument<Int>("width") ?: 0
        val height = call.argument<Int>("height") ?: 0

        if (filePath == null) {
          result.error("INVALID_ARGUMENT", "File path cannot be null", null)
          return
        }

        try {
          val croppedFile = cropImage(filePath, originX, originY, width, height)
          result.success(croppedFile.absolutePath)
        } catch (e: Exception) {
          result.error("CROP_ERROR", e.message, null)
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun compressImage(
    filePath: String,
    quality: Int,
    percentage: Int,
    targetWidth: Int,
    targetHeight: Int
  ): File {
    val file = File(filePath)
    val options = BitmapFactory.Options()
    options.inJustDecodeBounds = true
    BitmapFactory.decodeFile(filePath, options)

    val imageHeight = options.outHeight
    val imageWidth = options.outWidth
    var scale = 1

    if (targetWidth > 0 && targetHeight > 0) {
      val widthScale = imageWidth / targetWidth
      val heightScale = imageHeight / targetHeight
      scale = Math.max(widthScale, heightScale)
    } else if (percentage < 100) {
      scale = 100 / percentage
    }

    options.inJustDecodeBounds = false
    options.inSampleSize = scale

    var bitmap = BitmapFactory.decodeFile(filePath, options)
    val exif = ExifInterface(filePath)
    val orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)

    if (orientation != ExifInterface.ORIENTATION_NORMAL) {
      val matrix = Matrix()
      when (orientation) {
        ExifInterface.ORIENTATION_ROTATE_90 -> matrix.postRotate(90f)
        ExifInterface.ORIENTATION_ROTATE_180 -> matrix.postRotate(180f)
        ExifInterface.ORIENTATION_ROTATE_270 -> matrix.postRotate(270f)
      }
      bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    val outputFile = File(context.cacheDir, "compressed_${System.currentTimeMillis()}.jpg")
    val outputStream = FileOutputStream(outputFile)
    bitmap.compress(Bitmap.CompressFormat.JPEG, quality, outputStream)
    outputStream.close()
    bitmap.recycle()

    return outputFile
  }

  private fun getImageProperties(filePath: String): Map<String, Any> {
    val options = BitmapFactory.Options()
    options.inJustDecodeBounds = true
    BitmapFactory.decodeFile(filePath, options)

    val exif = ExifInterface(filePath)
    val orientation = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)

    return mapOf(
      "width" to options.outWidth,
      "height" to options.outHeight,
      "orientation" to orientation
    )
  }

  private fun cropImage(
    filePath: String,
    originX: Int,
    originY: Int,
    width: Int,
    height: Int
  ): File {
    val bitmap = BitmapFactory.decodeFile(filePath)
    val croppedBitmap = Bitmap.createBitmap(bitmap, originX, originY, width, height)
    bitmap.recycle()

    val outputFile = File(context.cacheDir, "cropped_${System.currentTimeMillis()}.jpg")
    val outputStream = FileOutputStream(outputFile)
    croppedBitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
    outputStream.close()
    croppedBitmap.recycle()

    return outputFile
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
} 