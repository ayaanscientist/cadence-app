import 'package:drift/drift.dart';

import 'package:cadence/core/database/app_database.dart';
import 'package:cadence/core/database/tables.dart';

part 'founder_dao.g.dart';

/// Data access object for [FounderRecords], [BusinessCanvases], and [BookNotes].
@DriftAccessor(tables: [FounderRecords, BusinessCanvases, BookNotes])
class FounderDao extends DatabaseAccessor<AppDatabase> with _$FounderDaoMixin {
  FounderDao(super.db);

  // ── Founder Records ─────────────────────────────────────────────────────

  Future<FounderRecordEntry?> getRecordByDate(String date) =>
      (select(founderRecords)..where((r) => r.date.equals(date)))
          .getSingleOrNull();

  Stream<FounderRecordEntry?> watchRecordByDate(String date) =>
      (select(founderRecords)..where((r) => r.date.equals(date)))
          .watchSingleOrNull();

  Future<List<FounderRecordEntry>> getAllRecords() =>
      (select(founderRecords)
            ..orderBy([(r) => OrderingTerm.desc(r.date)]))
          .get();

  Future<int> insertRecord(FounderRecordsCompanion entry) =>
      into(founderRecords).insert(entry);

  Future<void> upsertRecord(FounderRecordsCompanion entry) =>
      into(founderRecords).insertOnConflictUpdate(entry);

  Future<bool> updateRecord(FounderRecordEntry entry) =>
      update(founderRecords).replace(entry);

  // ── Business Canvases ───────────────────────────────────────────────────

  Future<List<BusinessCanvasEntry>> getAllCanvases() =>
      (select(businessCanvases)
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
          .get();

  Stream<List<BusinessCanvasEntry>> watchAllCanvases() =>
      (select(businessCanvases)
            ..orderBy([(c) => OrderingTerm.desc(c.createdAt)]))
          .watch();

  Future<BusinessCanvasEntry?> getCanvasById(String id) =>
      (select(businessCanvases)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertCanvas(BusinessCanvasesCompanion entry) =>
      into(businessCanvases).insert(entry);

  Future<bool> updateCanvas(BusinessCanvasEntry entry) =>
      update(businessCanvases).replace(entry);

  Future<int> deleteCanvas(String id) =>
      (delete(businessCanvases)..where((c) => c.id.equals(id))).go();

  // ── Book Notes ──────────────────────────────────────────────────────────

  Future<List<BookNoteEntry>> getAllBookNotes() =>
      (select(bookNotes)..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
          .get();

  Stream<List<BookNoteEntry>> watchAllBookNotes() =>
      (select(bookNotes)..orderBy([(n) => OrderingTerm.desc(n.createdAt)]))
          .watch();

  /// Returns only notes flagged for widget display.
  Future<List<BookNoteEntry>> getWidgetNotes() =>
      (select(bookNotes)..where((n) => n.showInWidget.equals(true))).get();

  Future<int> insertBookNote(BookNotesCompanion entry) =>
      into(bookNotes).insert(entry);

  Future<bool> updateBookNote(BookNoteEntry entry) =>
      update(bookNotes).replace(entry);

  Future<int> deleteBookNote(String id) =>
      (delete(bookNotes)..where((n) => n.id.equals(id))).go();
}
