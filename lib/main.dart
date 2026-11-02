import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapor_jalan/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: LaporJalanApp(),
    ),
  );
}
