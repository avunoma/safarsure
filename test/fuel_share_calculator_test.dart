import 'package:flutter_test/flutter_test.dart';
import 'package:safarsure/core/constants/fuel_share_constants.dart';
import 'package:safarsure/core/services/fuel_share_calculator.dart';
import 'package:safarsure/core/services/ride_offer_limit_service.dart';
import 'package:safarsure/core/services/trip_compliance_service.dart';
import 'package:safarsure/data/models/trip.dart';
import 'package:safarsure/data/models/vehicle.dart';
import 'package:safarsure/data/repositories/app_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const calculator = FuelShareCalculator();

  group('FuelShareCalculator', () {
    test('computes fuel + toll cost split across passengers and driver', () {
      // 300 km, hatchback 15 km/L, petrol ₹100/L, tolls ₹200, 3 passenger seats
      // fuel = (300/15)*100 = 2000; total = 2200; per person = 2200/4 = 550
      final result = calculator.calculate(
        distanceKm: 300,
        vehicleCategory: VehicleCategory.hatchback,
        fuelType: FuelType.petrol,
        fuelRateInr: 100,
        tollCostsInr: 200,
        passengerSeats: 3,
      );

      expect(result.fuelCostInr, closeTo(2000, 0.01));
      expect(result.totalRouteCostInr, closeTo(2200, 0.01));
      expect(result.occupants, 4);
      expect(result.maxContributionPerSeatInr, 550);
    });

    test('uses sedan mileage benchmark (12 km/L)', () {
      // 120 km, sedan 12 km/L, ₹96/L, no tolls, 1 passenger seat
      // fuel = (120/12)*96 = 960; total = 960; per person = 960/2 = 480
      final result = calculator.calculate(
        distanceKm: 120,
        vehicleCategory: VehicleCategory.sedan,
        fuelType: FuelType.petrol,
        fuelRateInr: 96,
        tollCostsInr: 0,
        passengerSeats: 1,
      );

      expect(result.mileageKmPerUnit, 12);
      expect(result.maxContributionPerSeatInr, 480);
    });

    test('uses SUV mileage benchmark (10 km/L)', () {
      // 100 km, SUV 10 km/L, ₹100/L, tolls ₹50, 2 passenger seats
      // fuel = 1000; total = 1050; per person = 1050/3 = 350
      final result = calculator.calculate(
        distanceKm: 100,
        vehicleCategory: VehicleCategory.suv,
        fuelType: FuelType.diesel,
        fuelRateInr: 100,
        tollCostsInr: 50,
        passengerSeats: 2,
      );

      expect(result.mileageKmPerUnit, 10);
      expect(result.maxContributionPerSeatInr, 350);
    });

    test('uses EV km/kWh benchmark (6 km/kWh)', () {
      // 60 km, 6 km/kWh, ₹9/kWh, no tolls, 1 passenger
      // energy = 10 kWh; cost = 90; per person = 90/2 = 45
      final result = calculator.calculate(
        distanceKm: 60,
        vehicleCategory: VehicleCategory.ev,
        fuelType: FuelType.ev,
        fuelRateInr: 9,
        tollCostsInr: 0,
        passengerSeats: 1,
      );

      expect(result.mileageKmPerUnit, FuelShareConstants.evKmPerKwh);
      expect(result.maxContributionPerSeatInr, 45);
    });

    test('rounds to nearest rupee (half-up)', () {
      expect(FuelShareCalculator.roundInr(10.4), 10);
      expect(FuelShareCalculator.roundInr(10.5), 11);
      expect(FuelShareCalculator.roundInr(10.6), 11);
    });

    test('isWithinCap and clampToMax enforce maximum', () {
      final result = calculator.calculate(
        distanceKm: 150,
        vehicleCategory: VehicleCategory.hatchback,
        fuelType: FuelType.petrol,
        fuelRateInr: 102,
        tollCostsInr: 0,
        passengerSeats: 2,
      );

      expect(result.maxContributionPerSeatInr, 340);
      expect(calculator.isWithinCap(contributionPerSeat: 300, result: result),
          isTrue);
      expect(calculator.isWithinCap(contributionPerSeat: 9999, result: result),
          isFalse);
      expect(
        calculator.clampToMax(contributionPerSeat: 9999, result: result),
        result.maxContributionPerSeatInr,
      );
    });
  });

  group('RideOfferLimitService', () {
    const service = RideOfferLimitService();
    final now = DateTime(2026, 9, 5, 12, 0);

    Trip offer(String id, {Duration age = Duration.zero}) {
      return Trip(
        id: id,
        driverId: 'driver-1',
        fromCity: 'Mumbai',
        toCity: 'Pune',
        departureTime: now.add(const Duration(days: 1)),
        seatsTotal: 2,
        seatsAvailable: 2,
        pricePerSeat: 200,
        vehicle: const Vehicle(make: 'X', model: 'Y', color: 'Z'),
        publishedAt: now.subtract(age),
      );
    }

    test('allows up to 4 offers in rolling 24 hours', () {
      final trips = List.generate(
        4,
        (i) => offer('t$i', age: Duration(hours: i + 1)),
      );
      expect(service.canPublish(trips, 'driver-1', now: now), isFalse);
      expect(service.countRecentOffers(trips, 'driver-1', now: now), 4);
    });

    test('ignores offers older than 24 hours', () {
      final trips = [
        offer('old', age: const Duration(hours: 25)),
        offer('new', age: const Duration(hours: 2)),
      ];
      expect(service.countRecentOffers(trips, 'driver-1', now: now), 1);
      expect(service.canPublish(trips, 'driver-1', now: now), isTrue);
    });
  });

  group('TripComplianceService', () {
    const compliance = TripComplianceService();

    test('rejects contribution above computed maximum', () {
      final trip = Trip(
        id: 't1',
        driverId: 'd1',
        fromCity: 'A',
        toCity: 'B',
        departureTime: DateTime(2026, 9, 10),
        seatsTotal: 2,
        seatsAvailable: 2,
        pricePerSeat: 999,
        maxFuelContributionPerSeat: 350,
        distanceKm: 100,
        vehicle: const Vehicle(make: 'X', model: 'Y', color: 'Z'),
      );

      expect(
        () => compliance.validateForPublish(trip, []),
        throwsA(isA<TripComplianceException>()),
      );
    });
  });

  group('AppRepository ride offer cap', () {
    test('rejects fifth publish within 24 hours', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = AppRepository(await SharedPreferences.getInstance());
      await repo.initialize();

      final now = DateTime.now();
      for (var i = 0; i < 4; i++) {
        await repo.addTrip(
          Trip(
            id: 'trip-$i',
            driverId: 'driver-cap',
            fromCity: 'Delhi',
            toCity: 'Jaipur',
            departureTime: now.add(Duration(days: i + 1)),
            seatsTotal: 2,
            seatsAvailable: 2,
            pricePerSeat: 100,
            maxFuelContributionPerSeat: 200,
            distanceKm: 280,
            vehicle: const Vehicle(make: 'X', model: 'Y', color: 'Z'),
            publishedAt: now,
          ),
        );
      }

      expect(repo.canDriverPublishOffer('driver-cap'), isFalse);
      expect(
        () => repo.addTrip(
          Trip(
            id: 'trip-5',
            driverId: 'driver-cap',
            fromCity: 'Delhi',
            toCity: 'Agra',
            departureTime: now.add(const Duration(days: 5)),
            seatsTotal: 2,
            seatsAvailable: 2,
            pricePerSeat: 100,
            maxFuelContributionPerSeat: 200,
            distanceKm: 230,
            vehicle: const Vehicle(make: 'X', model: 'Y', color: 'Z'),
            publishedAt: now,
          ),
        ),
        throwsA(isA<TripComplianceException>()),
      );
    });
  });
}
