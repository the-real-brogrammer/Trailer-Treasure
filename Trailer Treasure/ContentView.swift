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
    let title: String
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
    let key: String  // key for link
    let site: String // site video is on
    let name: String // name of trailer
    let id: String   // TMDB id
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
    @State private var isLoadingTrailers: Bool = true
    
    @State private var trailerIDs: [String] = []
    @State private var trailerList: [Movie] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16){
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(movie.poster_path ?? "")")) {
                        img in img.resizable().scaledToFit()
                    } placeholder: {
                        ProgressView()
                    } .frame(width: 100, height: 150)
                    
                    VStack(alignment: .leading) {
                        Text(movie.title)
                            .font(.system(size:24))
                            .bold()
                            
                            //.padding(.top, 10)
                        HStack(){
                            Text(String(movie.release_date.prefix(4)) + "    ")
                                .foregroundColor(.gray)
                                .font(.system(size: 14))
                            //.padding(.top, 1)
                            //Spacer()
                            
                            if let first = videos.first,
                               let trailerUrl = URL(string: "https://www.youtube.com/watch?v=\(first.key)"){
                                Button("Trailer") {
                                    url = trailerUrl
                                    //self.show = true
                                }
                                //.buttonStyle(.borderedProminent)
                                //.padding(.top, 1)
                            }
                        }
                    }
                }
                Text(movie.overview ?? "")
                    .font(.system(size:17))
                    .padding(.top, 4)
                
                Divider()
                
                if isLoadingTrailers == true {
                    ProgressView()
                } else if trailerList.isEmpty {
                    Text("No trailers added yet!")
                        .italic()
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Previews for this movie:")
                            .bold(true)
                            .padding(.vertical, 8)
                        
                        ForEach(trailerList) { preview in
                            NavigationLink(destination: movieDetail(movie: preview)) {
                                HStack(spacing: 12) {
                                    AsyncImage(url: URL(string: "https://image.tmdb.org/t/p/w500\(preview.poster_path ?? "")")) {
                                        image in image.resizable()
                                    } placeholder: { ProgressView() }
                                        .frame(width: 90, height: 135)
                                        .cornerRadius(8)
                                    
                                    VStack(alignment: .leading) {
                                        Text(preview.title)
                                            .font(.system(size: 18))
                                            .foregroundColor(.black)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)
                                        Text("(\(preview.release_date.prefix(4)))")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        
                                    }
                                    
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .imageScale(.small)
                                        .padding(6)
                                }
                            }
                        }
                    }
                }
            }
            
            .padding()
        }
        .sheet(item: $url){ u in
            TrailerSafariView(url: u)
        }
        
        .task{
            await loadVideo()
            await loadTrailers()
        }
    }
    
    
    
    func loadVideo() async {
        await self.videos = apiCall.shared.loadVideo(movieID: movie.id)
    }
    
    func loadTrailers() async {
        let stored = await DBCall.shared.getTrailers(for: movie.id)
        
        //var temp: [Movie] = []
        var parsedTrailers: [(id: Int, title: String, tally: Int)] = []
        
        for t in stored {
            let parts = t.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 3,
               let id = Int(parts[0]),
               let tally = Int(parts[2]) {
                parsedTrailers.append((id, parts[1], tally))
            }
        }
        
        let sortedTrailers = parsedTrailers.sorted {
            $0.tally > $1.tally
        }
        
        var temp: [Movie] = []
        for trailer in sortedTrailers {
            if let movie = await apiCall.shared.searchID(id: trailer.id),
               movie.id != self.movie.id {
                temp.append(movie)
            }
        }
        
        
        trailerList = temp
        isLoadingTrailers = false
        
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
                    print("button pressed")
                    Task {
                        print("made it")
                        //print(chosenMovies)
                        
                        await DBCall.shared.addMovie(movie: movie, trailers: chosenMovies)
                        print("exit")
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









