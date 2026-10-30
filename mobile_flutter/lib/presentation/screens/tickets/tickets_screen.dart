import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/data/models/booking_model.dart';
import 'package:mobile_flutter/providers/booking_providers.dart';
import 'package:mobile_flutter/presentation/widgets/state_views.dart';

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsState = ref.watch(bookingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Digital Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Tickets',
            onPressed: () {
              ref.read(bookingsNotifierProvider.notifier).loadBookings();
            },
          ),
        ],
      ),
      body: bookingsState.isLoading
          ? const LoadingView(message: 'Loading tickets from server...')
          : bookingsState.bookings.isEmpty
              ? EmptyStateView(
                  icon: Icons.confirmation_num_outlined,
                  title: 'No Digital Tickets Yet',
                  message:
                      'You haven\'t booked any bus rides yet. Plan a journey or browse routes to generate a digital travel pass.',
                  actionLabel: 'Browse Routes',
                  onAction: () => context.push('/routes'),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(bookingsNotifierProvider.notifier).loadBookings(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookingsState.bookings.length,
                    itemBuilder: (context, index) {
                      final ticket = bookingsState.bookings[index];
                      return _TicketCard(
                        ticket: ticket,
                        onTap: () => context.push('/ticket/${ticket.id}'),
                      );
                    },
                  ),
                ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final BookingModel ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(ticket.bookedAt));
    final isCancelled = ticket.status.toUpperCase() == 'CANCELLED';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCancelled ? AppColors.dangerLight : AppColors.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isCancelled ? AppColors.dangerLight : AppColors.primaryNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'BUS ${ticket.routeNumber}',
                      style: TextStyle(
                        color: isCancelled ? AppColors.danger : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCancelled ? AppColors.dangerLight : AppColors.successLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isCancelled ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${ticket.sourceStop} ➔ ${ticket.destinationStop}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                'Ref: ${ticket.bookingReference} · $formattedDate',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${ticket.passengerCount} Passenger${ticket.passengerCount > 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      Text(
                        '₹${ticket.fare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accentTeal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.qr_code_rounded, size: 20, color: AppColors.primaryNavy),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
