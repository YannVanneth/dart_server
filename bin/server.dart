import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_hotreload/shelf_hotreload.dart';
import 'package:shelf_router/shelf_router.dart';

import './controller/product_controller.dart';
import './controller/user_controller.dart';

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/users', _getUserHandler)
  ..get('/users/<id|[0-9]+>', _getUserByIdHandler)
  ..get('/userProfileImage/<images>', UserController.userProfileImage)
  ..post('/uploadPicture', _uploadImage)
  ..post('/createUser', _createUserHandler)
  ..put('/products/<id|[0-9]+>', ProductController.updateProductById)
  ..get('/products/images/<fileName>', ProductController.productImage)
  ..get('/products/<id|[0-9]+>', ProductController.getProductById)
  ..post('/products', ProductController.create)
  ..delete('/products/<id|[0-9]+>', ProductController.deleteProductById);

Response _rootHandler(Request req) {
  return Response.ok('home');
}

Future<Response> _uploadImage(Request req) async {
  return await UserController.uploadUserProfile(req);
}

Response _getUserHandler(Request req) {
  return UserController.getAllUsers(req);
}

Response _getUserByIdHandler(Request req, String id) {
  return UserController.getUserById(req, id);
}

Future<Response> _createUserHandler(Request req) async {
  return await UserController.createUser(req);
}

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  withHotreload(
    () => serve(handler, ip, port),
  );
}
