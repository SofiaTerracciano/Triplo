class ChangeEmailException implements Exception {
  final String code;

  ChangeEmailException(this.code);
}