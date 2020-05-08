import 'dart:developer';

import 'package:Moody/helpers/authed_request.dart';
import 'package:Moody/models/api_response_model.dart';
import 'package:Moody/models/error_response_model.dart';
import 'package:Moody/models/user_model.dart';
import 'package:Moody/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

class SearchService extends ChangeNotifier {
  AuthService authService;

  String searchTerm = '';
  List<UserModel> list = new List<UserModel>();

  bool loading = false;

  CancelToken cancelToken;

  SearchService();

  SearchService update(AuthService authService) {
    print(
        '[SearchService] updated! ${authService.user != null ? authService.user.userName : ''}');
    if (authService.user != null) this.reset();
    this.authService = authService;
    return this;
  }

  void reset() {
    searchTerm = '';
    list = new List<UserModel>();
    loading = false;
    cancelToken = null;
    notifyListeners();
  }

  Future<void> search(String query) async {
    if (query == '') {
      searchTerm = '';
      list.removeRange(0, list.length);
      notifyListeners();
      return;
    }

    Response<dynamic> res;

    searchTerm = query;
    this.loading = true;
    notifyListeners();

    if (cancelToken != null) {
      cancelToken.cancel();
    }

    cancelToken = new CancelToken();

    try {
      res = await AuthenticatedRequest(authService: authService)
          .request
          .get('/user/search?q=$query', cancelToken: cancelToken);
    } on DioError catch (e) {
      if (e.type == DioErrorType.RESPONSE) {
        res = e.response;
      } else {
        throw e;
      }
    }

    if (res.statusCode == 200) {
      list = WebApiSuccessResponse<List<UserModel>>.fromJson(res.data).data;
      this.loading = false;
      notifyListeners();
    } else {
      throw WebApiErrorResponse.fromJson(res.data);
    }
  }

  @override
  void dispose() {
    log('The search_service has been disposed');
    super.dispose();
  }
}
