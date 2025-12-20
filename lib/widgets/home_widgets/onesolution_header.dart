
import 'package:Velorex/widgets/theme.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:google_fonts/google_fonts.dart';

class OnesolutionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "OneSolution App"
        //     .text
        //     .xl5
        //     .bold
        //     .color(MyTheme.softLightColor)
        //     .textStyle(GoogleFonts.poppins()) //  Poppins font
        //     .make()
        //     .pOnly(top: 10, bottom: 0),

        "Trending Services"
            .text
            .xl3                       .bold
            .color(MyTheme.lightBluishColor)
            .textStyle(GoogleFonts.poppins()) //  Poppins font
            .make()
            .pOnly(bottom: 10),
      ],
    );
  }
}
