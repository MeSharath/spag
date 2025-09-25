import 'package:flutter/material.dart';
import '../models/studio.dart';
import '../services/api_service.dart';

class StudioProvider with ChangeNotifier {
  List<Studio> _studios = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _locationFilter = '';
  double? _maxPriceFilter;
  bool _availableOnlyFilter = false;

  // Getters
  List<Studio> get studios => _studios;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get locationFilter => _locationFilter;
  double? get maxPriceFilter => _maxPriceFilter;
  bool get availableOnlyFilter => _availableOnlyFilter;

  // Load studios with current filters
  Future<void> loadStudios() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _studios = await ApiService.getStudios(
        location: _locationFilter.isNotEmpty ? _locationFilter : null,
        maxPrice: _maxPriceFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        availableOnly: _availableOnlyFilter,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _studios = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search studios
  Future<void> searchStudios(String query) async {
    _searchQuery = query;
    await loadStudios();
  }

  // Filter by location
  Future<void> filterByLocation(String location) async {
    _locationFilter = location;
    await loadStudios();
  }

  // Filter by max price
  Future<void> filterByMaxPrice(double? maxPrice) async {
    _maxPriceFilter = maxPrice;
    await loadStudios();
  }

  // Filter by availability
  Future<void> filterByAvailability(bool availableOnly) async {
    _availableOnlyFilter = availableOnly;
    await loadStudios();
  }

  // Apply multiple filters at once
  Future<void> applyFilters({
    String? location,
    double? maxPrice,
    bool availableOnly = false,
  }) async {
    _locationFilter = location ?? '';
    _maxPriceFilter = maxPrice;
    _availableOnlyFilter = availableOnly;
    await loadStudios();
  }

  // Clear all filters
  Future<void> clearFilters() async {
    _searchQuery = '';
    _locationFilter = '';
    _maxPriceFilter = null;
    _availableOnlyFilter = false;
    await loadStudios();
  }

  // Get studio by ID
  Future<Studio?> getStudioById(int id) async {
    try {
      return await ApiService.getStudioById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Check API health
  Future<bool> checkApiHealth() async {
    return await ApiService.checkHealth();
  }

  // Refresh studios
  Future<void> refresh() async {
    await loadStudios();
  }
}
