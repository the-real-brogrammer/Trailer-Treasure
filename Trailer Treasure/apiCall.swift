//
//  apiCall.swift
//  Trailer Treasure
//
//

import Foundation


class apiCall {
    static let shared = apiCall()
    
    
    func searchMovie(query text: String) async -> [Movie] {
        guard let url = URL(string: "https://api.themoviedb.org/3/search/movie")
        else {
            print("Invalid URL")
            return []
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "query", value: text),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: "1"),
        ]
        components.queryItems = components.queryItems.map { $0 + queryItems } ?? queryItems
        
        let key = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as! String
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        do{
            let (data, _) = try await URLSession.shared.data(for: request)
            let moviesRes = try JSONDecoder().decode(movieJSON.self, from: data)
            return moviesRes.results
            
        }
        catch{
            print("Error: \(error)")
            return []
        }
    }
    
    
    
    func loadVideo(movieID: Int) async -> [Video] {
        guard let b = URL(string: "https://api.themoviedb.org/3/movie/\(movieID)/videos")
        else {
            return []
        }
        var r = URLRequest(url: b)
        
        let key = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as! String
        r.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        r.setValue( "application/json", forHTTPHeaderField: "accept")
        
        do {
            let (data, _) = try await URLSession.shared.data(for: r)
            let res = try JSONDecoder().decode(VideoJSON.self, from: data)
            print(res.results)
            return res.results
            
        }
        catch {
            print("Could not load video: ", error)
            return []
        }
    }
    
    
    func nowPlaying() async -> [Movie] {
        //let url = URL(string: "https://api.themoviedb.org/3/movie/now_playing")!
        let url = URL(string: "https://api.themoviedb.org/3/trending/movie/day?language=en-US")!
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: "1"),
        ]
        components.queryItems = components.queryItems.map { $0 + queryItems } ?? queryItems
        
        let key = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as! String
        
        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "accept")
        
        request.httpMethod = "GET"
        request.timeoutInterval = 10
        
        do{
            let (data, _) = try await URLSession.shared.data(for: request)
            let moviesRes = try JSONDecoder().decode(movieJSON.self, from: data)
            return moviesRes.results
            
        }
        catch{
            print("Error: \(error)")
            return []
        }
    }
}
