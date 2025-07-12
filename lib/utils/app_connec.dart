import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppConnec {

  Future<void> openMap(double lat, double lon) async {
    final googleMapsWebUrl = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon');

 if (await canLaunchUrl(googleMapsWebUrl)) {
      await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalApplication);
    } else {
      print("Không thể mở Google Maps");
    }
  }
}