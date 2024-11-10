class ScanResult {
  late String remoteId;
  late String name;
  ScanResult({required this.remoteId, required this.name});
  ScanResult.fromNative(Map<Object?, Object?> json) {
    remoteId = "${json['remote_id']}";
    name = "${json['name']}";
  }

  @override
  String toString() {
    return "{remoteId: $remoteId, name: $name}";
  }
}
