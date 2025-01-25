import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import '../data/product.dart';
import '../utils/http_params.dart';
import '../utils/utils.dart';
import 'validator.dart';

class ProductController {
  static const imageDirectory = 'public/images/products/';

  static Future<Response> create(Request request) async {
    //1. Create object and load request body
    var httpParams = HttpParams();
    await httpParams.loadRequest(request);

    //2. Create validation rule
    var error = httpParams.validate(
      {
        'title': [RequiredRule(), StringRule()],
        'price': [RequiredRule(), DoubleRule()],
        'detail': [RequiredRule(), StringRule()],
        'images': [
          RequiredRule(isFile: true),
          FileRule(allowedMimeTypes: ['.png', '.jpeg', '.jpg', '.webp'])
        ]
      },
    );

    if (error.isNotEmpty) {
      return Response.ok(
        jsonEncode(error),
        headers: {'content-type': 'application/json'},
      );
    }

    //3. Read data from HttpParams
    //Write images data into file
    var imageName = '';
    if (httpParams.getFile('images') case HttpFile image) {
      imageName = image.generateFileName;
      File('$imageDirectory$imageName').writeAsBytesSync(await image.content);
    }

    var id = 1;

    if (products.lastOrNull case Map<String, dynamic> lastProduct) {
      id = (lastProduct['id'] ?? id) + 1;
    }

    //Create new products object
    var product = {
      'id': id,
      'title': httpParams.getString('title'),
      'price': httpParams.getDouble('price'),
      'detail': httpParams.getString('detail'),
      // '/product/image/$imageName' is a route address we define in server.dart
      //...get('/product/image/<fileName>', ProductController.productImage)
      'image':
          Utils.hostAddress(request, path: ['/products/images/$imageName']),
    };
    // Add products object to new data source
    products.add(product);

    // write to file
    var fp =
        File(p.join(Directory.current.path, 'bin', 'data', 'product.dart'));

    fp.writeAsStringSync(
        'List<Map<String, dynamic>> products = ${jsonEncode(products)};',
        mode: FileMode.write);

    return Response.ok(
      jsonEncode(product),
      headers: {'content-type': 'application/json'},
    );
  }

  static Response productImage(Request request, String fileName) {
    var file = File('$imageDirectory$fileName');
    if (!file.existsSync()) {
      return Response.ok('File not found');
    }

    var contentType = lookupMimeType(fileName) ??
        'images/${p.extension(fileName).replaceFirst('.', '')}';

    return Response.ok(
      file.readAsBytesSync(),
      headers: {'content-type': contentType},
    );
  }

  static Response getProductById(Request request, String id) {
    var product = products;

    for (var pro in product) {
      if (pro['id'].toString() == id) {
        return Response.ok(
          jsonEncode(pro),
          headers: {'content-type': 'application/json'},
        );
      }
    }

    return Response.badRequest(body: 'Product not found');
  }

  static Future<Response> updateProductById(Request request, String id) async {
    //1. Create object and load request body
    var httpParams = HttpParams();
    await httpParams.loadRequest(request);

    // final body = await request.readAsString();

    // 2. Create validation rule
    for (var pro in products) {
      if (pro.values.first.toString() == id) {
        var productIndex = products.indexOf(pro);

        var imageName = '';
        if (httpParams.getFile('images') case HttpFile image) {
          imageName = pro['image'];

          File(p.join(Directory.current.path,
                  '$imageDirectory${p.basename(imageName)}'))
              .writeAsBytesSync(await image.content, mode: FileMode.write);
        }

        // update data
        pro['title'] = httpParams.getString('title').isEmpty
            ? pro['title']
            : httpParams.getString('title');
        pro['price'] = httpParams.getDouble('price') == 0
            ? pro['price']
            : httpParams.getDouble('price');
        pro['detail'] = httpParams.getString('detail').isEmpty
            ? pro['detail']
            : httpParams.getString('detail');

        pro['image'] = imageName.isEmpty ? pro['image'] : imageName;

        // update data source
        products[productIndex] = pro.isNotEmpty ? pro : products[productIndex];

        // write to file
        var fp =
            File(p.join(Directory.current.path, 'bin', 'data', 'product.dart'));
        fp.writeAsStringSync(
            'List<Map<String, dynamic>> products = ${jsonEncode(products)};',
            mode: FileMode.write);

        if (httpParams.getString('title').isEmpty &&
            httpParams.getString('detail').isEmpty &&
            httpParams.getString('images').isEmpty &&
            httpParams.getDouble('price') == 0) {
          return Response.badRequest(body: 'Data is empty');
        } else {
          return Response.ok(
            'Update successfully!! \n${jsonEncode(pro)}',
            headers: {'content-type': 'application/json'},
          );
        }
      }
    }

    return Response.badRequest(body: 'Product not found');
  }

  static Response deleteProductById(Request req, String id) {
    for (var pro in products) {
      if (pro.values.first.toString() == id) {
        products.removeAt(products.indexOf(pro));

        // write to file
        var fp =
            File(p.join(Directory.current.path, 'bin', 'data', 'product.dart'));
        fp.writeAsStringSync(
            'List<Map<String, dynamic>> products = ${jsonEncode(products)};',
            mode: FileMode.write);

        return Response.ok(
          'Delete successfully!! \nProduct id: $id',
          headers: {'content-type': 'application/json'},
        );
      }
    }

    return Response.badRequest(body: 'Product not found');
  }
}
