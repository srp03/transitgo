import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/providers/booking_providers.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final int ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  bool _isCancelling = false;

  Future<void> _cancelTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Ticket?'),
        content: const Text('Are you sure you want to cancel this booking? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Ticket')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    try {
      await ref.read(bookingsNotifierProvider.notifier).cancelBooking(widget.ticketId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket has been cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancellation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsState = ref.watch(bookingsNotifierProvider);
    final ticket = bookingsState.bookings.firstWhere(
      (b) => b.id == widget.ticketId,
      orElse: () => bookingsState.bookings.isNotEmpty ? bookingsState.bookings.first : throw Exception('Not found'),
    );

    final isCancelled = ticket.status.toUpperCase() == 'CANCELLED';
    final formattedDate = DateFormat('dd MMMM yyyy, hh:mm a')
        .format(DateTime.fromMillisecondsSinceEpoch(ticket.bookedAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Boarding Pass'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Boarding Pass Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Pass Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isCancelled ? AppColors.danger : AppColors.primaryNavy,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.accentAmber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'BUS ${ticket.routeNumber}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ticket.status.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${ticket.sourceStop} ➔ ${ticket.destinationStop}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Middle Details
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _PassRow(label: 'Booking Reference', value: ticket.bookingReference, isBold: true),
                        const SizedBox(height: 12),
                        _PassRow(label: 'Booked On', value: formattedDate),
                        const SizedBox(height: 12),
                        _PassRow(label: 'Passengers', value: '${ticket.passengerCount} Adult(s)'),
                        const SizedBox(height: 12),
                        _PassRow(label: 'Payment Method', value: 'UPI Demo (${ticket.paymentStatus})'),
                        const SizedBox(height: 12),
                        _PassRow(label: 'Total Fare', value: '₹${ticket.fare.toStringAsFixed(0)}', isPrice: true),
                      ],
                    ),
                  ),

                  // Perforated line effect
                  Row(
                    children: [
                      Container(width: 14, height: 28, decoration: const BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.horizontal(right: Radius.circular(14)))),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Flex(
                              direction: Axis.horizontal,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                (constraints.constrainWidth() / 10).floor(),
                                (_) => const SizedBox(width: 5, height: 1.5, child: DecoratedBox(decoration: BoxDecoration(color: AppColors.borderLight))),
                              ),
                            );
                          },
                        ),
                      ),
                      Container(width: 14, height: 28, decoration: const BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.horizontal(left: Radius.circular(14)))),
                    ],
                  ),

                  // QR Code Section
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        if (!isCancelled) ...[
                          QrImageView(
                            data: ticket.qrPayload.isNotEmpty ? ticket.qrPayload : ticket.bookingReference,
                            version: QrVersions.auto,
                            size: 180.0,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: AppColors.primaryNavy,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Scan for In-Bus Inspection',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cancel_outlined, size: 64, color: AppColors.danger),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'TICKET CANCELLED',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.danger),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevatedLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticket.notice,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions: Cancel Ticket if not cancelled
            if (!isCancelled)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _isCancelling ? null : _cancelTicket,
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
                  label: _isCancelling
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Cancel This Ticket', style: TextStyle(color: AppColors.danger)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.dangerLight, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PassRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isPrice;

  const _PassRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryLight)),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 18 : 13.5,
            fontWeight: isBold || isPrice ? FontWeight.w900 : FontWeight.w600,
            color: isPrice ? AppColors.accentTeal : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
