import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final res = await http.get(Uri.parse('https://assets.deadlock-api.com/v2/items'));
  final List data = jsonDecode(res.body);
  print('Items: ${data.length}');
  if (data.isNotEmpty) {
    print('Item keys: ${data[0].keys}');
    print('Item: ${data[0]}');
    
    // Find an item with ID 1001 or print the first few
    for (var i = 0; i < 3; i++) {
      print('Item $i: ${data[i]['id']} - ${data[i]['name']} - ${data[i]['images']?['icon_image_small']}');
    }
  }
}
