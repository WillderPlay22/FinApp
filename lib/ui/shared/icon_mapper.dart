import 'package:flutter/widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// This list must contain every single FontAwesome icon you use dynamically.
// If an icon's code is stored in the database, the original IconData object MUST be in this list.
const List<IconData> _registeredIcons = [
  FontAwesomeIcons.tag, FontAwesomeIcons.burger, FontAwesomeIcons.bus, 
  FontAwesomeIcons.house, FontAwesomeIcons.bolt, FontAwesomeIcons.heartPulse,
  FontAwesomeIcons.bagShopping, FontAwesomeIcons.gamepad, FontAwesomeIcons.graduationCap,
  FontAwesomeIcons.paw, FontAwesomeIcons.plane, FontAwesomeIcons.dumbbell,
  FontAwesomeIcons.shirt, FontAwesomeIcons.gift, FontAwesomeIcons.wrench,
  FontAwesomeIcons.car, FontAwesomeIcons.wifi, FontAwesomeIcons.mobile,
  FontAwesomeIcons.baby, FontAwesomeIcons.book,
  // Add other icons that might be stored in the DB from other parts of the app
  // For example, from income categories or default seeders.
  FontAwesomeIcons.moneyBillWave,
  FontAwesomeIcons.moneyBill,
  FontAwesomeIcons.piggyBank,
  FontAwesomeIcons.laptop,
  FontAwesomeIcons.coins,
  FontAwesomeIcons.sackDollar,
  FontAwesomeIcons.building,
  FontAwesomeIcons.umbrellaBeach,
  FontAwesomeIcons.question, // A good fallback
];

// We create a map for fast lookups. The map is created at compile time.
final Map<int, IconData> _iconMap = { for (var icon in _registeredIcons) icon.codePoint: icon };

/// Looks up an IconData from its code point.
///
/// This is the correct way to get an IconData object at runtime without breaking
/// Flutter's icon tree shaking. Returns a fallback icon if the code is not found.
IconData getIconFromCode(int code) {
  return _iconMap[code] ?? FontAwesomeIcons.question;
}