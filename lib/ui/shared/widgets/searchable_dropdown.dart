import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';

/// Generic searchable dropdown widget
class SearchableDropdown<T> extends StatelessWidget {
  final String labelText;
  final IconData prefixIcon;
  final T? selectedItem;
  final List<T> items;
  final String Function(T) itemAsString;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool showSearch;
  final String? searchHint;

  const SearchableDropdown({
    super.key,
    required this.labelText,
    required this.prefixIcon,
    required this.selectedItem,
    required this.items,
    required this.itemAsString,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.showSearch = true,
    this.searchHint,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>(
      items: (filter, infiniteScrollProps) => items,
      selectedItem: selectedItem,
      enabled: enabled,
      
      // Popup mode configuration
      popupProps: PopupProps.menu(
        showSearchBox: showSearch && items.length > 5,
        searchDelay: const Duration(milliseconds: 300),
        fit: FlexFit.loose,
        constraints: const BoxConstraints(maxHeight: 400),
        menuProps: MenuProps(
          backgroundColor: Colors.white,
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
        ),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: searchHint ?? 'Search...',
            prefixIcon: const Icon(Icons.search, size: 20),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        itemBuilder: (context, item, isDisabled, isSelected) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Text(
              itemAsString(item),
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          );
        },
        emptyBuilder: (context, searchEntry) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No items found',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      
      // Dropdown decoration
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(prefixIcon),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
          filled: true,
          fillColor: enabled ? Colors.white : AppColors.background,
        ),
      ),
      
      // Item as string
      itemAsString: itemAsString,
      
      // Comparison
      compareFn: (item1, item2) => item1 == item2,
      
      // Filter function for search
      filterFn: (item, filter) {
        if (filter.isEmpty) return true;
        return itemAsString(item)
            .toLowerCase()
            .contains(filter.toLowerCase());
      },
      
      // Callbacks
      onChanged: onChanged,
      
      // Validation
      validator: validator,
    );
  }
}
