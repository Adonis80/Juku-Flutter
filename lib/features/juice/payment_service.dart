import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/supabase_config.dart';

/// Juice-to-pence tiers matching the top-up cards.
class JuiceTier {
  const JuiceTier({
    required this.juice,
    required this.pricePence,
    required this.priceLabel,
    this.bonus,
  });

  final int juice;
  final int pricePence;
  final String priceLabel;
  final String? bonus;
}

const juiceTiers = [
  JuiceTier(juice: 10, pricePence: 100, priceLabel: '£1'),
  JuiceTier(juice: 55, pricePence: 500, priceLabel: '£5', bonus: '+10%'),
  JuiceTier(juice: 120, pricePence: 1000, priceLabel: '£10', bonus: '+20%'),
];

/// Centralized payment service for Stripe + GoCardless integration.
class PaymentService {
  PaymentService._();
  static final instance = PaymentService._();

  /// Initialize Stripe with the publishable key.
  /// Call once in main() after Supabase init.
  static void initStripe(String publishableKey) {
    Stripe.publishableKey = publishableKey;
    Stripe.merchantIdentifier = 'merchant.pro.juku.app';
  }

  /// Create a PaymentIntent on the server and show Stripe PaymentSheet.
  /// Returns true if payment succeeded.
  Future<bool> topUpWithCard({
    required int juiceAmount,
    required int amountPence,
  }) async {
    final session = supabase.auth.currentSession;
    if (session == null) return false;

    // 1. Create PaymentIntent via Edge Function
    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/create-payment-intent'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount_pence': amountPence,
        'juice_amount': juiceAmount,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('PaymentIntent creation failed: ${response.body}');
      return false;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final clientSecret = data['client_secret'] as String?;
    if (clientSecret == null) return false;

    // 2. Present Stripe PaymentSheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Juku',
        style: ThemeMode.system,
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
      return true; // Success — webhook will credit Juice
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return false; // User cancelled
      }
      debugPrint('Stripe error: ${e.error.localizedMessage}');
      return false;
    }
  }

  /// Save a card for future use (SetupIntent flow).
  Future<bool> saveCard() async {
    final session = supabase.auth.currentSession;
    if (session == null) return false;

    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/create-payment-intent'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'action': 'setup'}),
    );

    if (response.statusCode != 200) return false;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final clientSecret = data['client_secret'] as String?;
    if (clientSecret == null) return false;

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        setupIntentClientSecret: clientSecret,
        merchantDisplayName: 'Juku',
        style: ThemeMode.system,
      ),
    );

    try {
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException {
      return false;
    }
  }

  /// Launch GoCardless hosted mandate setup page in browser.
  /// The GoCardless redirect flow ID should be created server-side.
  Future<bool> setupGoCardlessMandate() async {
    final session = supabase.auth.currentSession;
    if (session == null) return false;

    final response = await http.post(
      Uri.parse('$supabaseUrl/functions/v1/create-gocardless-redirect'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode != 200) return false;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final redirectUrl = data['redirect_url'] as String?;
    if (redirectUrl == null) return false;

    final uri = Uri.parse(redirectUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return true;
    }
    return false;
  }

  /// Fetch user's payment methods from Supabase.
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final data = await supabase
        .from('payment_methods')
        .select()
        .eq('user_id', user.id)
        .eq('status', 'active')
        .order('is_default', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Fetch settlement history for the current user.
  Future<List<Map<String, dynamic>>> getSettlements() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final data = await supabase
        .from('settlements')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(20);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Set a payment method as the user's default.
  Future<void> setDefaultMethod(String methodId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Unset current default
    await supabase
        .from('payment_methods')
        .update({'is_default': false})
        .eq('user_id', user.id)
        .eq('is_default', true);

    // Set new default
    await supabase
        .from('payment_methods')
        .update({'is_default': true})
        .eq('id', methodId);
  }

  /// Remove a payment method.
  Future<void> removeMethod(String methodId) async {
    await supabase
        .from('payment_methods')
        .update({'status': 'cancelled'})
        .eq('id', methodId);
  }
}
