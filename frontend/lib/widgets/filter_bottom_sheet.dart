import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/studio_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _location;
  late double? _maxPrice;
  late bool _availableOnly;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<StudioProvider>();
    _location = provider.locationFilter;
    _maxPrice = provider.maxPriceFilter;
    _availableOnly = provider.availableOnlyFilter;
    _locationController = TextEditingController(text: _location);
  }
  
  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Location Filter
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Enter city or area',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _location = value;
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Max Price Filter
          Text(
            'Maximum Price per Hour',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _maxPrice ?? 5000,
                  min: 1000,
                  max: 5000,
                  divisions: 8,
                  label: _maxPrice != null 
                      ? '₹${_maxPrice!.round()}'
                      : 'No limit',
                  onChanged: (value) {
                    setState(() {
                      _maxPrice = value;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  _maxPrice != null 
                      ? '₹${_maxPrice!.round()}'
                      : 'No limit',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          
          // Remove price limit option
          CheckboxListTile(
            title: const Text('No price limit'),
            value: _maxPrice == null,
            onChanged: (value) {
              setState(() {
                _maxPrice = value == true ? null : 3000;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 10),
          
          // Available Only Filter
          CheckboxListTile(
            title: const Text('Show only available studios'),
            value: _availableOnly,
            onChanged: (value) {
              setState(() {
                _availableOnly = value ?? false;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 20),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
          
          // Add bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  void _applyFilters() {
    final provider = context.read<StudioProvider>();
    
    // Apply all filters at once for better performance
    provider.applyFilters(
      location: _location.trim().isEmpty ? null : _location.trim(),
      maxPrice: _maxPrice,
      availableOnly: _availableOnly,
    );
    
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _location = '';
      _maxPrice = null;
      _availableOnly = false;
      _locationController.clear();
    });
    
    context.read<StudioProvider>().clearFilters();
    Navigator.pop(context);
  }
}
