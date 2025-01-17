import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import '../data/user.dart';
import '../models/user_models.dart';
import 'package:path/path.dart' as path;

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

    return Response.notFound('User not found');
  }

  static Future<Response> createUser(Request req) async {
    final Map<String, dynamic> body = jsonDecode(await req.readAsString());

    ////////////////////////////////////////////////////////////////
    if (body.isEmpty) {
      return Response.ok('Request body is empty');
    }

    // cast body to Map<String,Object>
    Map<String, Object> newUser = body.map(
      (key, value) => MapEntry(key, value as Object),
    );

    // Validate the data ////////////////////////////////////////////////////////
    if (!(newUser.containsKey('id') &&
        newUser.containsKey('firstName') &&
        newUser.containsKey('lastName') &&
        newUser.containsKey('email') &&
        newUser.containsKey('gender'))) {
      return Response.ok('Invalid data !');
    }

    // if (_validateEmail(newUser['email'].toString())) {
    //   return Response.ok('Invalid email format');
    // }

    if (!_validateGenders(newUser['gender'].toString())) {
      return Response.ok('Invalid gender format');
    }

    if (!_validateNames(newUser['firstName'].toString())) {
      return Response.ok('Invalid firstName format');
    }

    if (!_validateNames(newUser['lastName'].toString())) {
      return Response.ok('Invalid lastName format');
    }

    ////////////////////////////////////////////////////////////////////

    final pathFiles =
        path.join(Directory.current.path, "bin", "data", "user.dart");

    final fp = File(pathFiles);

    if (userDS.last.keys.first == newUser.keys.first) {
      return Response.ok("User already exists");
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
}
