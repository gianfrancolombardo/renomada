import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import '../../profile/providers/location_provider.dart';

class ManualLocationSelector extends ConsumerStatefulWidget {
  final VoidCallback onLocationSelected;

  const ManualLocationSelector({
    super.key,
    required this.onLocationSelected,
  });

  @override
  ConsumerState<ManualLocationSelector> createState() => _ManualLocationSelectorState();
}

class _ManualLocationSelectorState extends ConsumerState<ManualLocationSelector> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isSelecting = false;

  // Default suggested cities (vibe with the brand)
  final List<Map<String, dynamic>> _defaultCities = [
    {'display_name': 'Madrid, España', 'lat': '40.4168', 'lon': '-3.7038'},
    {'display_name': 'Barcelona, España', 'lat': '41.3851', 'lon': '2.1734'},
    {'display_name': 'Valencia, España', 'lat': '39.4699', 'lon': '-0.3763'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (query.length > 2) {
        _searchLocations(query);
      } else if (query.isEmpty) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _searchLocations(String query) async {
    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5&accept-language=es',
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'RenomadaApp/1.0', // Required by Nominatim policy
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data.cast<Map<String, dynamic>>();
            _isSearching = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _selectLocation(Map<String, dynamic> location) async {
    setState(() {
      _isSelecting = true;
    });

    try {
      final lat = double.parse(location['lat'].toString());
      final lon = double.parse(location['lon'].toString());

      await ref.read(locationProvider.notifier).setManualLocation(lat, lon);
      
      // Feedback delay
      await Future.delayed(const Duration(milliseconds: 300));
      
      widget.onLocationSelected();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSelecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al seleccionar la ubicación')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultsToShow = _searchController.text.isEmpty && _searchResults.isEmpty 
        ? _defaultCities 
        : _searchResults;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header Image/Icon
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.map,
                size: 40.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 24.h),
            
            Text(
              'Encuentra tu lugar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Dinos dónde estás para mostrarte lo que hay cerca.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),
            
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Busca ciudad, pueblo o código postal...',
                prefixIcon: const Icon(LucideIcons.search),
                suffixIcon: _isSearching 
                    ? Padding(
                        padding: EdgeInsets.all(12.w),
                        child: SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(LucideIcons.x),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Results List
            Expanded(
              child: resultsToShow.isEmpty && _searchController.text.length > 2 && !_isSearching
                  ? _buildNoResults()
                  : _buildResultsList(resultsToShow),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(LucideIcons.searchX, size: 48.sp, color: Theme.of(context).colorScheme.outline),
        SizedBox(height: 16.h),
        Text(
          'No encontramos ese lugar',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildResultsList(List<Map<String, dynamic>> results) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 8.h),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final loc = results[index];
        final name = loc['display_name'] ?? loc['name']; // Fallback for defaults
        
        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: ListTile(
            onTap: _isSelecting ? null : () => _selectLocation(loc),
            leading: Icon(LucideIcons.mapPin, size: 20.sp, color: Theme.of(context).colorScheme.primary),
            title: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.sp),
            ),
            trailing: _isSelecting && _searchController.text.isNotEmpty // Simple check to show loading on right one
                ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.chevronRight, size: 16.sp),
          ),
        );
      },
    );
  }
}
