//
//  TransportHelpers.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation

// MARK: API Status and Result Types:
public enum APIStatus<T> {
    case ok(T, etag: String?)
    case notModified
}

public struct APIResult<T: Decodable> {
    public let status: APIStatus<T>
    
    public init(status: APIStatus<T>) {
        self.status = status
    }
}

// MARK: API Client Protocol:
public protocol APIClient {
    func get<T: Decodable>(_ path: String, headers: [String: String]) async throws -> APIResult<T>
    func put<Body: Encodable, T: Decodable>(_ path: String, body: Body, headers: [String: String]) async throws -> APIResult<T>
    func post<Body: Encodable, T: Decodable>(_ path: String, body: Body, headers: [String: String]) async throws -> APIResult<T>
}

// MARK: HTTP API Client Implementation:
public final class HTTPAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let authTokenProvider: () -> String?
    
    public init(
        baseURL: URL? = nil,
        session: URLSession = .shared,
        authTokenProvider: @escaping () -> String? = { KeychainHelper.get(key: "auth_token") }
    ) {
        // Default to localhost for development, can be overridden via environment variable.
        if let baseURL = baseURL {
            self.baseURL = baseURL
        } else if let envURL = ProcessInfo.processInfo.environment["API_BASE_URL"],
                  let url = URL(string: envURL) {
            self.baseURL = url
        } else {
            // Default to localhost:8000 for local development.
            self.baseURL = URL(string: "http://localhost:8000")!
        }
        self.session = session
        self.authTokenProvider = authTokenProvider
    }
    
    public func get<T: Decodable>(_ path: String, headers: [String: String]) async throws -> APIResult<T> {
        return try await performRequest(method: "GET", path: path, body: nil as Data?, headers: headers)
    }
    
    public func put<Body: Encodable, T: Decodable>(_ path: String, body: Body, headers: [String: String]) async throws -> APIResult<T> {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(body)
        return try await performRequest(method: "PUT", path: path, body: bodyData, headers: headers)
    }
    
    public func post<Body: Encodable, T: Decodable>(_ path: String, body: Body, headers: [String: String]) async throws -> APIResult<T> {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let bodyData = try encoder.encode(body)
        return try await performRequest(method: "POST", path: path, body: bodyData, headers: headers)
    }
    
    private func performRequest<T: Decodable>(
        method: String,
        path: String,
        body: Data?,
        headers: [String: String]
    ) async throws -> APIResult<T> {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw APIError.invalidURL(path)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Adds auth token if available.
        if let token = authTokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Adds custom headers.
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Adds request body if present.
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Handles 304 Not Modified.
        if httpResponse.statusCode == 304 {
            return APIResult<T>(status: .notModified)
        }
        
        // Handles other status codes.
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        // Extracts ETag from response headers.
        let etag = httpResponse.value(forHTTPHeaderField: "ETag")
        
        // Decodes response body.
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(T.self, from: data)
        
        return APIResult<T>(status: .ok(decoded, etag: etag))
    }
}

// MARK: API Errors:
public enum APIError: Error, LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
            case .invalidURL(let path):
                return "Invalid URL: \(path)"
            case .invalidResponse:
                return "Invalid HTTP response"
            case .httpError(let statusCode, let data):
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                return "HTTP error \(statusCode): \(message)"
            case .decodingError(let error):
                return "Decoding error: \(error.localizedDescription)"
        }
    }
}
