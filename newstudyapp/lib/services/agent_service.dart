import 'package:newstudyapp/models/agent_models.dart';
import 'package:newstudyapp/services/api_client.dart';
import 'package:newstudyapp/config/api_config.dart';

class AgentService {
  AgentService({
    required String baseUrl,
    ApiClient? apiClient,
  })  : _baseUrl = baseUrl,
        _apiClient = apiClient ?? ApiClient();

  final String _baseUrl;
  final ApiClient _apiClient;

  Future<AgentResponse> runCuriousStudent(String text) async {
    final uri = Uri.parse('$_baseUrl${ApiConfig.curiousStudent}');
    final json = await _apiClient.postJson(uri, body: {'text': text});
    return AgentResponse.fromJson(json);
  }

  Future<AgentResponse> runSimpleExplainer(String text) async {
    final uri = Uri.parse('$_baseUrl${ApiConfig.simpleExplainer}');
    final json = await _apiClient.postJson(uri, body: {'text': text});
    return AgentResponse.fromJson(json);
  }

  Future<TermsResponse> fetchTerms({String category = 'economics'}) async {
    final uri = Uri.parse('$_baseUrl${ApiConfig.fetchTerms}').replace(queryParameters: {'category': category});
    final json = await _apiClient.getJson(uri);
    return TermsResponse.fromJson(json);
  }

  void dispose() {
    _apiClient.dispose();
  }
}

