import 'package:churchdata/utils/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'area.dart';
import 'family.dart';
import 'street.dart';

class MapView extends StatelessWidget {
  final bool editMode;

  final LatLng initialLocation;
  final int childrenDepth;

  final Area area;
  final Street street;
  final Family family;

  MapView({
    Key key,
    this.editMode,
    this.initialLocation,
    this.area,
    this.street,
    this.family,
    this.childrenDepth = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
      future: Location.instance.requestPermission(),
      builder: (context, data) {
        if (data.hasData) {
          if (area != null) {
            return buildAreaMap();
          } else if (street != null) {
            return buildStreetMap();
          } else if (family != null) {
            return buildFamilyMap();
          }
          return Center(child: Text('خطأ غير معروف'));
        }
        return Center(child: const CircularProgressIndicator());
      },
    );
  }

  Widget buildAreaMap() {
    LatLng center = LatLng(30.0444, 31.2357); //Cairo Location
    area.locationPoints ??= [];
    if (area.locationPoints.isNotEmpty) {
      double x1 = 0;
      double x2 = 0;
      double y1 = 0;
      double y2 = 0;
      var tmpList = area.locationPoints.sublist(0);
      tmpList.sort(
        (pnt1, pnt2) => pnt1.latitude.compareTo(pnt2.latitude),
      );
      x1 = tmpList.first.latitude;
      x2 = tmpList.last.latitude;
      tmpList.sort(
        (pnt1, pnt2) => pnt1.longitude.compareTo(pnt2.longitude),
      );
      y1 = tmpList.first.longitude;
      y2 = tmpList.last.longitude;
      center = LatLng(
        x1 + ((x2 - x1) / 2),
        y1 + ((y2 - y1) / 2),
      );
    }

    return FutureBuilder<List<Street>>(
      future: childrenDepth >= 1 && area.id != ''
          ? area.getChildren('Location')
          : Future(() => null),
      builder: (context, streets) {
        return FutureBuilder<List<Family>>(
          future: childrenDepth >= 2 && streets.hasData
              ? area.getFamilyMembersList('Location')
              : Future(() => null),
          builder: (context, families) {
            return StatefulBuilder(
              builder: (context, setState) => GoogleMap(
                compassEnabled: true,
                mapToolbarEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onTap: editMode
                    ? (point) {
                        setState(() {
                          area.locationPoints.add(
                            fromLatLng(point),
                          );
                        });
                      }
                    : null,
                polygons: {
                  if ((area?.locationPoints?.length ?? 0) != 0 && !kIsWeb)
                    Polygon(
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
                    )
                },
                polylines: !kIsWeb
                    ? streets.data
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
                                        backgroundColor:
                                            s.color == Colors.transparent
                                                ? null
                                                : s.color,
                                        content: Text(s.name),
                                        action: SnackBarAction(
                                          label: 'فتح',
                                          onPressed: () =>
                                              streetTap(s, context),
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
                            ?.toSet() ??
                        {}
                    : {},
                markers: families.hasData && families.data.isNotEmpty
                    ? families.data
                            ?.where((f) => f.locationPoint != null)
                            ?.map((f) => Marker(
                                  onTap: () {
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(f.name),
                                        backgroundColor:
                                            f.color == Colors.transparent
                                                ? null
                                                : f.color,
                                        action: SnackBarAction(
                                          label: 'فتح',
                                          onPressed: () =>
                                              familyTap(f, context),
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
                        {}
                    : {},
                initialCameraPosition: CameraPosition(
                  zoom: 16,
                  target: initialLocation ?? center,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildFamilyMap() {
    LatLng center = LatLng(30.0444, 31.2357); //Cairo Location
    return FutureBuilder<Area>(
      future: family.areaId?.get()?.then((a) => Area.fromDoc(a)) ??
          Future(() => Area.empty()),
      builder: (context, areaData) {
        return FutureBuilder<Street>(
          future: family.streetId?.get()?.then((s) => Street.fromDoc(s)) ??
              Future(() => Street.empty()),
          builder: (context, streetData) {
            if (!areaData.hasData || !streetData.hasData)
              return Center(
                child: CircularProgressIndicator(),
              );
            Area area = areaData.data;
            Street street = streetData.data;
            return StatefulBuilder(
              builder: (context, setState) => GoogleMap(
                compassEnabled: true,
                mapToolbarEnabled: true,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onTap: editMode
                    ? (point) {
                        setState(() {
                          family.locationPoint = fromLatLng(point);
                        });
                      }
                    : null,
                polygons: (area?.locationPoints?.length ?? 0) != 0 && !kIsWeb
                    ? {
                        Polygon(
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
                        )
                      }
                    : {},
                polylines: (street?.locationPoints?.length ?? 0) != 0 && !kIsWeb
                    ? {
                        Polyline(
                          consumeTapEvents: true,
                          polylineId: PolylineId(street.id),
                          startCap: Cap.roundCap,
                          width: 5,
                          onTap: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor:
                                    street.color == Colors.transparent
                                        ? null
                                        : street.color,
                                content: Text(street.name),
                                action: SnackBarAction(
                                  label: 'فتح',
                                  onPressed: () => streetTap(street, context),
                                ),
                              ),
                            );
                          },
                          color: street.color == Colors.transparent
                              ? ((street.locationConfirmed ?? false)
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.25))
                              : ((street.locationConfirmed ?? false)
                                  ? street.color
                                  : street.color.withOpacity(0.25)),
                          endCap: Cap.roundCap,
                          jointType: JointType.round,
                          points: street.locationPoints
                              .map(
                                (e) => fromGeoPoint(e),
                              )
                              .toList(),
                        )
                      }
                    : {},
                markers: family.locationPoint != null
                    ? {
                        Marker(
                          markerId: MarkerId(family.id),
                          infoWindow: InfoWindow(
                              title: family.name,
                              snippet: (family.locationConfirmed ?? false)
                                  ? null
                                  : 'غير مؤكد'),
                          position: fromGeoPoint(family.locationPoint),
                        )
                      }
                    : {},
                initialCameraPosition: CameraPosition(
                  zoom: 16,
                  target: family.locationPoint != null
                      ? fromGeoPoint(family.locationPoint)
                      : (initialLocation ?? center),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildStreetMap() {
    LatLng center = LatLng(30.0444, 31.2357); //Cairo Location
    street.locationPoints ??= [];
    if (street.locationPoints.isNotEmpty) {
      center = LatLng(
          (street.locationPoints.first.latitude +
                  street.locationPoints.last.latitude) /
              2,
          (street.locationPoints.first.longitude +
                  street.locationPoints.last.longitude) /
              2);
    }
    return FutureBuilder<Area>(
      future: street.areaId?.get()?.then((a) => Area.fromDoc(a)) ??
          Future(() => Area.empty()),
      builder: (context, areaData) => FutureBuilder<List<Family>>(
        future: childrenDepth >= 1 && street.id != ''
            ? street.getChildren('Location')
            : Future(() => null),
        builder: (context, families) {
          if (!areaData.hasData)
            return Center(
              child: CircularProgressIndicator(),
            );
          Area area = areaData.data;
          return StatefulBuilder(
            builder: (context, setState) => GoogleMap(
              compassEnabled: true,
              mapToolbarEnabled: true,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: editMode
                  ? (point) {
                      setState(() {
                        street.locationPoints.add(
                          fromLatLng(point),
                        );
                      });
                    }
                  : null,
              polygons: (area?.locationPoints?.length ?? 0) != 0 && !kIsWeb
                  ? {
                      Polygon(
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
                      )
                    }
                  : {},
              polylines: (street.locationPoints?.length ?? 0) != 0 && !kIsWeb
                  ? {
                      Polyline(
                        polylineId: PolylineId(street.id),
                        startCap: Cap.roundCap,
                        width: 5,
                        color: street.color == Colors.transparent
                            ? ((street.locationConfirmed ?? false)
                                ? Colors.black
                                : Colors.black.withOpacity(0.25))
                            : ((street.locationConfirmed ?? false)
                                ? street.color
                                : street.color.withOpacity(0.25)),
                        endCap: Cap.roundCap,
                        jointType: JointType.round,
                        points: street.locationPoints
                            .map(
                              (e) => fromGeoPoint(e),
                            )
                            .toList(),
                      )
                    }
                  : {},
              markers: families.data
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
                zoom: 16,
                target: initialLocation ?? center,
              ),
            ),
          );
        },
      ),
    );
  }
}
