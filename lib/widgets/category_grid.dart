import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback

// --- CONSTANTS & THEME ---
const Color kPrimaryColor = Color(0xFF6366F1); // Indigo
const Color kSurfaceColor = Color(0xFF1E293B); // Slate 800
const Color kBackgroundColor = Color(0xFF0F172A); // Slate 900
const double kGridSpacing = 16.0;

/// A robust, interactive grid for selecting and managing categories.
/// Includes capabilities to Add/Edit categories via long-press.
class CategoryGrid extends StatefulWidget {
  final String? selectedCategory;
  final Function(String category, bool isEssential, IconData icon, Color color) onSelect;
  final bool allowEditing;

  const CategoryGrid({
    super.key,
    required this.onSelect,
    this.selectedCategory,
    this.allowEditing = true,
  });

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> with SingleTickerProviderStateMixin {
  // --- DEFAULT DATA (Simulated Database) ---
  // In a real app, this would come from the Provider/Database
  final List<Map<String, dynamic>> _categories = [
    {'id': '1', 'name': 'Food', 'icon': Icons.restaurant, 'color': 0xFFEF4444, 'essential': true},
    {'id': '2', 'name': 'Transport', 'icon': Icons.directions_bus, 'color': 0xFFF59E0B, 'essential': true},
    {'id': '3', 'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': 0xFFEC4899, 'essential': false},
    {'id': '4', 'name': 'Fun', 'icon': Icons.gamepad, 'color': 0xFF8B5CF6, 'essential': false},
    {'id': '5', 'name': 'Bills', 'icon': Icons.receipt_long, 'color': 0xFF3B82F6, 'essential': true},
    {'id': '6', 'name': 'Health', 'icon': Icons.medical_services, 'color': 0xFF10B981, 'essential': true},
    {'id': '7', 'name': 'Education', 'icon': Icons.school, 'color': 0xFF6366F1, 'essential': true},
    {'id': '8', 'name': 'Travel', 'icon': Icons.flight, 'color': 0xFF06B6D4, 'essential': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "CATEGORIES",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              if (widget.allowEditing)
                Text(
                  "Long press to edit",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: kGridSpacing,
              crossAxisSpacing: kGridSpacing,
              childAspectRatio: 0.8,
            ),
            itemCount: _categories.length + 1, // +1 for "Add New" button
            itemBuilder: (context, index) {
              // The "Add New" Button
              if (index == _categories.length) {
                return _buildAddButton();
              }

              final cat = _categories[index];
              final isSelected = widget.selectedCategory == cat['name'];

              return _CategoryItem(
                name: cat['name'],
                icon: cat['icon'],
                color: Color(cat['color']),
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onSelect(
                      cat['name'],
                      cat['essential'],
                      cat['icon'],
                      Color(cat['color'])
                  );
                },
                onLongPress: widget.allowEditing
                    ? () => _openCategoryEditor(index)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _openCategoryEditor(null); // null index means create new
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
              child: const Icon(Icons.add, color: Colors.white70, size: 24),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIC: OPEN EDITOR ---
  void _openCategoryEditor(int? index) async {
    final Map<String, dynamic>? existingData = index != null ? _categories[index] : null;

    // Show the editor sheet
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryEditorSheet(initialData: existingData),
    );

    if (result != null) {
      setState(() {
        if (result['delete'] == true && index != null) {
          _categories.removeAt(index);
        } else if (index != null) {
          // Update existing
          _categories[index] = result;
        } else {
          // Create new
          result['id'] = DateTime.now().millisecondsSinceEpoch.toString();
          _categories.add(result);
        }
      });
    }
  }
}

// --- SUB-WIDGET: SINGLE TILE ---

class _CategoryItem extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CategoryItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_CategoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _scaleController.forward().then((_) => _scaleController.reverse());
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;

    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      onLongPress: () {
        HapticFeedback.heavyImpact();
        if (widget.onLongPress != null) widget.onLongPress!();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: widget.isSelected ? color : kSurfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected ? Colors.white : Colors.white.withOpacity(0.05),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected ? Colors.white : color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.isSelected ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SUB-WIDGET: EDITOR SHEET (The Complex Part) ---

class _CategoryEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const _CategoryEditorSheet({this.initialData});

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  late TextEditingController _nameController;
  late IconData _selectedIcon;
  late Color _selectedColor;
  late bool _isEssential;

  // -- PRESET DATA --
  final List<Color> _colors = [
    const Color(0xFFEF4444), const Color(0xFFF97316), const Color(0xFFF59E0B),
    const Color(0xFF84CC16), const Color(0xFF10B981), const Color(0xFF06B6D4),
    const Color(0xFF3B82F6), const Color(0xFF6366F1), const Color(0xFF8B5CF6),
    const Color(0xFFD946EF), const Color(0xFFF43F5E), const Color(0xFF64748B),
  ];

  final List<IconData> _icons = [
    Icons.restaurant, Icons.directions_bus, Icons.shopping_bag, Icons.gamepad,
    Icons.receipt_long, Icons.medical_services, Icons.school, Icons.flight,
    Icons.home, Icons.pets, Icons.fitness_center, Icons.work,
    Icons.local_cafe, Icons.local_bar, Icons.movie, Icons.music_note,
    Icons.phone_android, Icons.wifi, Icons.bolt, Icons.water_drop,
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _nameController = TextEditingController(text: data?['name'] ?? '');
    _selectedIcon = data?['icon'] ?? Icons.category;
    _selectedColor = data != null ? Color(data['color']) : _colors[0];
    _isEssential = data?['essential'] ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header handle
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            widget.initialData == null ? "New Category" : "Edit Category",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),

          // Name Input
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Category Name",
              prefixIcon: Icon(_selectedIcon, color: _selectedColor),
              filled: true,
              fillColor: kSurfaceColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),

          // Essential Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Is Essential?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Needs vs Wants", style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                Switch(
                  value: _isEssential,
                  activeThumbColor: kPrimaryColor,
                  onChanged: (val) => setState(() => _isEssential = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Color Picker
          const Text("Color Code", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final color = _colors[index];
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedColor = color);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10)] : [],
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Icon Picker
          const Text("Icon", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _icons.length,
              itemBuilder: (context, index) {
                final icon = _icons[index];
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIcon = icon);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimaryColor : kSurfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: Colors.white) : null,
                    ),
                    child: Icon(icon, color: isSelected ? Colors.white : Colors.white54),
                  ),
                );
              },
            ),
          ),

          // Action Buttons
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.initialData != null)
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, {'delete': true}),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text("Delete"),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    if (_nameController.text.isEmpty) return;
                    Navigator.pop(context, {
                      'id': widget.initialData?['id'],
                      'name': _nameController.text,
                      'icon': _selectedIcon,
                      'color': _selectedColor.value,
                      'essential': _isEssential,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(widget.initialData == null ? "Create Category" : "Save Changes"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
