import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_flutter/core/config/app_config.dart';
import 'package:mobile_flutter/core/constants/app_colors.dart';
import 'package:mobile_flutter/providers/core_providers.dart';
import 'package:mobile_flutter/providers/route_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _openApiConfigDialog() {
    final prefs = ref.read(preferencesServiceProvider);
    final currentCustomUrl = prefs.getApiBaseUrl() ?? AppConfig.defaultBaseUrl;
    final controller = TextEditingController(text: currentCustomUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings_ethernet_rounded, color: AppColors.accentTeal),
            SizedBox(width: 8),
            Text('Network API Host', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure the Spring Boot REST API address for development or device testing:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'API Base URL',
                hintText: 'http://10.0.2.2:8080/api or http://192.168.x.x:8080/api',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Emulator (10.0.2.2)'),
                  onPressed: () => controller.text = 'http://10.0.2.2:8080/api',
                ),
                ActionChip(
                  label: const Text('Localhost'),
                  onPressed: () => controller.text = 'http://localhost:8080/api',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.clearApiBaseUrl();
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
              ref.invalidate(apiClientProvider);
              ref.invalidate(routesListProvider);
            },
            child: const Text('Reset Default'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await prefs.setApiBaseUrl(newUrl);
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
                ref.invalidate(apiClientProvider);
                ref.invalidate(routesListProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('API URL updated to: $newUrl')),
                  );
                }
              }
            },
            child: const Text('Save & Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesServiceProvider);
    final currentApiUrl = prefs.getApiBaseUrl() ?? AppConfig.defaultBaseUrl;
    final favourites = ref.watch(favouritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card (Guest Mode)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryNavy,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TransitGo Traveler',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.verified_user_outlined, size: 14, color: AppColors.accentTeal),
                            SizedBox(width: 4),
                            Text(
                              'Guest Mode · Local Persistence',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Preferences & Travel Data Section
          const Text('Travel Data', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.star_rounded, color: AppColors.accentAmber),
                  title: const Text('Saved Favourite Routes'),
                  subtitle: Text('${favourites.length} saved routes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/routes'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history_rounded, color: AppColors.accentTeal),
                  title: const Text('Recent Journey Searches'),
                  subtitle: const Text('Clear search history'),
                  trailing: TextButton(
                    onPressed: () {
                      ref.read(recentSearchesProvider.notifier).clearAll();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search history cleared')),
                      );
                    },
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.confirmation_num_outlined, color: AppColors.primaryNavy),
                  title: const Text('My Digital Bookings'),
                  subtitle: const Text('View ticket history & QR codes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/tickets'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Development & Network Configuration
          const Text('Network & Server Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dns_rounded, color: AppColors.info),
                  title: const Text('Backend API Host'),
                  subtitle: Text(
                    currentApiUrl,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 20),
                  onTap: _openApiConfigDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.campaign_outlined, color: AppColors.warning),
                  title: const Text('Service Notices & Helplines'),
                  subtitle: const Text('Official TMT announcements'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notices'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // TMT Transport Dataset Provenance & Limitations
          const Text('Dataset Provenance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondaryLight)),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.directions_bus_rounded, color: AppColors.primaryNavy, size: 20),
                      SizedBox(width: 8),
                      Text('Thane Municipal Transport (TMT)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '• Verified Routes: 436 active TMT bus services\n'
                    '• Bus Stops: 3,286 stops in Thane municipal zone\n'
                    '• Stop Sequences: 4,394 verified sequence records\n'
                    '• Route Paths: Rendered from verified GTFS stop coordinates (shapes.txt omitted in source feed)\n'
                    '• Telemetry Engine: Schedule-based simulation mode\n'
                    '• Tickets: Digital prototype with server verification',
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Center(
            child: Text(
              'TransitGo v1.0.0 · Flutter Android\nThane Municipal Transport Corporation Prototype',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textMutedLight, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
