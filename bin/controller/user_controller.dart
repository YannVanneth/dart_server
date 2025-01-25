import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';

import '../data/user.dart';

class UserController {
  UserController._();

  static getAllUsers(Request req) {
    return Response.ok(jsonEncode(userDS),
        headers: {'Content-Type': 'application/json'});
  }

  static getUserById(Request req, String id) {
    final userData = userDS;

    for (var user in userData) {
      if ((user['id'].toString()) == id) {
        return Response.ok(jsonEncode(user),
            headers: {'Content-Type': 'application/json'});
      }
    }

    return Response.notFound('User not found !');
  }

  static Future<Response> createUser(Request req) async {
    final body = await req.readAsString();

    if (body.isEmpty) {
      return Response.badRequest(body: 'Request body is empty!');
    }

    final newUser = await _toMapStringObject(jsonDecode(body));

    var validateState = await _validateRequest(newUser);

    if (validateState.statusCode != 200) {
      return validateState;
    }

    final pathFiles =
        path.join(Directory.current.path, "bin", "data", "user.dart");

    final fp = File(pathFiles);

    if (userDS.last.values.first == newUser.values.first) {
      return Response.badRequest(
          body: "User id : ${newUser.values.first} already exists");
    } else if (int.parse(userDS.last.values.first.toString()) + 1 !=
        newUser.values.first) {
      return Response.badRequest(
          body:
              "invalid id value ! the previous id = ${userDS.last.values.first} and the id should be = ${int.parse(userDS.last.values.first.toString()) + 1}");
    } else {
      userDS.add(newUser);
      final newContent = jsonEncode(userDS);

      await fp.writeAsString("var userDS = $newContent;", mode: FileMode.write);
      return Response.ok('created successfully');
    }
  }

  static bool _validateEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  static bool _validateGenders(String gender) {
    final genderRegex = RegExp(r'^(male|female)$');
    return genderRegex.hasMatch(gender);
  }

  static bool _validateNames(String name) {
    final nameRegex = RegExp(r'^[a-zA-Z]+$');
    return nameRegex.hasMatch(name);
  }

  static Future<Response> _validateRequest(Map<String, dynamic> newUser) async {
    var keyField = ['id', 'firstName', 'lastName', 'email', 'gender'];
    if (!(keyField.every(
      (key) => newUser.containsKey(key),
    ))) {
      return Response.badRequest(
          body: 'Invalid ! the missing key are required !');
    }

    if (!_validateEmail(newUser['email'].toString())) {
      return Response.badRequest(body: 'Invalid email format');
    }

    if (!_validateGenders(newUser['gender'].toString())) {
      return Response.badRequest(body: 'Invalid gender format');
    }

    if (!_validateNames(newUser['firstName'].toString())) {
      return Response.badRequest(body: 'Invalid firstName format');
    }

    if (!_validateNames(newUser['lastName'].toString())) {
      return Response.badRequest(body: 'Invalid lastName format');
    }

    return Response.ok('OK');
  }

  static Future<Map<String, Object>> _toMapStringObject(
      Map<dynamic, dynamic> json) async {
    return json.map(
      (key, value) => MapEntry(key as String, value as Object),
    );
  }

  static uploadUserProfile(Request req) async {
    var params = <String, dynamic>{};
    var form = req.formData();

    if (form != null) {
      var data = await form.formData.toList();

      for (var item in data) {
        if (item.filename != null) {
          params[item.name] = {
            'file_name': item.filename,
            'data': await item.part.readBytes()
          };

          print(item.filename);
        } else {
          params[item.name] = await item.part.readString();
        }
      }
    }

    var image = params['images'];
    File('public/images/${image['file_name']}').writeAsBytesSync(image['data']);

    return Response.ok("uploadUserProfile",
        headers: {'content-type': "application/json"});
  }

  static userProfileImage(Request req, String filename) async {
    return Response.ok(await File("public/images/${filename}").readAsBytes(),
        headers: {"content-type": "images/png"});
  }
}
