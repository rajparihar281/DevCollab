class PendingLoginCredentialHolder {
  static String? pendingEmail;
  static String? pendingPassword;

  static void set(String email, String password) {
    pendingEmail = email;
    pendingPassword = password;
  }

  static void clear() {
    pendingEmail = null;
    pendingPassword = null;
  }
}
