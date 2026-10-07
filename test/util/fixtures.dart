import 'dart:convert';

/// Builds the identified Google Play data used by public listing pages.
String googlePlayListing(
  String version, {
  String packageName = 'test.app',
  bool sparse = false,
  int versionField = 141,
}) {
  final app = List<Object?>.filled(
    sparse ? 78 : versionField + 1,
    null,
    growable: sparse,
  );
  app[77] = [packageName];
  final versionData = <Object?>[
    [
      [version],
    ],
  ];
  if (sparse) {
    app.add(<String, Object?>{'$versionField': versionData});
  } else {
    app[versionField] = versionData;
  }
  final data = jsonEncode(<Object?>[
    null,
    <Object?>[null, null, app],
  ]);
  return "AF_initDataCallback({key: 'ds:5', hash: '1', "
      'data:$data, sideChannel: {}});';
}
