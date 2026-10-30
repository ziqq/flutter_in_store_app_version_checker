/*
 * Author: Anton Ustinoff <https://github.com/ziqq> | <a.a.ustinoff@gmail.com>
 * Date: 22 September 2026
 */

import 'dart:convert';
import 'dart:math';

import 'package:flutter_in_store_app_version_checker/src/store/store_interface.dart';
import 'package:flutter_in_store_app_version_checker/src/store/store_request.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

/// Reads public AppGallery listing data through the AppGallery web client API.
@internal
final class Store$AppGalleryWeb implements IStore {
  /// Creates an AppGallery web store client.
  const Store$AppGalleryWeb(this._httpClient);

  static const _host = 'web-dre.hispace.dbankcloud.com';
  static const _timeout = Duration(seconds: 15);
  static final _storeIDPattern = RegExp(r'^C\d+$');

  final http.Client _httpClient;

  @override
  String get name => 'AppGallery';

  /// Reads an arbitrary AppGallery listing identified by `storeID`.
  @override
  Future<({String? version, String? appURL})> fetchListing(
    StoreRequest request,
  ) async {
    final storeID = switch (request.storeID?.trim()) {
      String storeID when _storeIDPattern.hasMatch(storeID) => storeID,
      _ => throw FormatException(
        'AppGallery web checks require storeID in the format "C107631977".',
        request.storeID,
      ),
    };
    final listing = await _getListing(
      uri: 'app|$storeID',
      lookup: 'store ID "$storeID"',
      subject: 'listing "$storeID"',
      locale: request.locale,
      matches: (listing) => listing['appid']?.toString() == storeID,
    );
    final packageName = listing.packageName;
    if (request.expectedPackageName case String expectedPackageName
        when packageName != expectedPackageName) {
      throw StateError(
        'AppGallery listing "$storeID" belongs to package '
        '"$packageName", not "$expectedPackageName".',
      );
    }
    return (version: listing.version, appURL: _buildAppURL(storeID));
  }

  /// Reads the AppGallery listing of the package in [request].
  Future<({String? version, String? appURL})> fetchListingByPackageName(
    StoreRequest request,
  ) async {
    final packageName = request.packageName;
    final listing = await _getListing(
      uri: 'package|$packageName',
      lookup: 'package "$packageName"',
      subject: 'listing of package "$packageName"',
      locale: request.locale,
      matches: (listing) => listing['package']?.toString() == packageName,
    );
    final storeID = switch (listing.storeID) {
      String storeID when _storeIDPattern.hasMatch(storeID) => storeID,
      final storeID => throw FormatException(
        'AppGallery listing of package "$packageName" does not contain a '
        'valid App ID.',
        storeID,
      ),
    };
    return (version: listing.version, appURL: _buildAppURL(storeID));
  }

  /// Returns the published version, package, and App ID of the first listing
  /// in the response for [uri] that [matches].
  Future<({String packageName, String? storeID, String version})> _getListing({
    required String uri,
    required String lookup,
    required String subject,
    required String locale,
    required bool Function(Map<String, Object?> listing) matches,
  }) async {
    final identityID = _createIdentityID();
    var interfaceCode = await _getInterfaceCode(identityID);
    var response = await _getTabDetail(
      identityID: identityID,
      interfaceCode: interfaceCode,
      locale: locale,
      uri: uri,
    );
    var data = _decodeResponse(response);
    var resultCode = _toIntOrNull(data['rtnCode']);
    if (resultCode == 1002) {
      interfaceCode = await _getInterfaceCode(identityID);
      response = await _getTabDetail(
        identityID: identityID,
        interfaceCode: interfaceCode,
        locale: locale,
        uri: uri,
      );
      data = _decodeResponse(response);
      resultCode = _toIntOrNull(data['rtnCode']);
    }
    if (resultCode != 0) {
      throw StateError(
        'AppGallery lookup failed with result code '
        '${resultCode ?? 'unknown'} for $lookup.',
      );
    }

    final listing = _findListing(data, matches);
    if (listing == null) {
      throw FormatException(
        'AppGallery response does not contain $subject.',
        response.body,
      );
    }

    final version = listing['versionName']?.toString().trim();
    final packageName = listing['package']?.toString().trim();
    if (version == null || version.isEmpty) {
      throw FormatException(
        'AppGallery $subject does not contain a version.',
        response.body,
      );
    }
    if (packageName == null || packageName.isEmpty) {
      throw FormatException(
        'AppGallery $subject does not contain a package name.',
        response.body,
      );
    }

    return (
      packageName: packageName,
      storeID: listing['appid']?.toString().trim(),
      version: version,
    );
  }

  Future<String> _getInterfaceCode(String identityID) async {
    final uri = Uri.https(_host, '/edge/webedge/getInterfaceCode');
    final response = await _httpClient
        .post(uri, headers: <String, String>{'Identity-Id': identityID})
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'AppGallery interface-code request failed '
        '(HTTP ${response.statusCode}).',
        uri,
      );
    }

    final Object? value = jsonDecode(response.body);
    if (value case String interfaceCode when interfaceCode.isNotEmpty) {
      return interfaceCode;
    }
    throw FormatException(
      'AppGallery returned an invalid interface code.',
      response.body,
    );
  }

  Future<http.Response> _getTabDetail({
    required String identityID,
    required String interfaceCode,
    required String locale,
    required String uri,
  }) async {
    final url = Uri.https(_host, '/edge/uowap/index', <String, String>{
      'method': 'internal.getTabDetail',
      'serviceType': '20',
      'reqPageNum': '1',
      'uri': uri,
      'maxResults': '25',
      'zone': '',
      'locale': locale.trim().replaceAll('-', '_'),
    });
    final response = await _httpClient
        .get(
          url,
          headers: <String, String>{
            'Identity-Id': identityID,
            'Interface-Code':
                '${interfaceCode}_${DateTime.now().millisecondsSinceEpoch}',
          },
        )
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'AppGallery listing request failed (HTTP ${response.statusCode}).',
        url,
      );
    }
    return response;
  }

  static Map<String, Object?> _decodeResponse(http.Response response) {
    final Object? value = jsonDecode(response.body);
    if (value case Map<String, Object?> data) return data;
    throw FormatException(
      'AppGallery returned an invalid listing response.',
      response.body,
    );
  }

  static Map<String, Object?>? _findListing(
    Object? value,
    bool Function(Map<String, Object?> listing) matches,
  ) => switch (value) {
    Map<String, Object?> map when map['versionName'] != null && matches(map) =>
      map,
    Map<String, Object?> map => _findFirstListing(map.values, matches),
    Iterable<Object?> values => _findFirstListing(values, matches),
    _ => null,
  };

  /// Returns the first listing found in [values], searching lazily.
  static Map<String, Object?>? _findFirstListing(
    Iterable<Object?> values,
    bool Function(Map<String, Object?> listing) matches,
  ) => values.map((child) => _findListing(child, matches)).nonNulls.firstOrNull;

  static int? _toIntOrNull(Object? value) => switch (value) {
    num number when number.isFinite && number == number.truncateToDouble() =>
      number.toInt(),
    String text => int.tryParse(text),
    _ => null,
  };

  static String _buildAppURL(String storeID) => Uri(
    scheme: 'https',
    host: 'appgallery.huawei.com',
    path: '/',
    fragment: '/app/$storeID',
  ).toString();

  static String _createIdentityID() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final value = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
