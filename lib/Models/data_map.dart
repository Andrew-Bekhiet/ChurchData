import 'package:churchdata/utils/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'area.dart';
import 'family.dart';
import 'street.dart';

class DataMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('خريطة الافتقاد'),
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
                          snapshot.data.latitude, snapshot.data.longitude),
                    )
                  : Center(
                      child: CircularProgressIndicator(),
                    ),
            );
          else if (data.hasData) return MegaMap();
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}

class MegaMap extends StatelessWidget {
  final LatLng center = LatLng(30.0444, 31.2357); //Cairo Location
  final LatLng initialLocation;

  MegaMap({Key key, this.initialLocation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<dynamic>>>(
        future: Future.wait([
          Area.getAllAreasForUser(orderBy: 'Location'),
          Street.getAllStreetsForUser(orderBy: 'Location'),
          Family.getAllFamiliesForUser(orderBy: 'Location'),
        ]),
        builder: (context, data) {
          if (data.connectionState != ConnectionState.done)
            return Center(
              child: CircularProgressIndicator(),
            );

          List<Area> areas = data.data[0];
          List<Street> streets = data.data[1];
          List<Family> families = data.data[2];

          return StatefulBuilder(
            builder: (context, setState) => GoogleMap(
              compassEnabled: true,
              mapToolbarEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              polygons: !kIsWeb
                  ? areas
                      ?.where((a) =>
                          a.locationPoints != null &&
                          a.locationPoints.isNotEmpty)
                      ?.map(
                        (area) => Polygon(
                          polygonId: PolygonId(area.id),
                          strokeWidth: 1,
                          fillColor: area.color == Colors.transparent
                              ? Colors.white.withOpacity(0.2)
                              : area.color.withOpacity(0.2),
                          points: area.locationPoints
                              .map(
                                (e) => fromGeoPoint(e),
                              )
                              .toList()
                                ..add(
                                  fromGeoPoint(area.locationPoints.first),
                                ),
                        ),
                      )
                      ?.toSet()
                  : {},
              polylines: !kIsWeb
                  ? streets
                      ?.where((s) => s.locationPoints != null)
                      ?.map((s) => Polyline(
                            consumeTapEvents: true,
                            polylineId: PolylineId(s.id),
                            startCap: Cap.roundCap,
                            width: 4,
                            onTap: () {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: s.color == Colors.transparent
                                      ? null
                                      : s.color,
                                  content: Text(s.name),
                                  action: SnackBarAction(
                                    label: 'فتح',
                                    onPressed: () => streetTap(s, context),
                                  ),
                                ),
                              );
                            },
                            endCap: Cap.roundCap,
                            jointType: JointType.round,
                            color: s.color == Colors.transparent
                                ? ((s.locationConfirmed ?? false)
                                    ? Colors.black
                                    : Colors.black.withOpacity(0.25))
                                : ((s.locationConfirmed ?? false)
                                    ? s.color
                                    : s.color.withOpacity(0.25)),
                            points: s.locationPoints
                                ?.map(
                                  (e) => fromGeoPoint(e),
                                )
                                ?.toList(),
                          ))
                      ?.toSet()
                  : {},
              markers: families
                      ?.where((f) => f.locationPoint != null)
                      ?.map((f) => Marker(
                            onTap: () {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(f.name),
                                  backgroundColor: f.color == Colors.transparent
                                      ? null
                                      : f.color,
                                  action: SnackBarAction(
                                    label: 'فتح',
                                    onPressed: () => familyTap(f, context),
                                  ),
                                ),
                              );
                            },
                            markerId: MarkerId(f.id),
                            infoWindow: InfoWindow(
                                title: f.name,
                                snippet: (f.locationConfirmed ?? false)
                                    ? null
                                    : 'غير مؤكد'),
                            position: fromGeoPoint(f.locationPoint),
                          ))
                      ?.toSet() ??
                  {},
              initialCameraPosition: CameraPosition(
                zoom: 13,
                target: initialLocation ?? center,
              ),
            ),
          );
        });
  }
}
