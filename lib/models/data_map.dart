import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:tuple/tuple.dart';

import 'area.dart';
import 'family.dart';
import 'street.dart';

class DataMap extends StatelessWidget {
  const DataMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة الافتقاد'),
      ),
      body: FutureBuilder<PermissionStatus>(
        future: Location.instance.requestPermission(),
        builder: (context, data) {
          if (data.hasData && data.data == PermissionStatus.granted)
            return FutureBuilder<LocationData>(
              future: Location.instance.getLocation(),
              builder: (context, snapshot) => snapshot.hasData
                  ? MegaMap(
                      initialLocation: LatLng(
                        snapshot.data!.latitude!,
                        snapshot.data!.longitude!,
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(),
                    ),
            );
          else if (data.hasData) return const MegaMap();
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

class MegaMap extends StatelessWidget {
  static const LatLng center = LatLng(30.0444, 31.2357); //Cairo Location
  final LatLng? initialLocation;

  const MegaMap({super.key, this.initialLocation});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Tuple3<List<Area>, List<Street>, List<Family>>>(
      future: () async {
        return Tuple3<List<Area>, List<Street>, List<Family>>(
          await Area.getAllAreasForUser(orderBy: 'Location'),
          await Street.getAllStreetsForUser(orderBy: 'Location'),
          await Family.getAllFamiliesForUser(orderBy: 'Location'),
        );
      }(),
      builder: (context, data) {
        if (!data.hasData)
          return const Center(
            child: CircularProgressIndicator(),
          );

        final List<Area> areas = data.data!.item1;
        final List<Street> streets = data.data!.item2;
        final List<Family> families = data.data!.item3;

        return StatefulBuilder(
          builder: (context, setState) => GoogleMap(
            myLocationEnabled: true,
            polygons: !kIsWeb
                ? {
                    for (final area in areas)
                      if (area.locationPoints.isNotEmpty)
                        Polygon(
                          polygonId: PolygonId(area.id),
                          strokeWidth: 1,
                          fillColor: area.color == Colors.transparent
                              ? Colors.white.withOpacity(0.2)
                              : area.color.withOpacity(0.2),
                          points: area.locationPoints.isNotEmpty
                              ? [
                                  for (final i in area.locationPoints)
                                    fromGeoPoint(i),
                                  fromGeoPoint(area.locationPoints.first),
                                ]
                              : [],
                        ),
                  }
                : {},
            polylines: !kIsWeb
                ? {
                    for (final s in streets)
                      if (s.locationPoints.isNotEmpty)
                        Polyline(
                          consumeTapEvents: true,
                          polylineId: PolylineId(s.id),
                          startCap: Cap.roundCap,
                          width: 4,
                          onTap: () {
                            scaffoldMessenger.currentState!
                                .hideCurrentSnackBar();
                            scaffoldMessenger.currentState!.showSnackBar(
                              SnackBar(
                                backgroundColor: s.color == Colors.transparent
                                    ? null
                                    : s.color,
                                content: Text(s.name),
                                action: SnackBarAction(
                                  label: 'فتح',
                                  onPressed: () => streetTap(s),
                                ),
                              ),
                            );
                          },
                          endCap: Cap.roundCap,
                          jointType: JointType.round,
                          color: s.color == Colors.transparent
                              ? ((s.locationConfirmed)
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.25))
                              : ((s.locationConfirmed)
                                  ? s.color
                                  : s.color.withOpacity(0.25)),
                          points: s.locationPoints.map(fromGeoPoint).toList(),
                        ),
                  }
                : {},
            markers: {
              for (final f in families)
                if (f.locationPoint != null)
                  Marker(
                    onTap: () {
                      scaffoldMessenger.currentState!.hideCurrentSnackBar();
                      scaffoldMessenger.currentState!.showSnackBar(
                        SnackBar(
                          content: Text(f.name),
                          backgroundColor:
                              f.color == Colors.transparent ? null : f.color,
                          action: SnackBarAction(
                            label: 'فتح',
                            onPressed: () => familyTap(f),
                          ),
                        ),
                      );
                    },
                    markerId: MarkerId(f.id),
                    infoWindow: InfoWindow(
                      title: f.name,
                      snippet: f.locationConfirmed ? null : 'غير مؤكد',
                    ),
                    position: fromGeoPoint(f.locationPoint!),
                  ),
            },
            initialCameraPosition: CameraPosition(
              zoom: 13,
              target: initialLocation ?? center,
            ),
          ),
        );
      },
    );
  }
}
