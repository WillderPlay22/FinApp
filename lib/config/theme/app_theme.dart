import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color principal
  static const Color seedColor = Color(0xFF2E7D32); 

  ThemeData getTheme() => ThemeData(
    useMaterial3: true,
    colorSchemeSeed: seedColor,
    brightness: Brightness.light,
    
    // Fuente moderna
    textTheme: GoogleFonts.outfitTextTheme(),
    
    // Eliminamos 'cardTheme' por completo para evitar el conflicto de versiones
  );
}