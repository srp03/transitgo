import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../core/config/app_config.dart';

class UserLocationState {
  final double latitude;
  final double longitude;
  final bool isPermissionGranted;
  final bool isDefaultLocation;
  final String? error;
  final bool isLoading;

  const UserLocationState({
    required this.latitude,
    required this.longitude,
    required this.isPermissionGranted,
    required this.isDefaultLocation,
    this.error,
    this.isLoading = false,
  });

  factory UserLocationState.defaultLocation({bool isLoading = false, String? error}) {
    return UserLocationState(
      latitude: AppConfig.defaultLatitude,
      longitude: AppConfig.defaultLongitude,
      isPermissionGranted: false,
      isDefaultLocation: true,
      isLoading: isLoading,
      error: error,
    );
  }

  UserLocationState copyWith({
    double? latitude,
    double? longitude,
    bool? isPermissionGranted,
    bool? isDefaultLocation,
    String? error,
    bool? isLoading,
  }) {
    return UserLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPermissionGranted: isPermissionGranted ?? this.isPermissionGranted,
      isDefaultLocation: isDefaultLocation ?? this.isDefaultLocation,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocationNotifier extends Notifier<UserLocationState> {
  @override
  UserLocationState build() {
    Future.microtask(() => checkPermissionAndFetchLocation(silent: true));
    return UserLocationState.defaultLocation();
  }

  Future<void> checkPermissionAndFetchLocation({bool silent = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = UserLocationState.defaultLocation(
          error: silent ? null : 'Location services are disabled on device.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!silent) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied) {
          state = UserLocationState.defaultLocation(
            error: silent ? null : 'Location permission denied.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = UserLocationState.defaultLocation(
          error: silent ? null : 'Location permissions permanently denied in settings.',
        );
        return;
      }

      // Permission granted -> get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );

      state = UserLocationState(
        latitude: position.latitude,
        longitude: position.longitude,
        isPermissionGranted: true,
        isDefaultLocation: false,
        isLoading: false,
      );
    } catch (e) {
      // Fallback safely to Thane station
      state = UserLocationState.defaultLocation(
        error: silent ? null : 'Could not obtain GPS position. Using Thane Station hub.',
      );
    }
  }

  Future<void> requestLocation() async {
    await checkPermissionAndFetchLocation(silent: false);
  }
}

final locationProvider = NotifierProvider<LocationNotifier, UserLocationState>(LocationNotifier.new);
