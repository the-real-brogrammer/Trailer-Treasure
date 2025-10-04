//
//  ContentView.swift
//  Trailer Treasure
//

import SwiftUI
import CoreData
import Foundation
import SafariServices



// Store movie info
struct Movie: Codable, Identifiable {
    let id: Int
    var title: String
    let overview: String?
    let release_date: String
    let poster_path: String?
}


// Hold list of decoded movies
struct movieJSON: Codable {
    let results: [Movie]
}


// Hold list of decoded trailers
struct VideoJSON: Codable {
    let results: [Video]
}


// Store trailer info
struct Video: Codable {
    let key: String
    let site: String
    let name: String
    let id: String
}


// URL extension for TrailerSafariView
extension URL: Identifiable {
    public var id: URL {
        self
    }
}


// For embedded youtube trailers
struct TrailerSafariView: UIViewControllerRepresentable {
    typealias UIViewControllerType = SFSafariViewController
    
    var url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        
    }
}



struct ContentView: View {
    var body: some View{
        TabView {
            // Homepage (TODO: have in theaters and upcoming movies tabs), add following list
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            // Add trailers page
            NavigationStack {
                AddView()
            }
            .tabItem {
                Label("Add Trailers", systemImage: "plus.app")
            }
            // Search movies page
            NavigationStack {
                SearchView()
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
        }
    }
}



struct SearchView: View {
    @State private var searchText: String = ""
    @State private var movies: [Movie] = []
    
    var body: some View {
        // Print list of movies
        List(movies) { movie in
            NavigationLink(destination: movieDetail(movie: movie)){
                
                HStack() {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.poster_path ?? "")")){
                        image in image.resizable()
                    }
                    placeholder: {
                        ProgressView()
                    }
                    .frame(width: 100, height:150)
                    VStack(){
                        Text(movie.title)
                            .font(.system(size:24)) +
                        Text(" (\(movie.release_date.prefix(4)))")
                            .font(.system(size:12))
                    }
                }
            }
        }
        .navigationTitle("Movies")
        
        .searchable(text: $searchText)
        .onSubmit(of: .search) {
            Task {
                await searchMovie(query: searchText)
            }
        }
    }
    func searchMovie(query text: String) async{
        await self.movies = apiCall.shared.searchMovie(query: text)
    }
}



struct AddView: View {
    @State private var searchText: String = ""
    @State private var movies: [Movie] = []
    
    var body: some View {
        // Print list of movies
        List(movies) { movie in
            NavigationLink(destination: movieEdit(movie: movie)){
                HStack() {
                    
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.poster_path ?? "")")){
                        image in image.resizable()
                    }
                    placeholder: {
                        ProgressView()
                    }
                    .frame(width: 100, height:150)
                    VStack(){
                        Text(movie.title)
                            .font(.system(size:24)) +
                        Text(" (\(movie.release_date.prefix(4)))")
                            .font(.system(size:12))
                    }
                }
            }
        }
        .navigationTitle("Add Trailer")
        
        .searchable(text: $searchText)
        .onSubmit(of: .search) {
            Task {
                await searchMovie(query: searchText)
            }
        }
    }
    func searchMovie(query text: String) async{
        await self.movies = apiCall.shared.searchMovie(query: text)
    }
}



struct movieDetail: View {
    let movie: Movie
    @Environment(\.presentationMode) var presentationMode
    @State private var videos: [Video] = []
    @State private var url: URL?
    @State private var show = false
    
    var body: some View {
        List {
            VStack(){
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.poster_path ?? "")")) {
                        img in img.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    } .frame(width: 100, height: 150)
                    
                    VStack(alignment: .leading) {
                        Text(movie.title)
                            .font(.system(size:24))
                        HStack(){
                            Text(String(movie.release_date.prefix(4)) + "    ")
                            //Spacer()
                            
                            if let first = videos.first,
                               let trailerUrl = URL(string: "https://www.youtube.com/watch?v=\(first.key)"){
                                Button("Trailer") {
                                    self.url = trailerUrl
                                    self.show = true
                                }
                            }
                        }
                    }
                }
                Text(movie.overview ?? "")
                    .font(.system(size:17))
            }
        }
        .sheet(item: $url){ u in
            TrailerSafariView(url: u)
        }
        /*
        .sheet(isPresented: $show) {
            if let url = url {
                TrailerSafariView(url: url)
            }
        }
         */
        .task{
            await self.loadVideo()
        }
    }
    
    func loadVideo() async {
        
        await self.videos = apiCall.shared.loadVideo(movieID: movie.id)
    }
}



struct movieEdit: View {
    @State private var searchText: String = ""
    @State private var movies: [Movie] = []
    @State private var chosenMovies: [Movie] = []
    let movie: Movie
    @Environment(\.presentationMode) var presentationMode
    @State private var videos: [Video] = []
    @State private var url: URL?
    @State private var show = false
    @State private var viewID = UUID()
    
    var body: some View {
        VStack{
            List {
                Section{
                    VStack(){
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.poster_path ?? "")")) {
                                img in img.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            } .frame(width: 100, height:  150)
                            //.clipShape(Circle())
                            
                            VStack(alignment: .leading) {
                                Text(movie.title)
                                    .font(.system(size:24))
                                HStack(){
                                    Text(String(movie.release_date.prefix(4)) + "    ")
                                    
                                    if let first = videos.first,
                                       let trailerUrl = URL(string: "https://www.youtube.com/watch?v=\(first.key)"){
                                        Button("Trailer") {
                                            self.url = trailerUrl
                                            self.show = true
                                        }
                                    }
                                }
                            }
                        }
                        Text(movie.overview ?? "")
                            .font(.system(size:17))
                    }
                }
                
                Section{
                    ForEach(chosenMovies) { m in
                        HStack() {
                            
                            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(m.poster_path ?? "")")){
                                image in image.resizable()
                            }
                            placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height:150)
                            VStack(){
                                Text(m.title)
                                    .font(.system(size:24)) +
                                Text(" (\(m.release_date.prefix(4)))")
                                    .font(.system(size:12))
                            }
                        }
                    }
                }
                
                Section{
                    TextField("Search trailers...", text:$searchText)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel (.search)
                        .padding(CGFloat.init(10))
                        .onSubmit {
                            Task { await searchMovie(query: searchText)}
                        }
                    
                    ForEach(movies) { m in
                        HStack() {
                            
                            AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(m.poster_path ?? "")")){
                                image in image.resizable()
                            }
                            placeholder: {
                                ProgressView()
                            }
                            .frame(width: 100, height:150)
                            VStack(){
                                Text(m.title)
                                    .font(.system(size:24)) +
                                Text(" (\(m.release_date.prefix(4)))")
                                    .font(.system(size:12))
                            }
                        }
                        .onTapGesture{
                            withAnimation{
                                chosenMovies.append(m)
                                movies = []
                                searchText = ""
                            }
                        }
                    }
                }
                
                Button("Submit"){
                    Task {
                        print(chosenMovies)
                    }
                    
                }
            }
        }
        .id(viewID)
        .navigationTitle(movie.title)
        
        .sheet(item: $url){ u in
            TrailerSafariView(url: u)
        }
        
        /*
         .sheet(isPresented: $show) {
         if let url = url {
         
         TrailerSafariView(url: url)
         }
         }
         */
        .task {
            await loadVideo()
        }
    }
    
    func searchMovie(query text: String) async{
        await self.movies = apiCall.shared.searchMovie(query: text)
    }
    
    func loadVideo() async {
        await self.videos = apiCall.shared.loadVideo(movieID: movie.id)
    }
}



struct HomeView: View {
    @State private var movies: [Movie] = []
    var body: some View {
        
        NavigationStack {
            // Print list of movies
            List(movies) { movie in
                NavigationLink(destination: movieDetail(movie: movie)){
                    HStack {
                        
                        AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.poster_path ?? "")")){
                            image in image.resizable()
                        }
                        placeholder: {
                            ProgressView()
                        }
                        .frame(width: 100, height:150)
                        VStack(){
                            Text(movie.title)
                                .font(.system(size:24)) +
                            Text(" (\(movie.release_date.prefix(4)))")
                                .font(.system(size:12))
                        }
                    }
                }
            }
            .navigationTitle("In Theaters")
            .task{
                await nowPlaying()
            }
        }
        
    }
    
    
    func nowPlaying() async{
        await self.movies = apiCall.shared.nowPlaying()
    }
}



#Preview {
    ContentView()
}
