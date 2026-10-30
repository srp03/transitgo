import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking_model.dart';
import 'core_providers.dart';

class BookingsState {
  final List<BookingModel> bookings;
  final bool isLoading;
  final String? error;

  const BookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  BookingsState copyWith({
    List<BookingModel>? bookings,
    bool? isLoading,
    String? error,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BookingsNotifier extends Notifier<BookingsState> {
  @override
  BookingsState build() {
    Future.microtask(() => loadBookings());
    return const BookingsState(isLoading: true);
  }

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(bookingRepositoryProvider);
      final list = await repo.getAllBookings();
      state = state.copyWith(bookings: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<BookingModel> createBooking(CreateBookingRequest request) async {
    final repo = ref.read(bookingRepositoryProvider);
    final newBooking = await repo.createBooking(request);
    state = state.copyWith(
      bookings: [newBooking, ...state.bookings.where((b) => b.id != newBooking.id)],
    );
    return newBooking;
  }

  Future<BookingModel?> cancelBooking(int id) async {
    final repo = ref.read(bookingRepositoryProvider);
    final updated = await repo.cancelBooking(id);
    if (updated != null) {
      state = state.copyWith(
        bookings: state.bookings.map((b) => b.id == id ? updated : b).toList(),
      );
    }
    return updated;
  }
}

final bookingsNotifierProvider = NotifierProvider<BookingsNotifier, BookingsState>(BookingsNotifier.new);
