// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cognitoAuthServiceHash() =>
    r'caaf631097d75a6fc2e12ea968667750e71e2541';

/// See also [cognitoAuthService].
@ProviderFor(cognitoAuthService)
final cognitoAuthServiceProvider = Provider<AuthService>.internal(
  cognitoAuthService,
  name: r'cognitoAuthServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cognitoAuthServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CognitoAuthServiceRef = ProviderRef<AuthService>;
String _$apiAuthServiceHash() => r'3e4e48858475b20afca79b7a7bc9bc92bbd463a8';

/// See also [apiAuthService].
@ProviderFor(apiAuthService)
final apiAuthServiceProvider = Provider<ApiAuthService>.internal(
  apiAuthService,
  name: r'apiAuthServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$apiAuthServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ApiAuthServiceRef = ProviderRef<ApiAuthService>;
String _$currentUserHash() => r'd981f841f1820c14297e2a9218a0b1cfc73649c8';

/// See also [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = AutoDisposeProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = AutoDisposeProviderRef<User?>;
String _$isLoggedInHash() => r'f23a32f00d2e98dfa49b2aa789339f360758a5bd';

/// See also [isLoggedIn].
@ProviderFor(isLoggedIn)
final isLoggedInProvider = AutoDisposeProvider<bool>.internal(
  isLoggedIn,
  name: r'isLoggedInProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isLoggedInHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsLoggedInRef = AutoDisposeProviderRef<bool>;
String _$isAdminHash() => r'92521b3654194be0e2936084acc4d0f984480325';

/// See also [isAdmin].
@ProviderFor(isAdmin)
final isAdminProvider = AutoDisposeProvider<bool>.internal(
  isAdmin,
  name: r'isAdminProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isAdminHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsAdminRef = AutoDisposeProviderRef<bool>;
String _$isCommonUserHash() => r'3c654249395938d97b1a3fb8afafd3a8376949a5';

/// See also [isCommonUser].
@ProviderFor(isCommonUser)
final isCommonUserProvider = AutoDisposeProvider<bool>.internal(
  isCommonUser,
  name: r'isCommonUserProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$isCommonUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsCommonUserRef = AutoDisposeProviderRef<bool>;
String _$authNotifierHash() => r'b52445bcc1994f558a73be7ff2e33a622ac37e14';

/// See also [AuthNotifier].
@ProviderFor(AuthNotifier)
final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>.internal(
  AuthNotifier.new,
  name: r'authNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthNotifier = Notifier<AuthState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
