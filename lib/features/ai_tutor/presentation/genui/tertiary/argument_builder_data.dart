import 'package:flutter/material.dart';
import 'package:genui/genui.dart';

class SectionConfig {
  final String label;
  final String key;
  final Color accent;
  const SectionConfig(this.label, this.key, this.accent);
}

const argumentSections = [
  SectionConfig('Claim', 'claim', Color(0xFF2196F3)),
  SectionConfig('Evidence', 'evidence', Color(0xFF4CAF50)),
  SectionConfig('Counter-argument', 'counter', Color(0xFFFF9800)),
  SectionConfig('Rebuttal', 'rebuttal', Color(0xFF009688)),
];

class ArgumentBuilderData {
  final String topic;
  final String position;
  final String claimPrompt;
  final String evidencePrompt;
  final String counterPrompt;
  final String rebuttalPrompt;
  final String actionName;
  final JsonMap actionContext;

  ArgumentBuilderData({
    required this.topic,
    required this.position,
    required this.claimPrompt,
    required this.evidencePrompt,
    required this.counterPrompt,
    required this.rebuttalPrompt,
    required this.actionName,
    required this.actionContext,
  });

  factory ArgumentBuilderData.fromJson(Map<String, Object?> json) {
    final action = json['reviewAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return ArgumentBuilderData(
      topic: (json['topic'] as String?) ?? '',
      position: (json['position'] as String?) ?? '',
      claimPrompt: (json['claim_prompt'] as String?) ?? '',
      evidencePrompt: (json['evidence_prompt'] as String?) ?? '',
      counterPrompt: (json['counter_prompt'] as String?) ?? '',
      rebuttalPrompt: (json['rebuttal_prompt'] as String?) ?? '',
      actionName: (event?['name'] as String?) ?? 'review',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }

  String promptFor(String key) {
    switch (key) {
      case 'claim':
        return claimPrompt;
      case 'evidence':
        return evidencePrompt;
      case 'counter':
        return counterPrompt;
      case 'rebuttal':
        return rebuttalPrompt;
      default:
        return '';
    }
  }
}
