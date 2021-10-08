import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ItemNetworkImage extends StatefulWidget {
  String? image;

  ItemNetworkImage({this.image});

  @override
  State<StatefulWidget> createState() {
    return _StateItemNetworkImage(image: image);
  }
}

class _StateItemNetworkImage extends State<ItemNetworkImage> {
  String? image;

  _StateItemNetworkImage({this.image});

  bool _isError = false;

  @override
  Widget build(BuildContext context) {
    ImageProvider imageAvatar;
    if (image != null && !_isError) {
      imageAvatar = NetworkImage(image!);
    } else {
      imageAvatar = AssetImage('assets/images/img_1.png');
    }
    return CircleAvatar(
      radius: 24,
      backgroundImage: imageAvatar,
      onBackgroundImageError: (_, __){
           setState(() {
             _isError = true;
           });
      },
    );
  }
}
