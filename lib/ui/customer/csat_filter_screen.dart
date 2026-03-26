import 'package:flutter/material.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:intl/intl.dart';

class CustomerCsatFilterScreen extends StatefulWidget {
  final String? initialTicketStatus;
  final String? initialStartDate;
  final String? initialEndDate;
  final String? initialSearch;

  const CustomerCsatFilterScreen({
    super.key,
    this.initialTicketStatus,
    this.initialStartDate,
    this.initialEndDate,
    this.initialSearch,
  });

  @override
  State<CustomerCsatFilterScreen> createState() =>
      _CustomerCsatFilterScreenState();
}

class _CustomerCsatFilterScreenState extends State<CustomerCsatFilterScreen> {
  String? _selectedTicketStatus;
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTicketStatus = widget.initialTicketStatus;
    _searchController.text = widget.initialSearch ?? '';

    if (widget.initialStartDate != null) {
      _startDate = DateTime.tryParse(widget.initialStartDate!);
    }
    if (widget.initialEndDate != null) {
      _endDate = DateTime.tryParse(widget.initialEndDate!);
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
    Navigator.pop(context, <String, String?>{
      'ticketStatus': _selectedTicketStatus,
      'startDate': _startDate != null
          ? DateFormat('yyyy-MM-dd').format(_startDate!)
          : null,
      'endDate': _endDate != null
          ? DateFormat('yyyy-MM-dd').format(_endDate!)
          : null,
      'search': _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedTicketStatus = null;
      _startDate = null;
      _endDate = null;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter CSAT'),
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
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Search by ticket id or subject',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedTicketStatus,
              decoration: const InputDecoration(
                labelText: 'Ticket Status',
                prefixIcon: Icon(Icons.confirmation_num_outlined),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Status')),
                DropdownMenuItem(value: 'Closed', child: Text('Closed')),
                DropdownMenuItem(value: 'Solved', child: Text('Solved')),
                DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTicketStatus = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(
                _startDate == null
                    ? 'Not selected'
                    : DateFormat('dd MMM yyyy').format(_startDate!),
              ),
              trailing: _startDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                        });
                      },
                    ),
              onTap: _selectStartDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.border),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('End Date'),
              subtitle: Text(
                _endDate == null
                    ? 'Not selected'
                    : DateFormat('dd MMM yyyy').format(_endDate!),
              ),
              trailing: _endDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _endDate = null;
                        });
                      },
                    ),
              onTap: _selectEndDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppColors.border),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
