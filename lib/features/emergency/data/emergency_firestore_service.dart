import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyRequest {
  final String id;
  final String patientId;
  final String ambulanceId;
  final double ambulanceLat;
  final double ambulanceLng;
  final String status;
  final int eta;

  EmergencyRequest({
    required this.id,
    required this.patientId,
    required this.ambulanceId,
    required this.ambulanceLat,
    required this.ambulanceLng,
    required this.status,
    required this.eta,
  });

  factory EmergencyRequest.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return EmergencyRequest(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      ambulanceId: data['ambulanceId'] ?? '',
      ambulanceLat: (data['ambulanceLat'] ?? 0.0).toDouble(),
      ambulanceLng: (data['ambulanceLng'] ?? 0.0).toDouble(),
      status: data['status'] ?? '',
      eta: data['eta'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'ambulanceId': ambulanceId,
      'ambulanceLat': ambulanceLat,
      'ambulanceLng': ambulanceLng,
      'status': status,
      'eta': eta,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class EmergencyFirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Stream of emergency updates
  Stream<EmergencyRequest> streamEmergency(String emergencyId) {
    try {
      return _db
          .collection('emergencies')
          .doc(emergencyId)
          .snapshots()
          .map((snap) => EmergencyRequest.fromFirestore(snap));
    } catch (e) {
      // Fallback for demo if Firebase is not initialized
      return Stream.value(
        EmergencyRequest(
          id: 'mock',
          patientId: 'patient_1',
          ambulanceId: 'amb_1',
          ambulanceLat: 10.4820,
          ambulanceLng: -66.9050,
          status: 'Ambulancia en camino (Demo)',
          eta: 8,
        ),
      );
    }
  }

  // Update ambulance location (Used by Ambulance Driver App)
  Future<void> updateAmbulanceLocation(
    String emergencyId,
    double lat,
    double lng,
    int eta,
  ) {
    return _db.collection('emergencies').doc(emergencyId).update({
      'ambulanceLat': lat,
      'ambulanceLng': lng,
      'eta': eta,
    });
  }

  // Create new emergency request
  Future<String> createEmergencyRequest(
    String patientId,
    double lat,
    double lng,
  ) async {
    DocumentReference ref = await _db.collection('emergencies').add({
      'patientId': patientId,
      'patientLat': lat,
      'patientLng': lng,
      'status': 'REQUESTED',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }
}
