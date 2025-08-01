import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:sky_trade/core/errors/exceptions/search_autocomplete_exception.dart';
import 'package:sky_trade/core/resources/strings/networking.dart'
    show accessTokenKey, qKey, retrievePath, sessionTokenKey, suggestPath;
import 'package:sky_trade/core/resources/strings/secret_keys.dart'
    show mapboxMapsPublicKey, mapboxMapsSearchBoxBaseUrl;
import 'package:sky_trade/core/resources/strings/special_characters.dart'
    show forwardSlash;
import 'package:sky_trade/core/utils/clients/network_client.dart'
    show HttpClient;
import 'package:sky_trade/core/utils/clients/response_handler.dart';
import 'package:sky_trade/core/utils/enums/networking.dart' show RequestMethod;
import 'package:sky_trade/features/search_autocomplete/data/data_sources/search_autocomplete_local_data_source.dart'
    show SearchAutocompleteLocalDataSource;
import 'package:sky_trade/features/search_autocomplete/data/models/search_result_model.dart'
    show RetrieveResultModel, SearchResultModel;

abstract interface class SearchAutocompleteRemoteDataSource {
  Future<SearchResultModel> autocompleteSearchUsing({
    required String query,
  });

  Future<RetrieveResultModel> retrieveGeometricCoordinatesFor({
    required String id,
  });
}

final class SearchAutocompleteRemoteDataSourceImplementation
    with ResponseHandler
    implements SearchAutocompleteRemoteDataSource {
  const SearchAutocompleteRemoteDataSourceImplementation({
    required HttpClient httpClient,
    required SearchAutocompleteLocalDataSource
        searchAutocompleteLocalDataSource,
  })  : _httpClient = httpClient,
        _searchAutocompleteLocalDataSource = searchAutocompleteLocalDataSource;

  final HttpClient _httpClient;

  final SearchAutocompleteLocalDataSource _searchAutocompleteLocalDataSource;

  @override
  Future<SearchResultModel> autocompleteSearchUsing({
    required String query,
  }) async =>
      handleResponse<SearchAutocompleteException, Map<String, dynamic>,
          SearchResultModel>(
        requestInitiator: _httpClient.request(
          overrideBaseUrl: dotenv.env[mapboxMapsSearchBoxBaseUrl],
          requestMethod: RequestMethod.get,
          path: suggestPath,
          includeSignature: false,
          queryParameters: {
            qKey: query,
            accessTokenKey: dotenv.env[mapboxMapsPublicKey],
            sessionTokenKey:
                await _searchAutocompleteLocalDataSource.sessionToken,
          },
        ),
        onSuccess: SearchResultModel.fromJson,
        onError: (_) => SearchAutocompleteException(),
      );

  @override
  Future<RetrieveResultModel> retrieveGeometricCoordinatesFor({
    required String id,
  }) async =>
      handleResponse<RetrieveGeometricCoordinatesException,
          Map<String, dynamic>, RetrieveResultModel>(
        requestInitiator: _httpClient.request(
          overrideBaseUrl: dotenv.env[mapboxMapsSearchBoxBaseUrl],
          requestMethod: RequestMethod.get,
          path: retrievePath + forwardSlash + id,
          includeSignature: false,
          queryParameters: {
            accessTokenKey: dotenv.env[mapboxMapsPublicKey],
            sessionTokenKey:
                await _searchAutocompleteLocalDataSource.sessionToken,
          },
        ),
        onSuccess: RetrieveResultModel.fromJson,
        onError: (_) => RetrieveGeometricCoordinatesException(),
      );
}
