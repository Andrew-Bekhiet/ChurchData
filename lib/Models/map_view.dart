import 'package:churchdata/utils/globals.dart';
import 'package:churchdata/utils/helpers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:tuple/tuple.dart';

import 'area.dart';
import 'family.dart';
import 'street.dart';

class MapView extends StatelessWidget {
  final bool editMode;

  final LatLng? initialLocation;
  final int childrenDepth;

  final Area? area;
  final Street? street;
  final Family? family;

  const MapView({
    Key? key,
    required this.editMode,
    this.initialLocation,
    this.area,
    this.street,
    this.family,
    this.childrenDepth = 0,
  })  : assert(area != null || street != null || family != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
      future: Location.instance.requestPermission(),
      builder: (context, data) {
        if (data.hasData) {
          if (area != null) {
            return _AreaMap(
                area: area!,
                childrenDepth: childrenDepth,
                editMode: editMode,
                initialLocation: initialLocation);
          } else if (street != null) {
            return _StreetMap(
                street: street!,
                childrenDepth: childrenDepth,
                editMode: editMode,
                initialLocation: initialLocation);
          } else if (family != null) {
            return _FamilyMap(
                family: family!,
                editMode: editMode,
                initialLocation: initialLocation);
          }
          return Center(child: Text('خطأ غير معروف'));
        }
        return Center(child: const CircularProgressIndicator());
      },
    );
  }
}

class _StreetMap extends StatelessWidget {
  const _StreetMap({
    Key? key,
    required this.street,
    required this.childrenDepth,
    required this.editMode,
    this.initialLocation,
  }) : super(key: key);

  final Street street;
  final int childrenDepth;
  final bool editMode;
  final LatLng? initialLocation;

  @override
  Widget build(BuildContext context) {
    LatLng center = LatLng(30.0444, 31.2357); //Cairo Location
    if (street.locationPoints.isNotEmpty) {
      center = LatLng(
          (street.locationPoints.first.latitude +
                  street.locationPoints.last.latitude) /
              2,
          (street.locationPoints.first.longitude +
                  street.locationPoints.last.longitude) /
              2);
    }
    return FutureBuilder<Tuple2<Area?, List<Family>>>(
      future: () async {
        return Tuple2<Area?, List<Family>>(
          street.areaId != null
              ? Area.fromDoc(await street.areaId!.get(dataSource))
              : null,
          childrenDepth >= 1 && street.id != ''
              ? await street.getChildren('Location')
              : [],
        );
      }(),
      builder: (context, data) {
        if (!data.hasData)
          return Center(
            child: CircularProgressIndicator(),
          );

        Area? area = data.data!.item1;
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
            polygons: (area?.locationPoints.length ?? 0) != 0 && !kIsWeb
                ? {
                    Polygon(
                      polygonId: PolygonId(area!.id),
                      strokeWidth: 1,
                      fillColor: area.color == Colors.transparent
                          ? Colors.white.withOpacity(0.2)
                          : area.color.withOpacity(0.2),
                      points: area.locationPoints.map(fromGeoPoint).toList()
                        ..add(
                          fromGeoPoint(area.locationPoints.first),
                        ),
                    )
                  }
                : {},
            polylines: street.locationPoints.isNotEmpty && !kIsWeb
                ? {
                    Polyline(
                      polylineId: PolylineId(street.id),
                      startCap: Cap.roundCap,
                      width: 5,
                      color: street.color == Colors.transparent
                          ? ((street.locationConfirmed)
                              ? Colors.black
                              : Colors.black.withOpacity(0.25))
                          : ((street.locationConfirmed)
                              ? street.color
                              : street.color.withOpacity(0.25)),
                      endCap: Cap.roundCap,
                      jointType: JointType.round,
                      points: street.locationPoints.map(fromGeoPoint).toList(),
                    )
                  }
                : {},
            markers: {
              for (final f in data.data!.item2)
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
                            onPressed: () => familyTap(f, context),
                          ),
                        ),
                      );
                    },
                    markerId: MarkerId(f.id),
                    infoWindow: InfoWindow(
                        title: f.name,
                        snippet: f.locationConfirmed ? null : 'غير مؤكد'),
                    position: fromGeoPoint(f.locationPoint!),
                  )
            },
            initialCameraPosition: CameraPosition(
              zoom: 16,
              target: initialLocation ?? center,
            ),
          ),
        );
      },
    );
  }
}

class _FamilyMap extends StatelessWidget {
  const _FamilyMap({
    Key? key,
    required this.family,
    required this.editMode,
    required this.initialLocation,
  }) : super(key: key);

  final Family family;
  final bool editMode;
  final LatLng? initialLocation;

  @override
  Widget build(BuildContext context) {
    LatLng center = LatLng(30.0444, 31.2357); //Cairo Location
    return FutureBuilder<Tuple2<Area?, Street?>>(
      future: () async {
        return Tuple2<Area?, Street?>(
            family.areaId != null
                ? Area.fromDoc(await family.areaId!.get(dataSource))
                : null,
            family.streetId != null
                ? Street.fromDoc(await family.streetId!.get(dataSource))
                : null);
      }(),
      builder: (context, data) {
        if (!data.hasData)
          return const Center(
            child: CircularProgressIndicator(),
          );

        Area? area = data.data!.item1;
        Street? street = data.data!.item2;
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
            polygons: (area?.locationPoints.length ?? 0) != 0 && !kIsWeb
                ? {
                    Polygon(
                      polygonId: PolygonId(area!.id),
                      strokeWidth: 1,
                      fillColor: area.color == Colors.transparent
                          ? Colors.white.withOpacity(0.2)
                          : area.color.withOpacity(0.2),
                      points: area.locationPoints.map(fromGeoPoint).toList()
                        ..add(
                          fromGeoPoint(area.locationPoints.first),
                        ),
                    )
                  }
                : {},
            polylines: (street?.locationPoints.length ?? 0) != 0 && !kIsWeb
                ? {
                    Polyline(
                      consumeTapEvents: true,
                      polylineId: PolylineId(street!.id),
                      startCap: Cap.roundCap,
                      width: 5,
                      onTap: () {
                        scaffoldMessenger.currentState!;
                        scaffoldMessenger.currentState!.showSnackBar(
                          SnackBar(
                            backgroundColor: street.color == Colors.transparent
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
                          ? ((street.locationConfirmed)
                              ? Colors.black
                              : Colors.black.withOpacity(0.25))
                          : ((street.locationConfirmed)
                              ? street.color
                              : street.color.withOpacity(0.25)),
                      endCap: Cap.roundCap,
                      jointType: JointType.round,
                      points: street.locationPoints.map(fromGeoPoint).toList(),
                    )
                  }
                : {},
            markers: family.locationPoint != null
                ? {
                    Marker(
                      markerId: MarkerId(family.id),
                      infoWindow: InfoWindow(
                          title: family.name,
                          snippet:
                              (family.locationConfirmed) ? null : 'غير مؤكد'),
                      position: fromGeoPoint(family.locationPoint!),
                    )
                  }
                : {},
            initialCameraPosition: CameraPosition(
              zoom: 16,
              target: family.locationPoint != null
                  ? fromGeoPoint(family.locationPoint!)
                  : (initialLocation ?? center),
            ),
          ),
        );
      },
    );
  }
}

class _AreaMap extends StatelessWidget {
  const _AreaMap({
    Key? key,
    required this.area,
    required this.childrenDepth,
    required this.editMode,
    required this.initialLocation,
  }) : super(key: key);

  final Area area;
  final int childrenDepth;
  final bool editMode;
  final LatLng? initialLocation;

  @override
  Widget build(BuildContext context) {
    LatLng center = LatLng(30.0444, 31.2357); //Cairo Location
    if (area.locationPoints.isNotEmpty) {
      double x1 = 0;
      double x2 = 0;
      double y1 = 0;
      double y2 = 0;
      var tmpList = area.locationPoints.sublist(0)
        ..sort(
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

    return FutureBuilder<Tuple2<List<Street>, List<Family>>>(
      future: () async {
        return Tuple2<List<Street>, List<Family>>(
          childrenDepth >= 1 && area.id != 'null'
              ? await area.getChildren('Location')
              : <Street>[],
          childrenDepth >= 2
              ? await area.getFamilyMembersList('Location')
              : <Family>[],
        );
      }(),
      builder: (context, data) {
        if (!data.hasData)
          return const Center(child: CircularProgressIndicator());

        return StatefulBuilder(
          builder: (context, setState) => GoogleMap(
            compassEnabled: true,
            mapToolbarEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: editMode
                ? (point) {
                    setState(() {
                      area.locationPoints.add(fromLatLng(point));
                    });
                  }
                : null,
            polygons: {
              if (area.locationPoints.isNotEmpty && !kIsWeb)
                Polygon(
                  polygonId: PolygonId(area.id),
                  strokeWidth: 1,
                  fillColor: area.color == Colors.transparent
                      ? Colors.white.withOpacity(0.2)
                      : area.color.withOpacity(0.2),
                  points: [
                    for (final p in area.locationPoints) fromGeoPoint(p),
                    if (area.locationPoints.isNotEmpty)
                      fromGeoPoint(area.locationPoints.first)
                  ],
                )
            },
            polylines: !kIsWeb
                ? {
                    for (final s in data.data!.item1)
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
                                  onPressed: () => streetTap(s, context),
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
              for (final f in data.data!.item2)
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
                            onPressed: () => familyTap(f, context),
                          ),
                        ),
                      );
                    },
                    markerId: MarkerId(f.id),
                    infoWindow: InfoWindow(
                        title: f.name,
                        snippet: (f.locationConfirmed) ? null : 'غير مؤكد'),
                    position: fromGeoPoint(f.locationPoint!),
                  ),
            },
            initialCameraPosition: CameraPosition(
              zoom: 16,
              target: initialLocation ?? center,
            ),
          ),
        );
      },
    );
  }
}
