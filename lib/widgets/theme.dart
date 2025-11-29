import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTheme {
static ThemeData lightTheme(BuildContext context) => ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blueGrey,
  scaffoldBackgroundColor: creamColor,
  canvasColor: creamColor,
  cardColor: Colors.grey,
  fontFamily: GoogleFonts.poppins().fontFamily,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: creamColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkBluishColor,
      foregroundColor: Colors.black,
      shape: StadiumBorder(),
    ),
  ),
);

static ThemeData darkTheme(BuildContext context) => ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blueGrey,
  scaffoldBackgroundColor: darkcreamColor,
  canvasColor: darkcreamColor,
  cardColor: Vx.gray700,
  fontFamily: GoogleFonts.poppins().fontFamily,
  colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
    secondary: darkcreamColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkBluishColor,
      foregroundColor: Colors.black,
      shape: StadiumBorder(),
    ),
  ),
);

static Color creamColor =Color(0xfff5f5f5);
static Color cyanColor =Color(0xFF00FFFF); 
static Color deepblueColor =Color(0xFF0000FF) ;
static Color softLightColor = Color(0xFFEEEEEE); // Soft light gray, perfect on black
// ALTERNATE (0xFF0000FF)
static Color darkcreamColor =Vx.gray900;
static Color ncreamColor =Vx.gray700;
  static Color darkBluishColor = Color(0xff403b58);
  static Color lightBluishColor = Vx.purple400;
}
