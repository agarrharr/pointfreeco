import AsyncHTTPClient
import DecodableRequest
import Dependencies
import Either
import Foundation
import FoundationPrelude
import Logging
import Tagged

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

public struct Client {
  /// Fetches an access token from GitHub from a `code` that was obtained from the callback redirect.
  public var fetchAuthToken: (String) async throws -> Either<OAuthError, AccessToken>

  /// Fetches a GitHub user's emails.
  public var fetchEmails: (AccessToken) async throws -> [GitHubUser.Email]

  /// Fetches a GitHub user from an access token.
  public var fetchUser: (AccessToken) async throws -> GitHubUser

  public init(
    fetchAuthToken: @escaping (String) async throws -> Either<OAuthError, AccessToken>,
    fetchEmails: @escaping (AccessToken) async throws -> [GitHubUser.Email],
    fetchUser: @escaping (AccessToken) async throws -> GitHubUser
  ) {
    self.fetchAuthToken = fetchAuthToken
    self.fetchEmails = fetchEmails
    self.fetchUser = fetchUser
  }
}

extension Client {
  public typealias ID = Tagged<(Self, id: ()), String>
  public typealias Secret = Tagged<(Self, secret: ()), String>

  public init(clientId: ID, clientSecret: Secret) {
    @Dependency(\.logger) var logger
    self.init(
      fetchAuthToken: { code in
        return try await jsonDataTask(
          with: fetchGitHubAuthToken(clientId: clientId, clientSecret: clientSecret)(code)
        )
      },
      fetchEmails: { try await runGitHub(logger)(fetchGitHubEmails(token: $0)) },
      fetchUser: { try await runGitHub(logger)(fetchGitHubUser(with: $0)) }
    )
  }
}

func fetchGitHubAuthToken(
  clientId: Client.ID, clientSecret: Client.Secret
)
  -> (String) throws
  -> DecodableHTTPClientRequest<Either<OAuthError, AccessToken>>
{

  return { code in
    var request = HTTPClientRequest(url: "https://github.com/login/oauth/access_token")
    request.method = .POST
    request.headers.add(name: "accept", value: "application/json")
    request.headers.add(name: "content-type", value: "application/json")
    request.body = .bytes(
      .init(
        data: try gitHubJsonEncoder.encode([
          "client_id": clientId.rawValue,
          "client_secret": clientSecret.rawValue,
          "code": code,
          "accept": "json",
        ])
      )
    )
    return DecodableHTTPClientRequest(request)
  }
}

func fetchGitHubEmails(token: AccessToken) -> DecodableRequest<[GitHubUser.Email]> {
  return apiDataTask("user/emails", token: token)
}

internal func fetchGitHubUser(with token: AccessToken) -> DecodableRequest<GitHubUser> {
  return apiDataTask("user", token: token)
}

private func apiDataTask<A>(_ path: String, token: AccessToken) -> DecodableRequest<A> {
  var request = URLRequest(url: URL(string: "https://api.github.com/" + path)!)
  request.addValue("token \(token.accessToken)", forHTTPHeaderField: "Authorization")
  request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
  return DecodableRequest(rawValue: request)
}

private func runGitHub<A>(
  _ logger: Logger?
) -> (DecodableRequest<A>) async throws -> A {
  return { gitHubRequest in
    try await jsonDataTask(with: gitHubRequest.rawValue, decoder: gitHubJsonDecoder)
      .performAsync()
  }
}

private let gitHubJsonEncoder: JSONEncoder = {
  let encoder = JSONEncoder()
  encoder.dateEncodingStrategy = .iso8601
  encoder.outputFormatting = [.sortedKeys]
  return encoder
}()

private let gitHubJsonDecoder: JSONDecoder = {
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .iso8601
  return decoder
}()

extension Client: TestDependencyKey {
  public static let testValue: Client = .failing
}

extension DependencyValues {
  public var gitHub: Client {
    get { self[Client.self] }
    set { self[Client.self] = newValue }
  }
}
