import 'package:fluttertoast/fluttertoast.dart';

class Toasted {
  void showToast(Object msg) {
    Fluttertoast.showToast(
        msg: msg.toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM);
  }
}
