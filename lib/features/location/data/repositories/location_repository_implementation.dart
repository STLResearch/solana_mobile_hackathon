import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:geolocator/geolocator.dart'
    show
        Geolocator,
        LocationPermission,
        LocationSettings,
        Position,
        ServiceStatus;
import 'package:sky_trade/core/errors/failures/location_failure.dart';
import 'package:sky_trade/core/utils/clients/data_handler.dart';
import 'package:sky_trade/features/location/domain/entities/location_entity.dart';
import 'package:sky_trade/features/location/domain/repositories/location_repository.dart';

final class LocationRepositoryImplementation
    with DataHandler
    implements LocationRepository {
  @override
  Future<LocationPositionEntity> get locationPosition async {
    final lastKnownPosition = await Geolocator.getLastKnownPosition();

    if (lastKnownPosition != null) {
      return LocationPositionEntity(
        latitude: lastKnownPosition.latitude,
        longitude: lastKnownPosition.longitude,
        heading: lastKnownPosition.heading,
      );
    }

    final currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(),
    );

    return LocationPositionEntity(
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
      heading: currentPosition.heading,
    );
  }

  @override
  Stream<Either<LocationPositionFailure, LocationPositionEntity>>
      get locationPositionStream => transformData<LocationPositionFailure,
              Position, LocationPositionEntity>(
            sourceStream: () => Geolocator.getPositionStream(
              locationSettings: const LocationSettings(),
            ),
            onData: (position) => LocationPositionEntity(
              latitude: position.latitude,
              longitude: position.longitude,
              heading: position.heading,
            ),
            onError: LocationPositionFailure.new,
          );

  @override
  Future<LocationServiceStatusEntity> get locationServiceStatus async {
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    return LocationServiceStatusEntity(
      enabled: locationServiceEnabled,
    );
  }

  @override
  Stream<Either<LocationServiceStatusFailure, LocationServiceStatusEntity>>
      get locationServiceStatusStream => transformData<
              LocationServiceStatusFailure,
              ServiceStatus,
              LocationServiceStatusEntity>(
            sourceStream: Geolocator.getServiceStatusStream,
            onData: (serviceStatus) => LocationServiceStatusEntity(
              enabled: serviceStatus == ServiceStatus.enabled,
            ),
            onError: LocationServiceStatusFailure.new,
          );

  @override
  Future<Either<LocationPermissionFailure, LocationPermissionEntity>>
      requestLocationPermission() async {
    final currentPermission = await Geolocator.checkPermission();

    if (currentPermission == LocationPermission.deniedForever ||
        currentPermission == LocationPermission.unableToDetermine) {
      return Left(
        LocationPermissionFailure(),
      );
    }

    if (currentPermission == LocationPermission.always ||
        currentPermission == LocationPermission.whileInUse) {
      return const Right(
        LocationPermissionEntity(
          granted: true,
        ),
      );
    }

    final permissionResult = await Geolocator.requestPermission();

    return switch (permissionResult) {
      LocationPermission.always || LocationPermission.whileInUse => const Right(
          LocationPermissionEntity(
            granted: true,
          ),
        ),
      LocationPermission.denied => const Right(
          LocationPermissionEntity(
            granted: false,
          ),
        ),
      _ => Left(
          LocationPermissionFailure(),
        ),
    };
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
