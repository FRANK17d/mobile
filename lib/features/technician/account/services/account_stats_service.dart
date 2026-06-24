import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/network/insforge_client.dart';

class TechnicianAccountStats {
  const TechnicianAccountStats({
    this.availableCredits = 0,
    this.paidCreditsBalance = 0,
    this.invoicedCredits = 0,
    this.totalPaid = 0,
    this.participations = 0,
    this.activeParticipations = 0,
    this.wonJobs = 0,
    this.lostJobs = 0,
    this.unlockCreditCost = 0,
    this.freeCredits = 0,
    this.freeCreditsExpiresAt,
  });

  final int availableCredits;
  final int paidCreditsBalance;
  final int invoicedCredits;
  final double totalPaid;
  final int participations;
  final int activeParticipations;
  final int wonJobs;
  final int lostJobs;
  final int unlockCreditCost;
  final int freeCredits;
  final DateTime? freeCreditsExpiresAt;

  TechnicianAccountStats copyWith({
    int? availableCredits,
    int? paidCreditsBalance,
    int? invoicedCredits,
    double? totalPaid,
    int? participations,
    int? activeParticipations,
    int? wonJobs,
    int? lostJobs,
    int? unlockCreditCost,
    int? freeCredits,
    DateTime? freeCreditsExpiresAt,
  }) {
    return TechnicianAccountStats(
      availableCredits: availableCredits ?? this.availableCredits,
      paidCreditsBalance: paidCreditsBalance ?? this.paidCreditsBalance,
      invoicedCredits: invoicedCredits ?? this.invoicedCredits,
      totalPaid: totalPaid ?? this.totalPaid,
      participations: participations ?? this.participations,
      activeParticipations: activeParticipations ?? this.activeParticipations,
      wonJobs: wonJobs ?? this.wonJobs,
      lostJobs: lostJobs ?? this.lostJobs,
      unlockCreditCost: unlockCreditCost ?? this.unlockCreditCost,
      freeCredits: freeCredits ?? this.freeCredits,
      freeCreditsExpiresAt: freeCreditsExpiresAt ?? this.freeCreditsExpiresAt,
    );
  }
}

class TechnicianAccountStatsService {
  final InsForgeClient _client = InsForgeClient();

  Future<TechnicianAccountStats> getStats({
    Map<String, dynamic>? profileData,
  }) async {
    final base = _statsFromProfile(profileData);
    final results = await Future.wait<Object?>([
      _getWalletBalance(),
      _getApplicationStats(),
      _getCreditStats(),
    ]);

    final wallet = results[0] as int?;
    final applications = results[1] as _ApplicationStats?;
    final credits = results[2] as _CreditStats?;

    return base.copyWith(
      availableCredits: wallet ?? base.availableCredits,
      participations: applications?.participations ?? base.participations,
      activeParticipations:
          applications?.activeParticipations ?? base.activeParticipations,
      lostJobs: applications?.lostJobs ?? base.lostJobs,
      unlockCreditCost: applications?.unlockCreditCost ?? base.unlockCreditCost,
      paidCreditsBalance:
          credits?.paidCreditsBalance ?? base.paidCreditsBalance,
      invoicedCredits: credits?.invoicedCredits ?? base.invoicedCredits,
      freeCredits: credits?.freeCredits ?? base.freeCredits,
    );
  }

  TechnicianAccountStats _statsFromProfile(Map<String, dynamic>? profileData) {
    final technician = _asMap(profileData?['technician']);
    final availableCredits = _toInt(
      profileData?['credits'] ??
          profileData?['creditos'] ??
          technician?['credits'] ??
          technician?['creditos'],
    );
    final wonJobs = _toInt(technician?['total_jobs_completed']);
    final freeExpires = _parseDate(
      technician?['free_credits_expires_at'] ??
          technician?['free_credits_expiration'] ??
          profileData?['free_credits_expires_at'],
    );

    return TechnicianAccountStats(
      availableCredits: availableCredits,
      wonJobs: wonJobs,
      freeCredits: _toInt(
        technician?['free_credits'] ?? profileData?['free_credits'],
        availableCredits,
      ),
      freeCreditsExpiresAt: freeExpires,
    );
  }

  Future<int?> _getWalletBalance() async {
    try {
      final technicianId = await _client.getCurrentUserId();
      if (technicianId == null || technicianId.isEmpty) return null;
      final encodedId = Uri.encodeQueryComponent(technicianId);
      final response = await _client.get(
        '/api/database/records/credit_wallets?technician_id=eq.$encodedId&select=balance',
        requireAuth: true,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final data = jsonDecode(response.body) as List<dynamic>;
      if (data.isEmpty) return 0;
      return _toInt((data.first as Map<String, dynamic>)['balance']);
    } catch (e) {
      debugPrint('Exception _getWalletBalance: $e');
      return null;
    }
  }

  Future<_ApplicationStats?> _getApplicationStats() async {
    try {
      final technicianId = await _client.getCurrentUserId();
      if (technicianId == null || technicianId.isEmpty) return null;
      final encodedId = Uri.encodeQueryComponent(technicianId);
      final response = await _client.get(
        '/api/database/records/applications?technician_id=eq.$encodedId&select=id,status,credits_charged,created_at',
        requireAuth: true,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final rows = jsonDecode(response.body) as List<dynamic>;

      var active = 0;
      var lost = 0;
      var unlockCost = 0;
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final status = row['status']?.toString() ?? '';
        if (status == 'pending' || status == 'accepted') active++;
        if (status == 'rejected' || status == 'withdrawn') lost++;
        final charged = _toInt(row['credits_charged']);
        if (charged > unlockCost) unlockCost = charged;
      }

      return _ApplicationStats(
        participations: rows.length,
        activeParticipations: active,
        lostJobs: lost,
        unlockCreditCost: unlockCost,
      );
    } catch (e) {
      debugPrint('Exception _getApplicationStats: $e');
      return null;
    }
  }

  Future<_CreditStats?> _getCreditStats() async {
    try {
      final technicianId = await _client.getCurrentUserId();
      if (technicianId == null || technicianId.isEmpty) return null;
      final encodedId = Uri.encodeQueryComponent(technicianId);
      final response = await _client.get(
        '/api/database/records/credit_transactions?technician_id=eq.$encodedId&select=amount,type,created_at',
        requireAuth: true,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final rows = jsonDecode(response.body) as List<dynamic>;

      var paid = 0;
      var invoiced = 0;
      var free = 0;
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final type = row['type']?.toString() ?? '';
        final amount = _toInt(row['amount']);
        if (amount <= 0) continue;
        if (type == 'purchase') {
          paid += amount;
          invoiced += amount;
        } else if (type == 'bonus' || type == 'admin_adjustment') {
          free += amount;
        }
      }

      return _CreditStats(
        paidCreditsBalance: paid,
        invoicedCredits: invoiced,
        freeCredits: free,
      );
    } catch (e) {
      debugPrint('Exception _getCreditStats: $e');
      return null;
    }
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  int _toInt(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class _ApplicationStats {
  const _ApplicationStats({
    required this.participations,
    required this.activeParticipations,
    required this.lostJobs,
    required this.unlockCreditCost,
  });

  final int participations;
  final int activeParticipations;
  final int lostJobs;
  final int unlockCreditCost;
}

class _CreditStats {
  const _CreditStats({
    required this.paidCreditsBalance,
    required this.invoicedCredits,
    required this.freeCredits,
  });

  final int paidCreditsBalance;
  final int invoicedCredits;
  final int freeCredits;
}
