// Stub pour éviter les erreurs d'import sur le web
// flutter_stripe n'est pas disponible sur web, donc on crée des stubs

class Stripe {
  static String publishableKey = '';
  static Stripe get instance => Stripe();
  Future<void> applySettings() async {}
  Future<void> initPaymentSheet({required dynamic paymentSheetParameters}) async {}
  Future<void> presentPaymentSheet() async {}
}

class StripeException implements Exception {
  final StripeError error;
  StripeException(this.error);
}

class StripeError {
  final FailureCode? code;
  final String? localizedMessage;
  StripeError({this.code, this.localizedMessage});
}

enum FailureCode {
  Canceled,
}

class SetupPaymentSheetParameters {
  final String? paymentIntentClientSecret;
  final String? merchantDisplayName;
  final PaymentSheetAppearance? appearance;
  final PaymentSheetGooglePay? googlePay;
  final PaymentSheetApplePay? applePay;

  SetupPaymentSheetParameters({
    this.paymentIntentClientSecret,
    this.merchantDisplayName,
    this.appearance,
    this.googlePay,
    this.applePay,
  });
}

class PaymentSheetAppearance {
  final PaymentSheetAppearanceColors? colors;
  final PaymentSheetShape? shapes;
  final PaymentSheetPrimaryButtonAppearance? primaryButton;

  PaymentSheetAppearance({
    this.colors,
    this.shapes,
    this.primaryButton,
  });
}

class PaymentSheetAppearanceColors {
  final dynamic primary;
  final dynamic background;
  final dynamic componentBackground;
  final dynamic componentBorder;
  final dynamic primaryText;
  final dynamic secondaryText;
  final dynamic placeholderText;

  PaymentSheetAppearanceColors({
    this.primary,
    this.background,
    this.componentBackground,
    this.componentBorder,
    this.primaryText,
    this.secondaryText,
    this.placeholderText,
  });
}

class PaymentSheetShape {
  final double? borderRadius;
  final double? borderWidth;

  const PaymentSheetShape({
    this.borderRadius,
    this.borderWidth,
  });
}

class PaymentSheetPrimaryButtonAppearance {
  final PaymentSheetPrimaryButtonTheme? colors;

  PaymentSheetPrimaryButtonAppearance({
    this.colors,
  });
}

class PaymentSheetPrimaryButtonTheme {
  final PaymentSheetPrimaryButtonThemeColors? light;

  PaymentSheetPrimaryButtonTheme({
    this.light,
  });
}

class PaymentSheetPrimaryButtonThemeColors {
  final dynamic background;
  final dynamic text;
  final dynamic border;

  PaymentSheetPrimaryButtonThemeColors({
    this.background,
    this.text,
    this.border,
  });
}

class PaymentSheetGooglePay {
  final String? merchantCountryCode;
  final String? currencyCode;
  final bool? testEnv;

  const PaymentSheetGooglePay({
    this.merchantCountryCode,
    this.currencyCode,
    this.testEnv,
  });
}

class PaymentSheetApplePay {
  final String? merchantCountryCode;

  const PaymentSheetApplePay({
    this.merchantCountryCode,
  });
}
