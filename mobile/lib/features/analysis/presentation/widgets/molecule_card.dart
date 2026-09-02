import 'package:flutter/material.dart';

import '../../../../shared/widgets/safety_badge.dart';
import '../../models/food_analysis_model.dart';

class MoleculeCard extends StatefulWidget {
  final IngredientItem molecule;

  const MoleculeCard({super.key, required this.molecule});

  @override
  State<MoleculeCard> createState() => _MoleculeCardState();
}

class _MoleculeCardState extends State<MoleculeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final molecule = widget.molecule;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      molecule.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  SafetyBadge(safety: _badgeSafety(molecule.category)),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                molecule.simpleExplanation,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                  color: Color(0xFF374151),
                ),
              ),
              if (_isExpanded && molecule.healthNote.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFFF3F4F6), height: 1),
                ),
                Text(
                  molecule.healthNote,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IngredientSafety _badgeSafety(SafetyCategory category) {
    switch (category) {
      case SafetyCategory.safe:
        return IngredientSafety.safe;
      case SafetyCategory.moderate:
        return IngredientSafety.moderate;
      case SafetyCategory.avoid:
        return IngredientSafety.avoid;
    }
  }
}
