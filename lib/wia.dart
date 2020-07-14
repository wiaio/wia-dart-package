import 'dart:async';
import 'dart:convert' as convert;

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:wia_dart_package/src/resources/kiosk_api_keys.dart';
import 'package:wia_dart_package/src/resources/occupancy.dart';

import './src/resources/access_token.dart';
import './src/resources/device.dart';
import './src/resources/event.dart';
import './src/resources/exceptions.dart';
import './src/resources/kiosk.dart';
import './src/resources/organisation.dart';
import './src/resources/space.dart';
import './src/resources/ui_widget.dart';
import './src/resources/user.dart';
import './src/resources/workplace.dart';

export './src/resources/access_token.dart';
export './src/resources/avatar.dart';
export './src/resources/device.dart';
export './src/resources/event.dart';
export './src/resources/exceptions.dart';
export './src/resources/kiosk.dart';
export './src/resources/kiosk_api_keys.dart';
export './src/resources/occupancy.dart';
export './src/resources/organisation.dart';
export './src/resources/space.dart';
export './src/resources/ui_widget.dart';
export './src/resources/user.dart';
export './src/resources/workplace.dart';

class Wia {
  final _baseUri = "https://api.wia.io/v1";
  String _clientKey = null;
  String _accessToken = null;
  String _secretKey = null; // for use with kiosks

  Wia(
      {@required String clientKey,
      String accessToken = null,
      String secretKey}) {
    _clientKey = clientKey;
    _accessToken = accessToken;
    _secretKey = secretKey;
  }

  Map<String, String> getClientHeaders() {
    var map = {'x-client-key': _clientKey};
    if (_clientKey != null) {
      map['x-client-key'] = _clientKey;
    }
    if (_accessToken != null) {
      map['Authorization'] = 'Bearer ' + _accessToken;
    } else if (_secretKey != null) {
      map['Authorization'] = 'Bearer ' + _secretKey;
    }
    return map;
  }

  Future<AccessToken> login(String username, String password) async {
    var response;

    response = await http.post(_baseUri + "/auth/token",
        body: {
          'username': username,
          'password': password,
          'scope': 'user',
          'grantType': 'password'
        },
        headers: getClientHeaders());

    if (response.statusCode == 200) {
      clearSecretKey();
      var jsonResponse = convert.jsonDecode(response.body);
      var accessToken = AccessToken.fromJson(jsonResponse);
      _accessToken = accessToken.token;
      return accessToken;
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  void logout() async {
    _accessToken = null;
  }

  void clearSecretKey() async {
    _secretKey = null;
  }

  Future<User> retrieveUserMe() async {
    var response =
        await http.get(_baseUri + "/users/me", headers: getClientHeaders());

    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var user = User.fromJson(jsonResponse);
      return user;
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<List<Space>> listSpaces({int limit = 80}) async {
    var queryString = "limit=" + limit.toString();

    var response = await http.get(_baseUri + "/spaces?" + queryString,
        headers: getClientHeaders());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = convert.jsonDecode(response.body);
      List<dynamic> spacesData = jsonResponse["spaces"];
      return spacesData.map((spaceJson) => Space.fromJson(spaceJson)).toList();
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<Space> retrieveSpace(String id) async {
    var response =
        await http.get(_baseUri + "/spaces/" + id, headers: getClientHeaders());

    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var space = Space.fromJson(jsonResponse);
      return space;
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<List<Device>> listDevices(
      {String spaceId, int limit = 40, int page = 1}) async {
    var queryParams = "/devices?space.id=$spaceId&limit=$limit";
    var response =
        await http.get(_baseUri + queryParams, headers: getClientHeaders());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = convert.jsonDecode(response.body);
      List<dynamic> devicesData = jsonResponse["devices"];
      return devicesData
          .map((deviceJson) => Device.fromJson(deviceJson))
          .toList();
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<Device> retrieveDevice(String id) async {
    var url = _baseUri + "/devices/" + id;
    if (_secretKey != null) url = "$url/kiosk";

    var response = await http.get(url, headers: getClientHeaders());

    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var device = Device.fromJson(jsonResponse);
      return device;
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<List<Organisation>> listOrganisations({int limit = 80}) async {
    var queryString = "limit=" + limit.toString();

    var response = await http.get(_baseUri + "/organisations?" + queryString,
        headers: getClientHeaders());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = convert.jsonDecode(response.body);

      List<dynamic> organisationsData = jsonResponse["organisations"];
      return organisationsData
          .map((organisationJson) => Organisation.fromJson(organisationJson))
          .toList();
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<List<UIWidget>> listUIWidgets({String deviceId, kioskId}) async {
    var queryString;

    if (deviceId != null)
      queryString = "device.id=$deviceId";
    else if (kioskId != null)
      queryString = "kiosk.id=$kioskId";
    else
      throw Exception("Either deviceId or kioskId must be supplied.");

    var response = await http.get(_baseUri + "/widgets?" + queryString,
        headers: getClientHeaders());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = convert.jsonDecode(response.body);

      List<dynamic> widgetsData = jsonResponse["widgets"];
      return widgetsData
          .map((widgetJson) => UIWidget.fromJson(widgetJson))
          .toList();
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<List<Event>> listEvents(
      {String deviceId = null, String name = null}) async {
    var queryString = "?device.id=" + deviceId;

    if (name != null) {
      queryString += "&name=" + name;
    }

    var response = await http.get(_baseUri + "/events" + queryString,
        headers: getClientHeaders());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = convert.jsonDecode(response.body);

      List<dynamic> eventsData = jsonResponse["events"];
      return eventsData.map((eventJson) => Event.fromJson(eventJson)).toList();
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<List<Event>> queryEvents(String deviceId, String name, int since,
      {int until,
      String aggregateFunction,
      String resolution,
      String sort,
      int limit = 40,
      int page}) async {
    var queryString = "?device.id=$deviceId&name=$name&since=$since";

    if (until != null) queryString += "&until=$until";
    if (aggregateFunction != null)
      queryString += "&aggregateFunction=$aggregateFunction";
    if (resolution != null) queryString += "&resolution=$resolution";
    if (limit != null) queryString += "&limit=$limit";
    if (page != null) queryString += "&page=$page";

    var response = await http.get(_baseUri + "/events" + queryString,
        headers: getClientHeaders());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = convert.jsonDecode(response.body);

      List<dynamic> eventsData = jsonResponse["events"];
      return eventsData != null
          ? eventsData.map((eventJson) => Event.fromJson(eventJson)).toList()
          : [];
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<List<Workplace>> listWorkplaces(
      {String spaceId, int limit = 40, int page = 1}) async {
    var response = await http.get(_baseUri + "/workplaces?space.id=" + spaceId,
        headers: getClientHeaders());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = convert.jsonDecode(response.body);
      List<dynamic> workplacesData = jsonResponse["workplaces"];
      return workplacesData
          .map((workplaceJson) => Workplace.fromJson(workplaceJson))
          .toList();
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<Workplace> retrieveWorkplace(String id) async {
    var url = _baseUri + "/workplaces/" + id;
    if (_secretKey != null) url = "$url/kiosk";

    var response = await http.get(url, headers: getClientHeaders());

    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var workplace = Workplace.fromJson(jsonResponse);
      return workplace;
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<List<Kiosk>> listKiosks(String spaceId,
      {int limit = 40, int page = 1}) async {
    var response = await http.get(_baseUri + "/kiosks?space.id=" + spaceId,
        headers: getClientHeaders());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = convert.jsonDecode(response.body);
      List<dynamic> kiosksData = jsonResponse["kiosks"];
      return kiosksData.map((kioskJson) => Kiosk.fromJson(kioskJson)).toList();
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<Kiosk> retrieveKiosk(String id) async {
    var response =
        await http.get(_baseUri + "/kiosks/" + id, headers: getClientHeaders());

    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var kiosk = Kiosk.fromJson(jsonResponse);
      return kiosk;
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<List<Occupancy>> getLiveOccupancy(
      {String spaceId, workplaceId}) async {
    var queryString;

    if (spaceId != null)
      queryString = "space.id=$spaceId";
    else if (workplaceId != null)
      queryString = "workplace.id=$workplaceId";
    else
      throw Exception("Either spaceId or workplaceId must be supplied.");

    var url = _baseUri + "/utilisation/occupancy/live";
    if (_secretKey != null) url = "$url/kiosk";
    if (queryString != null) url = "$url?$queryString";

    var response = await http.get(url, headers: getClientHeaders());

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = convert.jsonDecode(response.body);

      List<dynamic> occupancyData = jsonResponse["results"];
      return occupancyData
          .map((occupancyJson) => Occupancy.fromJson(occupancyJson))
          .toList();
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<Kiosk> retrieveKiosksMe() async {
    var response =
        await http.get("$_baseUri/kiosks/me", headers: getClientHeaders());

    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var kiosk = Kiosk.fromJson(jsonResponse);
      return kiosk;
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }

  Future<KioskApiKeys> retrieveKioskApiKeys(String id) async {
    var response = await http.get("$_baseUri/kiosks/$id/apiKeys",
        headers: getClientHeaders());

    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      var kioskApiKeys = KioskApiKeys.fromJson(jsonResponse);
      return kioskApiKeys;
    } else {
      var jsonResponse = convert.jsonDecode(response.body);
      throw new WiaHttpException(response.statusCode, jsonResponse["message"]);
    }
  }
}
