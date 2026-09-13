/// Illustrative flat-rate hire-purchase maths, as used by Thai motorcycle
/// finance companies. Final terms are confirmed by the showroom.
class Finance {
  Finance._();

  static const ratePerYear = 0.0299;
  static const termOptions = [12, 24, 36, 48, 60];

  static int downPayment(int price, double downPercent) => (price * downPercent).round();

  static int monthly({required int price, required double downPercent, required int months}) {
    final principal = price - downPayment(price, downPercent);
    final interest = principal * ratePerYear * (months / 12);
    return ((principal + interest) / months).ceil();
  }
}
