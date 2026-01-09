import 'package:flutter/material.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/enums/ticket_status.dart';
import 'package:intl/intl.dart';

class CustomerFilterScreen extends StatefulWidget {
  final String? initialStatus;
  final String? initialStartDate;
  final String? initialEndDate;
  final String? initialSearch;

  const CustomerFilterScreen({
    super.key,
    this.initialStatus,
    this.initialStartDate,
    this.initialEndDate,
    this.initialSearch,
  });

  @override
  State<CustomerFilterScreen> createState() => _CustomerFilterScreenState();
}

class _CustomerFilterScreenState extends State<CustomerFilterScreen> {
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _searchController.text = widget.initialSearch ?? '';
    
    if (widget.initialStartDate != null) {
      try {
        _startDate = DateTime.parse(widget.initialStartDate!);
      } catch (e) {
        // Invalid date
      }
    }
    
    if (widget.initialEndDate != null) {
      try {
        _endDate = DateTime.parse(widget.initialEndDate!);
      } catch (e) {
        // Invalid date
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _applyFilters() {
    final result = <String, String?>{
      'status': _selectedStatus,
      'startDate': _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null,
      'endDate': _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null,
      'search': _searchController.text.isNotEmpty
          ? _searchController.text
          : null,
    };

    Navigator.pop(context, result);
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Tickets'),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Field
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Search tickets...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),

            // Status Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Status'),
                ),
                ...TicketStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status.value,
                    child: Text(status.displayName),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Start Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(
                _startDate != null
                    ? DateFormat('dd MMM yyyy').format(_startDate!)
                    : 'Not selected',
              ),
              trailing: _startDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                        });
                      },
                    )
                  : null,
              onTap: _selectStartDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.border),
              ),
            ),
            const SizedBox(height: 16),

            // End Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('End Date'),
              subtitle: Text(
                _endDate != null
                    ? DateFormat('dd MMM yyyy').format(_endDate!)
                    : 'Not selected',
              ),
              trailing: _endDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _endDate = null;
                        });
                      },
                    )
                  : null,
              onTap: _selectEndDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.border),
              ),
            ),
            const SizedBox(height: 32),

            // Apply Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
