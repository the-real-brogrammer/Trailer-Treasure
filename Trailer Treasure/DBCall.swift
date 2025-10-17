//
//  DBCall.swift
//  Trailer Treasure
//
//

import Foundation
import CloudKit

struct TrailerEntry: Codable {
    let id: String
    let name: String
    let tally: Int
}

class DBCall {
    static let shared = DBCall()
    private let container = CKContainer(identifier: "iCloud.com.ahoy.Trailer-Treasure.movies")
    private let db = CKContainer(identifier: "iCloud.com.ahoy.Trailer-Treasure.movies").publicCloudDatabase
    
    func addMovie(movie: Movie, trailers: [Movie]) async {
        let query = CKQuery(recordType: "Movie", predicate: NSPredicate(format: "id == %d", movie.id))

        do{
            
            // check if already in db
            let (results, _) = try await db.records(matching: query)
            var exists: CKRecord? = nil
            
            for (_, result) in results {
                if let record = try? result.get() {
                    exists = record
                    break
                }
            }
            
            // if in db, add trailers that don't exist and add 1 to the tally for each trailer that already exists
            if let record = exists {
                let existingTrailers = record["trailers"] as? [String] ?? []
                var trailerDict: [String: (title: String, tally: Int)] = [:]
                
                for trailer in existingTrailers {
                    let parts = trailer.split(separator: "|").map {
                        $0.trimmingCharacters(in: .whitespaces)
                    }
                    if parts.count >= 3, let tally = Int(parts[2]) {
                        trailerDict[parts[0]] = (parts[1], tally)
                    }
                }
                
                for newTrailer in trailers {
                    if let existing = trailerDict["\(newTrailer.id)"] {
                        trailerDict["\(newTrailer.id)"] = (existing.title, existing.tally + 1)
                    } else {
                        trailerDict["\(newTrailer.id)"] = (newTrailer.title, 1)
                    }
                }
                
                record["trailers"] = trailerDict.map { "\($0.key) | \($0.value.title) | \($0.value.tally)" }
                try await db.save(record)
                print("Updated existing movie record for \(movie.title)")
            }
            
            // if not in db, just add movie with each trailer having a tally of 1
            else {
                let entry = CKRecord(recordType: "Movie")
                entry["id"] = movie.id as CKRecordValue
                entry["title"] = movie.title as CKRecordValue
                entry["trailers"] = trailers.map {
                    "\($0.id) | \($0.title)|1"
                }
                
                _ = try await db.save(entry)
                print("Saved record for \(movie.title)")
            }
        } catch {
            print("fail", error)
        }
        
    }
    
    
    // pull all trailers for a given movie
    func getTrailers(for movieID: Int) async -> [String] {
        let query = CKQuery(recordType: "Movie", predicate: NSPredicate(format: "id == %d", movieID))
        do {
            let (matchResults, _) = try await db.records(matching: query)
            for (_, result) in matchResults {
                if let record = try? result.get() {
                    if let trailers = record["trailers"] as? [String] {
                        return trailers
                    }
                }
            }
            return []
            
        } catch {
            print("Error getting trailers: \(error)")
            return []
        }
    }
}
