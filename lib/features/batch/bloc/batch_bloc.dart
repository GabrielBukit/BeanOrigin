import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bean_origin/shared/models/batch_model.dart';
import 'package:bean_origin/features/batch/data/batch_repository.dart';

// ─── Events ──────────────────────────────────────────────────
abstract class BatchEvent extends Equatable {
  const BatchEvent();
  @override
  List<Object?> get props => [];
}

class BatchLoadAll extends BatchEvent {}

class BatchSearch extends BatchEvent {
  final String? query;
  final String? variety;
  final String? origin;
  final String? status;
  final double? minScore;
  final double? maxScore;

  const BatchSearch({
    this.query,
    this.variety,
    this.origin,
    this.status,
    this.minScore,
    this.maxScore,
  });

  @override
  List<Object?> get props => [query, variety, origin, status, minScore, maxScore];
}

class BatchAdd extends BatchEvent {
  final BatchModel batch;
  const BatchAdd(this.batch);
  @override
  List<Object?> get props => [batch];
}

class BatchUpdate extends BatchEvent {
  final BatchModel batch;
  const BatchUpdate(this.batch);
  @override
  List<Object?> get props => [batch];
}

class BatchDelete extends BatchEvent {
  final String batchId;
  const BatchDelete(this.batchId);
  @override
  List<Object?> get props => [batchId];
}

// ─── States ──────────────────────────────────────────────────
abstract class BatchState extends Equatable {
  const BatchState();
  @override
  List<Object?> get props => [];
}

class BatchInitial extends BatchState {}

class BatchLoading extends BatchState {}

class BatchLoaded extends BatchState {
  final List<BatchModel> batches;
  final String? activeQuery;
  final String? activeVariety;
  final String? activeOrigin;
  final String? activeStatus;

  const BatchLoaded(
    this.batches, {
    this.activeQuery,
    this.activeVariety,
    this.activeOrigin,
    this.activeStatus,
  });

  @override
  List<Object?> get props => [batches, activeQuery, activeVariety, activeOrigin, activeStatus];
}

class BatchError extends BatchState {
  final String message;
  const BatchError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ────────────────────────────────────────────────────
class BatchBloc extends Bloc<BatchEvent, BatchState> {
  final BatchRepository _repository = BatchRepository();

  BatchBloc() : super(BatchInitial()) {
    on<BatchLoadAll>(_onLoadAll);
    on<BatchSearch>(_onSearch);
    on<BatchAdd>(_onAdd);
    on<BatchUpdate>(_onUpdate);
    on<BatchDelete>(_onDelete);
  }

  Future<void> _onLoadAll(BatchLoadAll event, Emitter<BatchState> emit) async {
    try {
      final batches = _repository.getAllBatches();
      emit(BatchLoaded(batches));
    } catch (e) {
      emit(BatchError('Gagal memuat batch: $e'));
    }
  }

  Future<void> _onSearch(BatchSearch event, Emitter<BatchState> emit) async {
    try {
      final batches = _repository.searchBatches(
        query: event.query,
        variety: event.variety,
        origin: event.origin,
        status: event.status,
        minScore: event.minScore,
        maxScore: event.maxScore,
      );
      emit(BatchLoaded(
        batches,
        activeQuery: event.query,
        activeVariety: event.variety,
        activeOrigin: event.origin,
        activeStatus: event.status,
      ));
    } catch (e) {
      emit(BatchError('Pencarian gagal: $e'));
    }
  }

  Future<void> _onAdd(BatchAdd event, Emitter<BatchState> emit) async {
    _repository.addBatch(event.batch);
    add(BatchLoadAll());
  }

  Future<void> _onUpdate(BatchUpdate event, Emitter<BatchState> emit) async {
    _repository.updateBatch(event.batch);
    add(BatchLoadAll());
  }

  Future<void> _onDelete(BatchDelete event, Emitter<BatchState> emit) async {
    _repository.deleteBatch(event.batchId);
    add(BatchLoadAll());
  }
}
