import 'dart:convert';

import 'package:amap_base/amap_base.dart';

class RideRouteResult {
  List<RidePath> paths;
  LatLng startPos;
  LatLng targetPos;

  RideRouteResult({
    this.paths,
    this.startPos,
    this.targetPos,
  });

  RideRouteResult.fromJson(Map<String, dynamic> json) {
    if (json['paths'] != null) {
      paths = List<RidePath>();
      json['paths'].forEach((v) {
        paths.add(RidePath.fromJson(v as Map<String, dynamic>));
      });
    }
    startPos =
    json['startPos'] != null ? LatLng.fromJson(json['startPos']) : null;
    targetPos =
    json['targetPos'] != null ? LatLng.fromJson(json['targetPos']) : null;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (this.paths != null) {
      data['paths'] = this.paths.map((v) => v.toJson()).toList();
    }
    if (this.startPos != null) {
      data['startPos'] = this.startPos.toJson();
    }
    if (this.targetPos != null) {
      data['targetPos'] = this.targetPos.toJson();
    }
    return data;
  }

  RideRouteResult copyWith({
    List paths,
    LatLng startPos,
    LatLng targetPos,
    num taxiCost,
  }) {
    return RideRouteResult(
      paths: paths ?? this.paths,
      startPos: startPos ?? this.startPos,
      targetPos: targetPos ?? this.targetPos,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RideRouteResult &&
              runtimeType == other.runtimeType &&
              paths == other.paths &&
              startPos == other.startPos &&
              targetPos == other.targetPos;

  @override
  int get hashCode => paths.hashCode ^ startPos.hashCode ^ targetPos.hashCode;

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class RidePath {
  num restriction;
  List<RideSteps> steps;
  String strategy;
  num tollDistance;
  num tolls;
  num totalTrafficlights;

  RidePath({
    this.restriction,
    this.steps,
    this.strategy,
    this.tollDistance,
    this.tolls,
    this.totalTrafficlights,
  });

  RidePath.fromJson(Map<String, dynamic> json) {
    restriction = json['restriction'] as num;
    if (json['steps'] != null) {
      steps = List<RideSteps>();
      json['steps'].forEach((v) {
        steps.add(RideSteps.fromJson(v as Map<String, dynamic>));
      });
    }
    strategy = json['strategy'] as String;
    tollDistance = json['tollDistance'] as num;
    tolls = json['tolls'] as num;
    totalTrafficlights = json['totalTrafficlights'] as num;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['restriction'] = this.restriction;
    if (this.steps != null) {
      data['steps'] = this.steps.map((v) => v.toJson()).toList();
    }
    data['strategy'] = this.strategy;
    data['tollDistance'] = this.tollDistance;
    data['tolls'] = this.tolls;
    data['totalTrafficlights'] = this.totalTrafficlights;
    return data;
  }

  RidePath copyWith({
    int restriction,
    List steps,
    String strategy,
    num tollDistance,
    num tolls,
    int totalTrafficlights,
  }) {
    return RidePath(
      restriction: restriction ?? this.restriction,
      steps: steps ?? this.steps,
      strategy: strategy ?? this.strategy,
      tollDistance: tollDistance ?? this.tollDistance,
      tolls: tolls ?? this.tolls,
      totalTrafficlights: totalTrafficlights ?? this.totalTrafficlights,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RidePath &&
              runtimeType == other.runtimeType &&
              restriction == other.restriction &&
              steps == other.steps &&
              strategy == other.strategy &&
              tollDistance == other.tollDistance &&
              tolls == other.tolls &&
              totalTrafficlights == other.totalTrafficlights;

  @override
  int get hashCode =>
      restriction.hashCode ^
      steps.hashCode ^
      strategy.hashCode ^
      tollDistance.hashCode ^
      tolls.hashCode ^
      totalTrafficlights.hashCode;

  @override
  String toString() {
    return '''Paths{
		restriction: $restriction,
		steps: $steps,
		strategy: $strategy,
		tollDistance: $tollDistance,
		tolls: $tolls,
		totalTrafficlights: $totalTrafficlights}''';
  }
}

class RideSteps {
  String instruction;
  String orientation;
  String road;
  num distance;
  num duration;
  List<LatLng> polyline;
  String action;
  String assistantAction;

  RideSteps({
    this.action,
    this.assistantAction,
    this.distance,
    this.duration,
    this.instruction,
    this.orientation,
    this.polyline,
    this.road,
  });

  RideSteps.fromJson(Map<String, dynamic> json) {
    action = json['action'] as String;
    assistantAction = json['assistantAction'] as String;
    distance = json['distance'] as num;
    duration = json['duration'] as num;
    instruction = json['instruction'] as String;
    orientation = json['orientation'] as String;
    if (json['polyline'] != null) {
      polyline = List<LatLng>();
      json['polyline'].forEach((v) {
        polyline.add(LatLng.fromJson(v as Map<String, dynamic>));
      });
    }
    road = json['road'] as String;
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['action'] = this.action;
    data['assistantAction'] = this.assistantAction;
    data['distance'] = this.distance;
    data['duration'] = this.duration;
    data['instruction'] = this.instruction;
    data['orientation'] = this.orientation;
    if (this.polyline != null) {
      data['polyline'] = this.polyline.map((v) => v.toJson()).toList();
    }
    data['road'] = this.road;
    return data;
  }

  RideSteps copyWith({
    String action,
    String assistantAction,
    num distance,
    num duration,
    String instruction,
    String orientation,
    List polyline,
    String road,
  }) {
    return RideSteps(
      action: action ?? this.action,
      assistantAction: assistantAction ?? this.assistantAction,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      instruction: instruction ?? this.instruction,
      orientation: orientation ?? this.orientation,
      polyline: polyline ?? this.polyline,
      road: road ?? this.road,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RideSteps &&
              runtimeType == other.runtimeType &&
              action == other.action &&
              assistantAction == other.assistantAction &&
              distance == other.distance &&
              duration == other.duration &&
              instruction == other.instruction &&
              orientation == other.orientation &&
              polyline == other.polyline &&
              road == other.road;

  @override
  int get hashCode =>
      action.hashCode ^
      assistantAction.hashCode ^
      distance.hashCode ^
      duration.hashCode ^
      instruction.hashCode ^
      orientation.hashCode ^
      polyline.hashCode ^
      road.hashCode;

  @override
  String toString() {
    return 'RideSteps{instruction: $instruction, orientation: $orientation, road: $road, distance: $distance, duration: $duration, polyline: $polyline, action: $action, assistantAction: $assistantAction}';
  }
}
