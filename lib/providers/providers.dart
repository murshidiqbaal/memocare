import 'connection_providers.dart';

// Export authentication providers
export 'auth_provider.dart';
// Export profile providers
export 'caregiver_profile_provider.dart';
// Export connection providers (linking)
export 'connection_providers.dart';
// Export service providers
export 'service_providers.dart';

// Alias for easier access to specific providers if needed
// (Though direct import is preferred for clarity)
final myPatientsProvider = linkedPatientsProvider;
final myCaregiversProvider = linkedCaregiversProvider;
