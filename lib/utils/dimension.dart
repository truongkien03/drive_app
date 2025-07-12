import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class Dimension {

  // Sử dụng MediaQuery thay vì Get.context để tránh null
  static double get screenHeight => MediaQuery.of(Get.context!).size.height;
  static double get screenWidth => MediaQuery.of(Get.context!).size.width;
  
  // Fallback values nếu context chưa sẵn sàng
  static double get _defaultHeight => 838.4;
  static double get _defaultWidth => 384.0;
  
  // Safe getters với fallback
  static double get _safeScreenHeight {
    try {
      return MediaQuery.of(Get.context!).size.height;
    } catch (e) {
      return _defaultHeight;
    }
  }
  
  static double get _safeScreenWidth {
    try {
      return MediaQuery.of(Get.context!).size.width;
    } catch (e) {
      return _defaultWidth;
    }
  }

  // height: 838.4
  // width: 384.0
  static double get screenHeightSafe => _safeScreenHeight;
  static double get screenWidthSafe => _safeScreenWidth;
  
  // 320
  static double get pageView => screenHeightSafe/2.62;
  // 220
  static double get pageViewContainer => screenHeightSafe/3.81;
  // 120
  static double get pageViewTextContainer => screenHeightSafe/6.80;

  static double get height5 => screenHeightSafe/169.68;
  static double get height8 => screenHeightSafe/104.8;
  static double get height10 => screenHeightSafe/83.84;
  static double get height12 => screenHeightSafe/69.87;
  static double get height15 => screenHeightSafe/55.89;
  static double get height20 => screenHeightSafe/41.92;
  static double get height30 => screenHeightSafe/28.28;
  static double get height40 => screenHeightSafe/21.21;
  static double get height45 => screenHeightSafe/18.85;
  static double get height50 => screenHeightSafe/16.76;
  static double get height80 => screenHeightSafe/10.605;
  static double get height100 => screenHeightSafe/8.484;
  static double get height120 => screenHeightSafe/7.07;
  static double get height200 => screenHeightSafe/4.192;
  static double get height400 => screenHeightSafe/2.096;
  static double get height2 => screenHeightSafe/419.2;
  static double get height4 => screenHeightSafe/209.6;
  static double get height6 => screenHeightSafe/139.73;
  static double get height16 => screenHeightSafe/52.4;
  static double get height18 => screenHeightSafe/46.58;
  static double get width4 => screenWidthSafe/96;
  static double get width6 => screenWidthSafe/64;
  static double get icon18 => screenHeightSafe/46.58;
  static double get radius10 => screenHeightSafe/83.84;
  static double get font_size12 => screenHeightSafe/69.87;

  static double get width5 => screenHeightSafe/169.68;
  static double get width8 => screenHeightSafe/104.8;
  static double get width10 => screenHeightSafe/83.84;
  static double get width12 => screenHeightSafe/69.87;
  static double get width15 => screenHeightSafe/55.89;
  static double get width16 => screenHeightSafe/52.4;
  static double get width20 => screenHeightSafe/41.92;
  static double get width30 => screenHeightSafe/28.28;
  static double get width40 => screenHeightSafe/21.21;
  static double get width45 => screenHeightSafe/18.85;
  static double get width50 => screenHeightSafe/16.76;
  static double get width80 => screenHeightSafe/10.605;
  static double get width100 => screenHeightSafe/8.484;
  static double get width120 => screenHeightSafe/7.07;

  // font size
  static double get font_size16 => screenHeightSafe/53;
  static double get font_size18 => screenHeightSafe/46.58;
  static double get font_size20 => screenHeightSafe/41.92;
  static double get font_size26 => screenHeightSafe/32.61;
  static double get font_size14 => screenHeightSafe/59.88;

  static double get radius8 => screenHeightSafe/104.8;
  static double get radius12 => screenHeightSafe/69.87;
  static double get radius15 => screenHeightSafe/56.56;
  static double get radius20 => screenHeightSafe/42.42;
  static double get radius30 => screenHeightSafe/28.28;

  // icon size
  static double get icon15 => screenHeightSafe/56.55;
  static double get icon16 => screenHeightSafe/53;
  static double get icon20 => screenHeightSafe/42.4;
  static double get icon24 => screenHeightSafe/35.34;
  static double get icon48 => screenHeightSafe/17.67;

  // Additional dimensions for HistoryScreen
  static double get radius2 => screenHeightSafe/419.2;
  static double get radius16 => screenHeightSafe/52.4;
  static double get font_size10 => screenHeightSafe/83.84;

  // list view food
  static double get listViewImageSize120 => screenWidthSafe/3.2;
  static double get listViewText100 => screenWidthSafe/3.84;

  static double get popularViewImage => screenHeightSafe/2.42;
}