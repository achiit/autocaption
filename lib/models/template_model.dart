class TemplateModel {
  final String id;
  final String name;
  final String description;

  TemplateModel({
    required this.id,
    required this.name,
    required this.description,
  });

  static final Map<String, TemplateModel> templates = {
    'classic': TemplateModel(
      id: 'classic',
      name: 'Classic',
      description: 'Yellow highlights, dark background',
    ),
    'neon': TemplateModel(
      id: 'neon',
      name: 'Neon Glow',
      description: 'Cyan glow effect, futuristic',
    ),
    'bold': TemplateModel(
      id: 'bold',
      name: 'Bold Pop',
      description: 'Red highlights, bold stroke',
    ),
    'minimal': TemplateModel(
      id: 'minimal',
      name: 'Minimal Clean',
      description: 'Clean white background',
    ),
    'gradient': TemplateModel(
      id: 'gradient',
      name: 'Gradient Style',
      description: 'Purple gradient, gold accents',
    ),
  };

  static List<TemplateModel> get all => templates.values.toList();

  static TemplateModel? getById(String id) => templates[id];
}
