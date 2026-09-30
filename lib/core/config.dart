/// URL base de la API. Se cambia al compilar:
///   flutter run -d chrome --dart-define=API_URL=http://localhost:8000
/// En el emulador de Android, localhost es 10.0.2.2.
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');
