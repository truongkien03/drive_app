import 'lib/services/location_service.dart';
import 'lib/services/driver_service.dart';

void main() async {
  print('🧪 Testing Location Service...');

  final locationService = LocationService();
  final driverService = DriverService();

  try {
    // Test location service initialization
    print('📍 Checking location permissions...');
    final hasPermission = await locationService.checkLocationPermission();
    print('✅ Permission check result: $hasPermission');

    // Test location stats
    print('📊 Getting location stats...');
    final stats = locationService.getLocationStats();
    print('📈 Location stats: $stats');

    // Test driver service initialization
    print('🚗 Initializing driver service...');
    await DriverService.initialize();
    print('✅ Driver service initialized');

    // Check if location service is healthy
    print('❤️ Location service health: ${locationService.isHealthy}');

    print('🎉 All tests completed successfully!');
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
