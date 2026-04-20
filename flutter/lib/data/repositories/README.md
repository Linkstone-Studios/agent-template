# Repositories

Data access layer for the application.

## Structure

Implement your repository classes here based on your data model.

## Supabase Integration

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:agent_template/data/providers/supabase_provider.dart';

class MyRepository {
  final SupabaseClient _supabase = SupabaseProvider.instance.client;
  
  // Implement your data access methods
}
```

Replace this with your project's actual repository implementations.
