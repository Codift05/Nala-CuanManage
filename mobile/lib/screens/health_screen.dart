import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../theme/app_theme.dart';
import '../widgets/speedometer_chart.dart';
import '../widgets/trend_line_chart.dart';
import 'nala_chat_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  final HealthService _healthService = HealthService();
  Map<String, dynamic>? _healthData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await _healthService.getHealthScore();
    if (!mounted) return;

    setState(() {
      _healthData = data;
      _isLoading = false;
      _errorMessage =
          data == null ? 'Data kesehatan keuangan belum bisa dimuat.' : null;
    });
  }

  int get _score =>
      ((_healthData?['score'] as num?) ?? 0).round().clamp(0, 100);
  String get _status => (_healthData?['status'] as String?) ?? 'Belum tersedia';

  List<dynamic> get _details {
    final details = _healthData?['details'];
    if (details is List && details.isNotEmpty) return details;
    return const [
      {'label': 'Rasio Tabungan', 'score': 0},
      {'label': 'Kepatuhan Budget', 'score': 0},
      {'label': 'Konsistensi Catat', 'score': 0},
      {'label': 'Diversifikasi', 'score': 0},
    ];
  }

  List<double> get _trendPoints {
    final trend = _healthData?['trend'];
    final normalized = trend is Map ? trend['normalized'] : null;
    if (normalized is List && normalized.isNotEmpty) {
      return normalized
          .map((value) => ((value as num?)?.toDouble() ?? 0).clamp(0.0, 1.0))
          .toList();
    }
    final scores = trend is Map ? trend['scores'] : null;
    if (scores is List && scores.isNotEmpty) {
      return scores
          .map((value) =>
              (((value as num?)?.toDouble() ?? 0) / 100).clamp(0.0, 1.0))
          .toList();
    }
    return const [0, 0, 0];
  }

  List<String> get _trendLabels {
    final trend = _healthData?['trend'];
    final labels = trend is Map ? trend['labels'] : null;
    if (labels is List && labels.isNotEmpty) {
      return labels.map((label) => label.toString()).toList();
    }
    return const ['-', '-', '-'];
  }

  String get _trendMessage {
    final trend = _healthData?['trend'];
    if (trend is Map && trend['message'] is String) {
      return trend['message'] as String;
    }
    return 'Menunggu data bulan ini';
  }

  String get _updatedLabel {
    final rawDate = _healthData?['updatedAt'];
    if (rawDate is! String) return 'Diperbarui saat data tersedia';

    final date = DateTime.tryParse(rawDate)?.toLocal();
    if (date == null) return 'Diperbarui saat data tersedia';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return 'Diperbarui ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _colorForScore(int score) {
    if (score >= 75) return AppTheme.primaryColor;
    if (score >= 55) return const Color(0xFFB45309);
    return AppTheme.secondaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHealthData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                if (_isLoading)
                  _buildLoadingCard()
                else if (_errorMessage != null)
                  _buildErrorCard()
                else ...[
                  _buildSpeedometerCard(),
                  const SizedBox(height: 24),
                  Text(
                    'Faktor kebiasaan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildScoreGrid(),
                  const SizedBox(height: 24),
                  _buildTrendCard(),
                  const SizedBox(height: 24),
                  _buildAdviceButton(context),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary,
            size: 19,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Habit Score',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                _updatedLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 220,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: const CircularProgressIndicator(color: AppTheme.primaryColor),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppTheme.secondaryColor,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadHealthData,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedometerCard() {
    final color = _colorForScore(_score);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: Column(
        children: [
          SpeedometerChart(
            score: _score.toDouble(),
            activeColor: color,
            backgroundColor: const Color(0xFFE2E8FF),
          ),
          const SizedBox(height: 8),
          Text(
            _score.toString(),
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Indikator kebiasaan finansial, bukan penilaian kredit.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreGrid() {
    return Column(
      children: _details.map((item) {
        final score = ((item['score'] as num?) ?? 0).round().clamp(0, 100);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildScoreGridItem(
            item['label']?.toString() ?? '-',
            score,
            _colorForScore(score),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreGridItem(String title, int score, Color barColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                score.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEEF6),
              borderRadius: BorderRadius.circular(3),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth * (score / 100),
                      height: 6,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    return Container(
      height: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAEDF2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tren 3 Bulan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _trendMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: TrendLineChart(
              dataPoints: _trendPoints,
              labels: _trendLabels,
              lineColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NalaChatScreen()),
          );
        },
        icon: const Icon(Icons.chat_bubble_outline,
            color: Colors.white, size: 20),
        label: Text(
          'Diskusikan dengan Nala',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
