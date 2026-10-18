class RundownHelper {
  /// Sample rundown per event — used until organizers can edit schedules in-app.
  static List<Map<String, String>> rundownFor(String eventId) {
    switch (eventId) {
      case 'konser1':
        return const [
          {'waktu': '18:00', 'item': 'Gate Open'},
          {'waktu': '19:00', 'item': 'Opening Act'},
          {'waktu': '20:00', 'item': 'Hindia — Main Set'},
          {'waktu': '22:00', 'item': 'Encore'},
        ];
      case 'konser2':
        return const [
          {'waktu': '18:30', 'item': 'Doors Open'},
          {'waktu': '19:30', 'item': 'Nadin Amizah'},
          {'waktu': '21:30', 'item': 'Closing'},
        ];
      default:
        return const [
          {'waktu': '18:00', 'item': 'Gate Open'},
          {'waktu': '19:00', 'item': 'Opening'},
          {'waktu': '20:00', 'item': 'Main Act'},
          {'waktu': '22:00', 'item': 'End'},
        ];
    }
  }
}
