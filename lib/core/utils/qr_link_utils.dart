/// Helpers for encoding and parsing ScanMe QR deep links.
///
/// Social QRs use HTTPS URLs so standard phone cameras (iOS/Android) can
/// detect them. Les liens `scanme://` sont aussi acceptés lors du scan.
class QrLinkUtils {
  static const String webHost = 'scanme.app';

  static String buildSocialQrLink({
    required String ownerPhone,
    required String network,
    required String username,
  }) {
    final query = Uri(
      queryParameters: {
        'ownerPhone': ownerPhone,
        'network': network,
        'username': username,
      },
    ).query;

    return 'https://$webHost/social?$query';
  }

  static bool isSocialQrLink(String data) {
    if (data.startsWith('scanme://social')) return true;

    final uri = Uri.tryParse(data);
    if (uri == null) return false;

    return uri.scheme == 'https' &&
        (uri.host == webHost || uri.host == 'www.$webHost') &&
        (uri.path == '/social' || uri.path == '/social/');
  }

  static Map<String, String> parseSocialQrParams(String data) {
    return Uri.parse(data).queryParameters;
  }
}
