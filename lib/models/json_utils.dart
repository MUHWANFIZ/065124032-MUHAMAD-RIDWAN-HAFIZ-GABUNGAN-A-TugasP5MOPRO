int asJsonInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}

String asJsonString(dynamic value, {String fallback = ''}) {
  return value?.toString() ?? fallback;
}
