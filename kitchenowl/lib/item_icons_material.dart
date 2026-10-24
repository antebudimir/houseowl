import 'package:material_ui/material_ui.dart';

/// Material icon fallback set for items.
///
/// This is a curated stand-in for additional icons8 font glyphs: items can
/// reference an icon by the key `material:<name>` (see [resolve]) and it
/// renders everywhere `ItemIcons.get` is used. Font entries in the generated
/// `ItemIcons.map` always take precedence; this map only fills the gaps.
/// Keys double as search terms in the icon selection page.
const Map<String, IconData> materialItemIcons = {
  'milk': Icons.local_drink_rounded,
  'water': Icons.water_drop_rounded,
  'coffee': Icons.coffee_rounded,
  'tea': Icons.emoji_food_beverage_rounded,
  'juice': Icons.local_drink_outlined,
  'beer': Icons.sports_bar_rounded,
  'wine': Icons.wine_bar_rounded,
  'bread': Icons.bakery_dining_rounded,
  'cheese': Icons.lunch_dining_rounded,
  'egg': Icons.egg_rounded,
  'fish': Icons.set_meal_rounded,
  'meat': Icons.outdoor_grill_rounded,
  'pasta': Icons.ramen_dining_rounded,
  'rice': Icons.rice_bowl_rounded,
  'soup': Icons.soup_kitchen_rounded,
  'pizza': Icons.local_pizza_rounded,
  'cake': Icons.cake_rounded,
  'ice_cream': Icons.icecream_rounded,
  'candy': Icons.cookie_outlined,
  'fruit': Icons.apple_rounded,
  'vegetable': Icons.grass_rounded,
  'salad': Icons.eco_rounded,
  'spice': Icons.spa_rounded,
  'sugar': Icons.cookie_rounded,
  'snack': Icons.fastfood_rounded,
  'frozen': Icons.ac_unit_rounded,
  'baby': Icons.child_care_rounded,
  'medicine': Icons.medication_rounded,
  'first_aid': Icons.medical_services_rounded,
  'vitamins': Icons.health_and_safety_rounded,
  'soap': Icons.soap_rounded,
  'shampoo': Icons.wash_rounded,
  'cleaning': Icons.cleaning_services_rounded,
  'laundry': Icons.local_laundry_service_rounded,
  'toilet_paper': Icons.undo_rounded,
  'trash_bags': Icons.delete_outline_rounded,
  'dish_soap': Icons.wash_outlined,
  'paper_towels': Icons.layers_rounded,
  'battery': Icons.battery_charging_full_rounded,
  'light_bulb': Icons.lightbulb_rounded,
  'tools': Icons.handyman_rounded,
  'screwdriver': Icons.construction_rounded,
  'paint': Icons.format_paint_rounded,
  'garden': Icons.yard_rounded,
  'plant': Icons.grass_outlined,
  'flower': Icons.local_florist_rounded,
  'pet_food': Icons.pets_rounded,
  'dog': Icons.cruelty_free_rounded,
  'sports': Icons.sports_basketball_rounded,
  'fitness': Icons.fitness_center_rounded,
  'book': Icons.menu_book_rounded,
  'music': Icons.music_note_rounded,
  'games': Icons.sports_esports_rounded,
  'electronics': Icons.devices_other_rounded,
  'phone': Icons.smartphone_rounded,
  'computer': Icons.computer_rounded,
  'gift': Icons.card_giftcard_rounded,
  'clothes': Icons.checkroom_rounded,
  'shoes': Icons.hiking_rounded,
  'umbrella': Icons.beach_access_rounded,
  'keys': Icons.vpn_key_rounded,
  'money': Icons.payments_rounded,
  'car': Icons.directions_car_rounded,
  'bike': Icons.pedal_bike_rounded,
  'camping': Icons.forest_rounded,
  'party': Icons.celebration_rounded,
  'office': Icons.work_rounded,
  'school': Icons.school_rounded,
  'travel': Icons.luggage_rounded,
};

/// Resolves an item icon string to a Material [IconData].
///
/// Returns `null` for anything that is not a `material:<name>` key so the
/// generated font map stays the first and preferred source.
IconData? materialIconByName(String? icon) {
  if (icon == null || !icon.startsWith('material:')) return null;
  return materialItemIcons[icon.substring('material:'.length)];
}
