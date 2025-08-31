import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Ritorna lo stato **di rete** del dispositivo (Wi-Fi/Dati/nessuna rete).
Future<ConnectivityResult> statoConnettivita() async {
  final c = await Connectivity().checkConnectivity();
  // Se la libreria restituisce una lista (alcune versioni), prendiamo il primo risultato utile
  if (c is List<ConnectivityResult>) {
    return c.isNotEmpty ? c.first : ConnectivityResult.none;
  }
  return c as ConnectivityResult;
}

/// Stream per ascoltare i cambiamenti di connettività (Wi-Fi/Dati/nessuna rete).
Stream<ConnectivityResult> connettivitaStream() {
  final stream = Connectivity().onConnectivityChanged;
  // Alcune versioni emettono ConnectivityResult, altre List<ConnectivityResult>
  return stream.map((event) {
    if (event is List<ConnectivityResult>) {
      return event.isNotEmpty ? event.first : ConnectivityResult.none;
    }
    return event as ConnectivityResult;
  });
}

/// Verifica **connettività Internet reale** provando a risolvere dei domini.
/// Utile per distinguere tra “connesso a una rete” e “Internet disponibile”.
Future<bool> isOnline({
  Duration timeout = const Duration(seconds: 3),
  List<String> hostsDaProvare = const ['one.one.one.one', 'google.com'],
}) async {
  final conn = await statoConnettivita();
  if (conn == ConnectivityResult.none) return false;

  for (final host in hostsDaProvare) {
    try {
      final res = await InternetAddress.lookup(host).timeout(timeout);
      if (res.isNotEmpty && res.first.rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException {
      // continua con il prossimo host
    } on Exception {
      // continua con il prossimo host
    }
  }
  return false;
}
