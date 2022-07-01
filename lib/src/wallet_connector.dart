import 'dart:async';

import 'package:public_address_wallet/src/app_info.dart';
import 'package:public_address_wallet/src/deeplink_helper.dart';
import 'package:public_address_wallet/src/wallet.dart';
import 'package:url_launcher/url_launcher.dart';

import 'wallet_connect_sdk/session/peer_meta.dart';
import 'wallet_connect_sdk/walletconnect.dart';

typedef OnSessionUriCallback = void Function(String uri);
Uri metamaskDownloadLink = Uri.parse("https://metamask.io/download/");

/// WalletConnector is an object for implement WalletConnect protocol for
/// mobile apps using deep linking to connect with wallets.
class WalletConnector {
  // walletconnect
  final WalletConnect connector;
  // mobile app info
  final AppInfo? appInfo;

  const WalletConnector._internal({
    required this.connector,
    required this.appInfo,
  });

  /// Connector using brigde 'https://bridge.walletconnect.org' by default.
  factory WalletConnector(AppInfo? appInfo, {String? bridge}) {
    var _connector = WalletConnect();
    try {
      final connector = WalletConnect(
        bridge: bridge ?? 'https://bridge.walletconnect.org',
        clientMeta: PeerMeta(
          name: appInfo?.name ?? 'WalletConnect',
          description: appInfo?.description ?? 'WalletConnect Developer App',
          url: appInfo?.url ?? 'https://walletconnect.org',
          icons: appInfo?.icons ??
              [
                'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
              ],
        ),
      );
      _connector = connector;

      return WalletConnector._internal(
        connector: connector,
        appInfo: appInfo,
      );
    } catch (e) {
      launchUrl(metamaskDownloadLink);
      print(e);
      return WalletConnector._internal(
        connector: _connector,
        appInfo: appInfo,
      );
    }
  }

  /// Get public address, wallet param only use on iOS and using metamask by default
  ///
  /// flow: connector init session then open deeplink with uri from session
  /// if can not launch throw an error else
  /// if user approve session in wallet return a valid public address
  /// if user reject session in wallet, or something wrong happen throw an error
  /// in other case throw 'Unexpected exception'
  Future<String> publicAddress({Wallet wallet = Wallet.metamask}) async {
    if (!connector.connected) {
      final session = await connector.createSession(
        onDisplayUri: (uri) async {
          var deeplink = DeeplinkHelper.getDeeplink(wallet: wallet, uri: uri);
          if (!await launch(deeplink, forceSafariVC: false)) {
            throw Future.error(Exception("Platformmmmm"));
          }
        },
      ).catchError((onError) {
        launchUrl(metamaskDownloadLink);
        throw Future.error(Exception("Platformmmmm"));
      });
      if (session.accounts.isNotEmpty) {
        var address = session.accounts.first;
        return address;
      } else {
        launchUrl(metamaskDownloadLink);
        throw Future.error(Exception("Platformmmmm"));
      }
    } else {
      if (connector.session.accounts.isNotEmpty) {
        return connector.session.accounts.first;
      } else {
        launchUrl(metamaskDownloadLink);
        throw Future.error(Exception("Platformmmmm"));
      }
    }
  }

  // just init session
  void initSession(void Function(String)? onDisplayUri) async {
    if (!connector.connected) {
      await connector.createSession(onDisplayUri: onDisplayUri);
    } else {
      if (onDisplayUri != null) {
        onDisplayUri(connector.session.toUri());
      }
    }
  }

  void dispose() {
    connector.killSession();
  }
}
