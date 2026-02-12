import 'package:flutter/material.dart';

/// ════════════════════════════════════════════════════════════════
/// BOATHOUSE INPUT STYLES
/// ════════════════════════════════════════════════════════════════
///
/// Centralized styling for all form inputs across the app.
/// Every widget accepts [primaryColor] so it adapts to team theming.
///
/// Usage:
///   import '../utils/boathouse_styles.dart';
///
///   // Text field:
///   TextFormField(decoration: BoathouseStyles.inputDecoration(primaryColor: primaryColor, hintText: 'Name'))
///
///   // Full widget helpers:
///   BoathouseStyles.textField(primaryColor: primaryColor, controller: _ctrl, hintText: 'Name')
///   BoathouseStyles.dropdown<String>(primaryColor: primaryColor, value: v, items: [...], onChanged: (v) {})
///   BoathouseStyles.sectionLabel('Workout Name')
///
class BoathouseStyles {
  BoathouseStyles._(); // Prevent instantiation

  // ══════════════════════════════════════════════════════════
  // CORE INPUT DECORATION
  // ══════════════════════════════════════════════════════════

  /// The base InputDecoration used by all text fields and dropdowns.
  /// This is the single source of truth for the "Boathouse look."
  static InputDecoration inputDecoration({
    required Color primaryColor,
    String? hintText,
    String? labelText,
    String? suffixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? helperText,
    String? errorText,
    bool isDense = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      suffixText: suffixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      helperText: helperText,
      errorText: errorText,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      isDense: isDense,
      contentPadding: isDense
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TEXT FIELD
  // ══════════════════════════════════════════════════════════

  /// Standard text field with team-color focus ring.
  static Widget textField({
    required Color primaryColor,
    TextEditingController? controller,
    String? hintText,
    String? labelText,
    String? suffixText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: inputDecoration(
        primaryColor: primaryColor,
        hintText: hintText,
        labelText: labelText,
        suffixText: suffixText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }

  /// Number-only text field.
  static Widget numberField({
    required Color primaryColor,
    required TextEditingController controller,
    String? hintText,
    String? suffixText,
    ValueChanged<String>? onChanged,
    FormFieldValidator<String>? validator,
  }) {
    return textField(
      primaryColor: primaryColor,
      controller: controller,
      hintText: hintText,
      suffixText: suffixText,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      validator: validator,
    );
  }

  /// Compact number field for inline use (e.g., min:sec inputs).
  static Widget compactNumberField({
    required Color primaryColor,
    required TextEditingController controller,
    String? hintText,
    String? suffixText,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      decoration: inputDecoration(
        primaryColor: primaryColor,
        hintText: hintText,
        suffixText: suffixText,
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }

  // ══════════════════════════════════════════════════════════
  // TIME INPUT (min : sec)
  // ══════════════════════════════════════════════════════════

  /// Two compact fields with a colon separator for min:sec entry.
  static Widget timeInput({
    required Color primaryColor,
    required TextEditingController minController,
    required TextEditingController secController,
    String minHint = '0',
    String secHint = '00',
    String minSuffix = 'min',
    String secSuffix = 'sec',
    VoidCallback? onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: minController,
            keyboardType: TextInputType.number,
            decoration: inputDecoration(
              primaryColor: primaryColor,
              hintText: minHint,
              suffixText: minSuffix,
            ),
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            ':',
            style: TextStyle(fontSize: 20, color: Colors.grey[500]),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: secController,
            keyboardType: TextInputType.number,
            decoration: inputDecoration(
              primaryColor: primaryColor,
              hintText: secHint,
              suffixText: secSuffix,
            ),
            onChanged: (_) => onChanged?.call(),
          ),
        ),
      ],
    );
  }

  /// Compact min:sec for inline use (e.g., rest times inside cards).
  static Widget compactTimeInput({
    required Color primaryColor,
    required TextEditingController minController,
    required TextEditingController secController,
    VoidCallback? onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: compactNumberField(
            primaryColor: primaryColor,
            controller: minController,
            hintText: '0',
            suffixText: 'm',
            onChanged: (_) => onChanged?.call(),
          ),
        ),
        const SizedBox(width: 4),
        Text(':', style: TextStyle(color: Colors.grey[500])),
        const SizedBox(width: 4),
        SizedBox(
          width: 60,
          child: compactNumberField(
            primaryColor: primaryColor,
            controller: secController,
            hintText: '00',
            suffixText: 's',
            onChanged: (_) => onChanged?.call(),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // DROPDOWN
  // ══════════════════════════════════════════════════════════

  /// Styled dropdown with team-color focus ring.
  static Widget dropdown<T>({
    required Color primaryColor,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    FormFieldValidator<T>? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: inputDecoration(
        primaryColor: primaryColor,
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SECTION LABEL
  // ══════════════════════════════════════════════════════════

  /// Consistent section label above form fields.
  static Widget sectionLabel(String label, {double bottomPadding = 8}) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // TOGGLE CHIP (e.g., Erg Type, Format selectors)
  // ══════════════════════════════════════════════════════════

  /// A selectable chip/button. Use in a Row with Expanded for equal sizing.
  static Widget toggleChip({
    required Color primaryColor,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    bool filled = false, // true = solid bg when selected, false = tinted bg
  }) {
    final onPrimary = primaryColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? (filled ? primaryColor : primaryColor.withOpacity(0.1))
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? primaryColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: selected
                    ? (filled ? onPrimary : primaryColor)
                    : Colors.grey[600],
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? (filled ? onPrimary : primaryColor)
                    : Colors.grey[700],
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Row of equally-spaced toggle chips. Pass labels and the selected index.
  static Widget toggleChipRow({
    required Color primaryColor,
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
    List<IconData?>? icons,
    bool filled = false,
    double spacing = 8,
  }) {
    return Row(
      children: List.generate(labels.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: i < labels.length - 1 ? spacing : 0,
            ),
            child: toggleChip(
              primaryColor: primaryColor,
              label: labels[i],
              selected: i == selectedIndex,
              onTap: () => onSelected(i),
              icon: icons != null && i < icons.length ? icons[i] : null,
              filled: filled,
            ),
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════════════════════
  // SWITCH / TOGGLE
  // ══════════════════════════════════════════════════════════

  /// Styled switch list tile with team color.
  static Widget switchTile({
    required Color primaryColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  /// A card containing multiple switch tiles with dividers.
  static Widget switchCard({
    required Color primaryColor,
    required List<SwitchTileData> switches,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        children: switches.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Column(
            children: [
              switchTile(
                primaryColor: primaryColor,
                title: s.title,
                subtitle: s.subtitle,
                value: s.value,
                onChanged: s.onChanged,
              ),
              if (i < switches.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // CARD WRAPPER
  // ══════════════════════════════════════════════════════════

  /// Standard card with consistent border radius and subtle border.
  static Widget card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    EdgeInsetsGeometry? margin,
  }) {
    return Card(
      elevation: 0,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  // ══════════════════════════════════════════════════════════
  // BUTTONS
  // ══════════════════════════════════════════════════════════

  /// Primary filled button (e.g., "Create Workout", "Save").
  static Widget primaryButton({
    required Color primaryColor,
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    double height = 52,
  }) {
    final onPrimary = primaryColor.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          disabledBackgroundColor: primaryColor.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: onPrimary,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  /// Secondary outlined button (e.g., "Cancel", "Remove").
  static Widget outlinedButton({
    required Color color,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    double height = 48,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon != null
            ? Icon(icon, color: color, size: 20)
            : const SizedBox.shrink(),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// Destructive button (red outline, for delete/remove actions).
  static Widget destructiveButton({
    required String label,
    required VoidCallback? onPressed,
    double height = 48,
  }) {
    return outlinedButton(
      color: Colors.red,
      label: label,
      onPressed: onPressed,
      icon: Icons.delete_outline,
      height: height,
    );
  }

  // ══════════════════════════════════════════════════════════
  // SEARCH FIELD
  // ══════════════════════════════════════════════════════════

  /// Search field with magnifying glass and team-color focus.
  static Widget searchField({
    required Color primaryColor,
    String hintText = 'Search...',
    ValueChanged<String>? onChanged,
    TextEditingController? controller,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: inputDecoration(
        primaryColor: primaryColor,
        hintText: hintText,
        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
        isDense: true,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // DATE/TIME PICKER ROW
  // ══════════════════════════════════════════════════════════

  /// Tappable row showing an icon + text, used for date/time pickers.
  static Widget pickerRow({
    required Color primaryColor,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 20),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

/// Data class for [BoathouseStyles.switchCard].
class SwitchTileData {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SwitchTileData({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });
}
