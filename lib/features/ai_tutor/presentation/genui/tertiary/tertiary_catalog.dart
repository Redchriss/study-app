import 'package:genui/genui.dart';
import '../secondary/formula_card.dart';
import 'concept_map.dart';
import 'argument_builder.dart';
import 'code_snippet_card.dart';
import 'research_summary.dart';
import 'debate_card.dart';
import 'progress_ring.dart';

Catalog buildTertiaryCatalog() {
  return BasicCatalogItems.asCatalog().copyWith(
    newItems: [
      conceptMapItem,
      argumentBuilderItem,
      codeSnippetCardItem,
      researchSummaryItem,
      formulaCardItem,
      debateCardItem,
      progressRingItem,
    ],
  );
}
