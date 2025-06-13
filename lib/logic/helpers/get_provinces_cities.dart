import 'package:dio/dio.dart';
import 'package:csv/csv.dart';

class GetProvincesCities 
{
  final Dio _dio = Dio();

  final String csvUrl =
      'https://docs.google.com/spreadsheets/d/e/2PACX-1vQOcnh1xGII37PPC8yNqv6sAkPXtjruONVXGjwU3dt60biMsjOKtSmRbhK1dP338ApkDEOjq3ckJjNm/pub?gid=0&single=true&output=csv';

  Future<List<String>> getCitiesByProvince(String province) async 
  {
    try 
    {
      final response = await _dio.get(csvUrl);

      if (response.statusCode == 200) 
      {
        final csvString = response.data.toString();
        final rows = const CsvToListConverter().convert(csvString);

        // Buscar índices de las columnas
        final headers = rows.first;
        final provinceIndex = headers.indexOf('Provincia');
        final cityIndex = headers.indexOf('Ciudad');

        if (provinceIndex == -1 || cityIndex == -1) 
        {
          throw Exception(
              'Encabezados "Provincia" o "Ciudad" no encontrados en el CSV.');
        }

        // Filtrar por provincia
        final filteredCities = rows
            .skip(1)
            .where((row) =>
                row[provinceIndex].toString().trim().toLowerCase() ==
                province.trim().toLowerCase())
            .map((row) => row[cityIndex].toString())
            .toSet()
            .toList()
          ..sort();

        return filteredCities;
      } 
      else 
      {
        throw Exception(
            'Error al descargar CSV: código ${response.statusCode}');
      }
    } 
    catch (e) 
    {
      print('Error: $e');
      return [];
    }
  }
}
