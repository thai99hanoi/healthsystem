import 'dart:convert';
import 'dart:io';

import 'package:heath_care/application.dart';
import 'package:heath_care/model/user.dart';
import 'package:heath_care/networks/api_base_helper.dart';
import 'package:heath_care/networks/auth.dart';
import 'package:heath_care/utils/api.dart';
import 'package:heath_care/utils/app_exceptions.dart';
import 'package:http/http.dart' as http;

class UserRepository {
  ApiBaseHelper apiBaseHelper = ApiBaseHelper();

  Future<User> getCurrentUser() async {
    User? userTmp = getCurrentUserTmp();
    if (userTmp != null){
      return userTmp;
    }
    else {
      Map<String, dynamic> response =
          await apiBaseHelper.get("/v1/api/current-user");
      var entriesList = response.entries.toList();
      User _currentUser =  User.fromJson(entriesList[1].value);
      setCurrentUser(_currentUser);
      return _currentUser;
    }
  }

  Future<List<User>?> getUserOnline() async {
    var user = await UserRepository().getCurrentUser();
    String token = await Auth().getToken();
    var userId = user.userId;
    print('Api Get, url /v1/api/users-online?userId="' + userId.toString());
    var responseJson;
    try {
      final response = await http.get(
        Uri.parse(
            Api.authUrl + "/v1/api/users-online?userId=" + userId.toString()),
        headers: {
          "content-type": "application/json",
          'Authorization': 'Bearer $token',
        },
      );
      responseJson = jsonDecode(response.body);
      print('api get user online recieved! ${responseJson}');
      return (responseJson['data'] as List)
          .map((user) => User.fromJson(user))
          .toList();
    } on SocketException {
      print('No net');
      throw FetchDataException('No Internet connection');
    }
  }

  List<User>? parseUser(String responseBody) {
    final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<User>((json) => User.fromJson(json)).toList();
  }
}
