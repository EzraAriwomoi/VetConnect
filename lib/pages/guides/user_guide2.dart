import 'package:flutter/material.dart';
import 'package:vetconnect/components/coloors/colors.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';
import 'package:vetconnect/pages/guides/user_guide3.dart';

class UserGuide2 extends StatelessWidget {
  const UserGuide2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.primecolor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: context.theme.primecolor,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 62.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: context.theme.deepprimecolor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.0),
                    topRight: Radius.circular(20.0),
                  ),
                  child: Image.asset(
                    'assets/user_guide2.jpg',
                    fit: BoxFit.contain,
                    height: 400,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipPath(
              clipper: CurveClipper(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                color: context.theme.curvedpartcolor,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'For the health and care of your pet',
                        style: TextStyle(
                          fontSize: 32,
                          color: context.theme.titletext,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 12),

                      Text(
                        'Empower yourself with essential knowledge and resources to provide the best care for your beloved pets.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: context.theme.subtitletext,
                        ),
                      ),
                      SizedBox(height: 50),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                              radius: 4,
                              backgroundColor: CustomColors.greycolor),
                          SizedBox(width: 6),
                          CircleAvatar(
                              radius: 4, backgroundColor: context.theme.primecolor),
                          SizedBox(width: 6),
                          CircleAvatar(
                              radius: 4,
                              backgroundColor: CustomColors.greycolor),
                        ],
                      ),

                      SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => UserGuide3()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.theme.primecolor,
                            padding: EdgeInsets.symmetric(
                                vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper to create a curve of the container
class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height * 0.2);
    path.quadraticBezierTo(
      size.width / 2,
      0,
      size.width,
      size.height * 0.2,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
