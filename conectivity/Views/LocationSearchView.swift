//
//  LocationSearchView.swift
//  conectivity
//

//  Created by Dilip on 2024-10-17.
//


import SwiftUI

struct LocationSearchView: View {
    @Binding var selectedLocation: String?
    @State private var searchText: String = ""
    @State private var places: [String] = []
    
    // Access the presentation mode environment value
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for a location", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: searchText) { newValue in
                        if !newValue.isEmpty {
                            fetchPlaces(query: newValue)
                        } else {
                            places = []
                        }
                    }

                List(places, id: \.self) { place in
                    Button(action: {
                        selectedLocation = place
                        presentationMode.wrappedValue.dismiss() // Dismiss the view
                    }) {
                        Text(place)
                    }
                }
            }
            .navigationBarTitle("Location Search")
        }
    }

    func fetchPlaces(query: String) {
        let apiKey = "AIzaSyCjElsVqyTBv23vxQWkOy2s3RcclGtQeWA" // Replace with your Google Places API key
        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&key=\(apiKey)"

        guard let url = URL(string: urlString) else { return }

        print("Fetching places from URL: \(urlString)") // Debugging line

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching places: \(error.localizedDescription)")
                return
            }

            guard let data = data else { return }

            do {
                // Parse the JSON response to extract place names
                let json = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
                DispatchQueue.main.async {
                    self.places = json.predictions.map { $0.description }
                    print("Fetched places: \(self.places)") // Debugging line
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    struct GooglePlacesResponse: Codable {
        let predictions: [Prediction]
    }

    struct Prediction: Codable {
        let description: String
    }
}

