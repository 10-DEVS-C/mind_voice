import 'dart:async';
import 'dart:io';

class RequestErrorMapper {
  static const String networkPrefix = 'Problema de red.';
  static const String networkRetryMessage =
      '$networkPrefix Verifica tu conexión e intenta de nuevo.';
  static const String sessionInvalidMessage =
      'Sesión inválida. Debes iniciar sesión nuevamente.';

  static bool isSessionInvalidStatus(int statusCode) {
    return statusCode == 400 || statusCode == 401 || statusCode == 403;
  }

  static String fromHttpStatus(int statusCode, String operationMessage) {
    if (isSessionInvalidStatus(statusCode)) {
      return sessionInvalidMessage;
    }

    if (statusCode >= 500) {
      return 'Error del servidor. $operationMessage';
    }

    return 'No se pudo completar la solicitud. $operationMessage';
  }

  static bool isNetworkException(Object error) {
    return error is SocketException || error is TimeoutException;
  }

  static String fromException(
    Object error, {
    String fallbackMessage = 'No se pudo completar la operación. Intenta de nuevo.',
  }) {
    if (isNetworkException(error)) {
      return networkRetryMessage;
    }

    return fallbackMessage;
  }

  static bool isNetworkMessage(String message) {
    return message.startsWith(networkPrefix);
  }
}
