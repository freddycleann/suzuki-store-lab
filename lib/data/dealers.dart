import '../models/dealer.dart';

/// Sample showroom network for the lab project (approximate locations).
class Dealers {
  Dealers._();

  static const all = [
    Dealer(
      id: 'bkk-rama9',
      name: 'Suzuki Showroom Rama 9',
      area: 'Bangkok',
      address: 'Rama 9 Rd, Huai Khwang, Bangkok',
      hours: '09:00–19:00',
      latitude: 13.7588,
      longitude: 100.5652,
      bigBikeCenter: true,
    ),
    Dealer(
      id: 'bkk-bangna',
      name: 'Suzuki Showroom Bang Na',
      area: 'Bangkok',
      address: 'Bang Na–Trat Rd, Bang Na, Bangkok',
      hours: '09:00–18:00',
      latitude: 13.6680,
      longitude: 100.6340,
      bigBikeCenter: true,
    ),
    Dealer(
      id: 'nonthaburi',
      name: 'Suzuki Showroom Ngamwongwan',
      area: 'Nonthaburi',
      address: 'Ngamwongwan Rd, Mueang Nonthaburi',
      hours: '08:30–18:00',
      latitude: 13.8590,
      longitude: 100.5390,
    ),
    Dealer(
      id: 'chiangmai',
      name: 'Suzuki Showroom Chiang Mai',
      area: 'Chiang Mai',
      address: 'Superhighway Rd, Mueang Chiang Mai',
      hours: '08:30–18:00',
      latitude: 18.8030,
      longitude: 99.0100,
      bigBikeCenter: true,
    ),
    Dealer(
      id: 'pattaya',
      name: 'Suzuki Showroom Pattaya',
      area: 'Chonburi',
      address: 'Sukhumvit Rd, Bang Lamung, Chonburi',
      hours: '09:00–18:00',
      latitude: 12.9280,
      longitude: 100.9020,
    ),
  ];
}
