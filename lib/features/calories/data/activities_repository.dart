import 'local/activities_local_ds.dart';

class ActivitiesRepository {
  final ActivitiesLocalDs local;
  ActivitiesRepository(this.local);

  Future<double?> getPesoUtenteKg() => local.getPeso();
  Future<void> setPesoUtenteKg(double kg) => local.setPeso(kg);

  Future<Map<String, dynamic>> addAttivitaSelezionataOggi({
    required String nome,
    required String assetPath,
    required int minuti,
    required String durata,
  }) => local.addAttivitaSelezionataOggi(
    nome: nome,
    assetPath: assetPath,
    minuti: minuti,
    durata: durata,
  );

  Future<void> resetAttivitaOggi() => local.resetAttivitaOggi();
}
