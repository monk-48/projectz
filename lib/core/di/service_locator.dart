import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/inventory/data/datasources/inventory_remote_datasource.dart';
import '../../features/inventory/data/repositories/inventory_repository_impl.dart';
import '../../features/inventory/domain/repositories/inventory_repository.dart';
import '../../features/storage/data/datasources/storage_remote_datasource.dart';
import '../config/environment.dart';

class ServiceLocator {
  static final ServiceLocator instance = ServiceLocator._internal();
  factory ServiceLocator() => instance;
  ServiceLocator._internal();

  // Core Services
  late final FirebaseAuth _firebaseAuth;
  late final FirebaseFirestore _firestore;
  late final SharedPreferences _sharedPreferences;
  late final SupabaseClient _supabaseClient;

  // Data Sources
  late final AuthRemoteDataSource _authRemoteDataSource;
  late final AuthLocalDataSource _authLocalDataSource;
  late final InventoryRemoteDataSource _inventoryRemoteDataSource;
  late final StorageRemoteDataSource _storageRemoteDataSource;

  // Repositories
  late final AuthRepository _authRepository;
  late final InventoryRepository _inventoryRepository;

  Future<void> init() async {
    // Initialize SharedPreferences
    _sharedPreferences = await SharedPreferences.getInstance();

    // Initialize Firebase
    _firebaseAuth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;

    // Initialize Supabase
    _supabaseClient = Supabase.instance.client;

    // Initialize Data Sources
    _authRemoteDataSource = AuthRemoteDataSourceImpl(
      firebaseAuth: _firebaseAuth,
      firestore: _firestore,
    );
    _authLocalDataSource = AuthLocalDataSourceImpl(
      sharedPreferences: _sharedPreferences,
    );
    _inventoryRemoteDataSource = InventoryRemoteDataSourceImpl(
      firestore: _firestore,
    );
    _storageRemoteDataSource = StorageRemoteDataSourceImpl(
      supabaseClient: _supabaseClient,
    );

    // Initialize Repositories
    _authRepository = AuthRepositoryImpl(
      remoteDataSource: _authRemoteDataSource,
      localDataSource: _authLocalDataSource,
    );
    _inventoryRepository = InventoryRepositoryImpl(
      remoteDataSource: _inventoryRemoteDataSource,
    );
  }

  // Getters
  AuthRepository get authRepository => _authRepository;
  InventoryRepository get inventoryRepository => _inventoryRepository;
  StorageRemoteDataSource get storageRemoteDataSource => _storageRemoteDataSource;
  SharedPreferences get sharedPreferences => _sharedPreferences;
}

