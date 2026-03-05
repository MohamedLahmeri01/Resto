import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/kds_repository.dart';

class KdsScreen extends ConsumerStatefulWidget {
  const KdsScreen({super.key});

  @override
  ConsumerState<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends ConsumerState<KdsScreen> {
  List<KdsTicket> _tickets = [];
  bool _loading = true;
  String? _station;
  Timer? _refreshTimer;
  Timer? _tickTimer;

  static const stations = ['all', 'hot', 'cold', 'grill', 'bar', 'pastry'];

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadTickets());
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    final repo = ref.read(kdsRepositoryProvider);
    final result = await repo.getTickets(station: _station == 'all' ? null : _station);
    if (result.isSuccess && result.data != null && mounted) {
      setState(() {
        _tickets = result.data!;
        _loading = false;
      });
    }
  }

  Future<void> _bumpItem(String itemId) async {
    final repo = ref.read(kdsRepositoryProvider);
    await repo.bumpItem(itemId);
    await _loadTickets();
  }

  Future<void> _bumpAll(String orderId) async {
    final repo = ref.read(kdsRepositoryProvider);
    await repo.bumpAll(orderId);
    await _loadTickets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kdsBg,
      body: Column(
        children: [
          // Station filter bar
          _buildStationBar(),
          // Tickets grid
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _tickets.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune commande en attente',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 3 : 2;
                          return GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _tickets.length,
                            itemBuilder: (_, i) => _TicketCard(
                              ticket: _tickets[i],
                              onBumpItem: _bumpItem,
                              onBumpAll: () => _bumpAll(_tickets[i].orderId),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationBar() {
    return Container(
      height: 56,
      color: AppColors.kdsHeader,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.kitchen, color: Colors.white),
          const SizedBox(width: 12),
          const Text('KDS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
          ...stations.map((s) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s == 'all' ? 'Tout' : s.toUpperCase()),
              selected: (_station ?? 'all') == s,
              selectedColor: AppColors.kdsUrgent,
              backgroundColor: AppColors.kdsHeader,
              labelStyle: TextStyle(
                color: (_station ?? 'all') == s ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() => _station = s);
                _loadTickets();
              },
            ),
          )),
          const Spacer(),
          Text(
            '${_tickets.length} tickets',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final KdsTicket ticket;
  final Future<void> Function(String) onBumpItem;
  final VoidCallback onBumpAll;

  const _TicketCard({
    required this.ticket,
    required this.onBumpItem,
    required this.onBumpAll,
  });

  Color get _timerColor {
    final mins = ticket.elapsedTime.inMinutes;
    if (mins >= 15) return AppColors.kdsUrgent;
    if (mins >= 8) return AppColors.kdsWarning;
    return AppColors.kdsNormal;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kdsCard,
        borderRadius: BorderRadius.circular(8),
        border: Border(top: BorderSide(color: _timerColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _timerColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${ticket.orderNumber}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    if (ticket.tableNumber != null)
                      Text('Table ${ticket.tableNumber}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _timerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _formatDuration(ticket.elapsedTime),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: ticket.items.length,
              itemBuilder: (_, i) {
                final item = ticket.items[i];
                final isDone = item.status == 'ready' || item.status == 'served';
                return InkWell(
                  onTap: isDone ? null : () => onBumpItem(item.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: isDone ? Colors.green.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${item.quantity}x',
                            style: TextStyle(
                              color: isDone ? Colors.green : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nameFr,
                                style: TextStyle(
                                  color: isDone ? Colors.green : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              if (item.modifiers.isNotEmpty)
                                Text(
                                  item.modifiers.join(', '),
                                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              if (item.notes != null)
                                Text(
                                  '⚠ ${item.notes}',
                                  style: const TextStyle(color: AppColors.kdsWarning, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                        ),
                        if (isDone) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Bump all button
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: onBumpAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kdsNormal,
                foregroundColor: Colors.white,
              ),
              child: const Text('BUMP ALL'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
