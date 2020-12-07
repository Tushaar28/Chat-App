import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class Utils {
  static String getUsername(String email) {
    return "live:${email.split('@')[0]}";
  }

  static String getInitials(String name) {
    List<String> nameSplit = name.split(" ");
    String firstNameInitial = nameSplit[0][0];
    String lastNameInitial = nameSplit[1][0];
    return firstNameInitial + lastNameInitial;
  }

  static Future<File> pickImage({@required ImageSource source}) async {
    PickedFile file = await ImagePicker().getImage(
      source: source,
      maxHeight: 500,
      maxWidth: 500,
      imageQuality: 85,
    );
    File selectedImage = File(file.path);
    return storeImage(selectedImage);
  }

  static Future<File> storeImage(File selectedImage) async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    print(path);
    int random = Random().nextInt(10000);
    File saved = new File('$path/img_$random.jpg');
    print(saved);
    return saved;
  }
}
