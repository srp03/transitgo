import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/data/models/booking_model.dart';
import 'package:mobile_flutter/data/models/stop_model.dart';
import 'package:mobile_flutter/providers/booking_providers.dart';
import 'package:mobile_flutter/providers/route_providers.dart';
import 'package:mobile_flutter/presentation/widgets/state_views.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  final int routeId;

  const BookingFlowScreen({super.key, required this.routeId});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _step = 0; // 0: Select Stops & Pax, 1: Review & Fare, 2: Mock UPI Payment
  String? _selectedSourceStop;
  String? _selectedDestStop;
  int _passengers = 1;
  final TextEditingController _upiController = TextEditingController(text: 'passenger@okhdfcbank');
  bool _simulateSuccess = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  double _calculateFare(List<StopModel> stops) {
    if (_selectedSourceStop == null || _selectedDestStop == null || stops.isEmpty) {
      return 15.0 * _passengers;
    }
    final srcIdx = stops.indexWhere((s) => s.name == _selectedSourceStop);
    final dstIdx = stops.indexWhere((s) => s.name == _selectedDestStop);
    if (srcIdx != -1 && dstIdx != -1 && dstIdx > srcIdx) {
      final span = dstIdx - srcIdx;
      return (span * 5.0 < 10.0 ? 10.0 : span * 5.0) * _passengers;
    }
    return 15.0 * _passengers;
  }

  Future<void> _processPaymentAndCreateBooking(double fare, String routeNumber, String routeName) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    // Simulate payment processing delay (1.2 seconds)
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!_simulateSuccess) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Mock payment was declined. Select "Successful Payment" to proceed.';
      });
      return;
    }

    try {
      final request = CreateBookingRequest(
        routeId: widget.routeId,
        sourceStop: _selectedSourceStop ?? 'Origin',
        destinationStop: _selectedDestStop ?? 'Destination',
        departureTime: 'Next Scheduled Bus',
        passengerCount: _passengers,
        fare: fare,
        upiId: _upiController.text.trim(),
      );

      final booking = await ref.read(bookingsNotifierProvider.notifier).createBooking(request);

      if (mounted) {
        setState(() => _isProcessing = false);
        context.pushReplacement('/ticket/${booking.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Booking creation failed: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeDetailAsync = ref.watch(routeDetailProvider(widget.routeId));
    final routeStopsAsync = ref.watch(routeStopsProvider(widget.routeId));

    return routeDetailAsync.when(
      data: (route) {
        if (route == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Book Ticket')),
            body: const EmptyStateView(title: 'Route Not Found', message: 'Unable to load route for booking.'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Book Bus ${route.routeNumber}'),
          ),
          body: routeStopsAsync.when(
            data: (stops) {
              // Set initial source and dest stops
              if (_selectedSourceStop == null && stops.isNotEmpty) {
                _selectedSourceStop = stops.first.name;
              }
              if (_selectedDestStop == null && stops.length > 1) {
                _selectedDestStop = stops.last.name;
              }

              final calculatedFare = _calculateFare(stops);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Progress Indicator
                    Row(
                      children: [
                        _StepBubble(stepNumber: 1, label: 'Journey', isActive: _step == 0, isDone: _step > 0),
                        Expanded(child: Container(height: 2, color: _step > 0 ? AppColors.accentTeal : AppColors.borderLight)),
                        _StepBubble(stepNumber: 2, label: 'Review', isActive: _step == 1, isDone: _step > 1),
                        Expanded(child: Container(height: 2, color: _step > 1 ? AppColors.accentTeal : AppColors.borderLight)),
                        _StepBubble(stepNumber: 3, label: 'Payment', isActive: _step == 2, isDone: false),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Demo Notice Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Demonstration Mode: Fares and UPI payments are simulated. No real money will be charged.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Step 0: Stop Selection & Passengers
                    if (_step == 0) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Boarding Stop', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedSourceStop,
                                isExpanded: true,
                                decoration: const InputDecoration(isDense: true),
                                items: stops.map((s) {
                                  return DropdownMenuItem(value: s.name, child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedSourceStop = val),
                              ),
                              const SizedBox(height: 16),
                              const Text('Destination Stop', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedDestStop,
                                isExpanded: true,
                                decoration: const InputDecoration(isDense: true),
                                items: stops.map((s) {
                                  return DropdownMenuItem(value: s.name, child: Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis));
                                }).toList(),
                                onChanged: (val) => setState(() => _selectedDestStop = val),
                              ),
                              const SizedBox(height: 20),
                              const Text('Passengers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.remove),
                                    onPressed: _passengers > 1 ? () => setState(() => _passengers--) : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Text('$_passengers Pax', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 16),
                                  IconButton.filledTonal(
                                    icon: const Icon(Icons.add),
                                    onPressed: _passengers < 6 ? () => setState(() => _passengers++) : null,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹${calculatedFare.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.accentTeal),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedSourceStop == _selectedDestStop) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Origin and destination cannot be the same')),
                              );
                              return;
                            }
                            setState(() => _step = 1);
                          },
                          child: const Text('Proceed to Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],

                    // Step 1: Review Summary
                    if (_step == 1) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('BUS ${route.routeNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('TMT Bus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.info)),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              _SummaryRow(label: 'From', value: _selectedSourceStop ?? ''),
                              const SizedBox(height: 10),
                              _SummaryRow(label: 'To', value: _selectedDestStop ?? ''),
                              const SizedBox(height: 10),
                              _SummaryRow(label: 'Passengers', value: '$_passengers'),
                              const SizedBox(height: 10),
                              _SummaryRow(label: 'Service Type', value: 'Ordinary / AC'),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Estimated Fare', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  Text('₹${calculatedFare.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() => _step = 0),
                              child: const Text('Back'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => _step = 2),
                              child: const Text('Proceed to Pay'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Step 2: Mock UPI Payment
                    if (_step == 2) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentTeal),
                                  SizedBox(width: 8),
                                  Text('Demo UPI Payment Gateway', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _upiController,
                                decoration: const InputDecoration(
                                  labelText: 'Virtual Payment Address (VPA / UPI ID)',
                                  hintText: 'e.g. yourname@bank',
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text('Simulation Outcome for Testing:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Radio<bool>(
                                    value: true,
                                    groupValue: _simulateSuccess,
                                    onChanged: (val) => setState(() => _simulateSuccess = val ?? true),
                                  ),
                                  const Text('Successful Payment', style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 12),
                                  Radio<bool>(
                                    value: false,
                                    groupValue: _simulateSuccess,
                                    onChanged: (val) => setState(() => _simulateSuccess = val ?? false),
                                  ),
                                  const Text('Simulate Failure', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(_errorMessage!, style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _processPaymentAndCreateBooking(calculatedFare, route.routeNumber, route.routeName),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentTeal,
                          ),
                          child: _isProcessing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                    SizedBox(width: 12),
                                    Text('Contacting Demo UPI Gateway...'),
                                  ],
                                )
                              : Text('Pay ₹${calculatedFare.toStringAsFixed(0)} (Demo)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const LoadingView(message: 'Loading stops for ticket selection...'),
            error: (err, _) => ErrorStateView(message: err.toString()),
          ),
        );
      },
      loading: () => Scaffold(appBar: AppBar(title: const Text('Book Ticket')), body: const LoadingView()),
      error: (err, _) => Scaffold(appBar: AppBar(title: const Text('Book Ticket')), body: ErrorStateView(message: err.toString())),
    );
  }
}

class _StepBubble extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepBubble({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.success
                : isActive
                    ? AppColors.primaryNavy
                    : AppColors.surfaceElevatedLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isDone ? Colors.transparent : AppColors.borderLight,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppColors.primaryNavy : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
