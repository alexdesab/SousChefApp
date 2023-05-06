//
//  ContentView.swift
//  Sous Chef
//
//  Created by Alex De Sabatino on 5/5/23.
//

import AuthenticationServices
import SwiftUI


struct Recipe: Codable, Identifiable {
    let id = UUID()
    let name: String
    let time_to_make: Int
    let calories: Int
    let protein_grams: Int
    let fat_grams: Int
    let carbohydrate_grams: Int
    let ingredients: String
}

struct RecipesResponse: Codable {
    let recipes: [Recipe]
}

struct ContentView: View {
    @State private var searchText: String = ""
    @State private var recipes: [Recipe] = []
    @State private var isLoading = false
    @State private var selectedRecipe: Recipe?
    @State private var showRecipeDetail = false
    @AppStorage("userID") var userID: String = ""
    
    var body: some View {
        
        if userID.isEmpty{
            SigninView()
        }
        else{
            NavigationView {
                VStack {
                    TextField("Enter ingredients", text: $searchText, onCommit: {
                        self.fetchRecipes()
                    })
                    .padding()
                    
                    if isLoading {
                         ProgressView()
                     } else if !recipes.isEmpty {
                        List(recipes) { recipe in
                            VStack(alignment: .leading) {
                                Text(recipe.name)
                                    .font(.headline)
                                HStack {
                                    Text("Time to make: \(recipe.time_to_make) minutes")
                                    Spacer()
                                    Text("Calories: \(recipe.calories)")
                                }
                                HStack {
                                    Text("Protein: \(recipe.protein_grams)g")
                                    Spacer()
                                    Text("Fat: \(recipe.fat_grams)g")
                                    Spacer()
                                    Text("Carbs: \(recipe.carbohydrate_grams)g")
                                }
                            }
                            .onTapGesture {
                                self.selectedRecipe = recipe
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .background(
                            NavigationLink(
                                destination: RecipeDetailView(recipe: selectedRecipe ?? Recipe(name: "", time_to_make: 0, calories: 0, protein_grams: 0, fat_grams: 0, carbohydrate_grams: 0, ingredients: "")),
                                isActive: Binding(
                                    get: { self.selectedRecipe != nil },
                                    set: { if !$0 { self.selectedRecipe = nil } }
                                )
                            ) {
                                EmptyView()
                            }
                        )
                     } else {
                        Text("No recipes found")
                            .padding()
                     }
                     
                     Spacer()
                 }
                 .navigationTitle("Sous Chef")
                 .navigationBarTitleDisplayMode(.inline)
                 .toolbar {
                     ToolbarItemGroup(placement: .bottomBar) {
                         NavigationLink(destination: SavedRecipesView()) {
                             Label("Saved Recipes", systemImage: "heart.fill")
                         }
                         NavigationLink(destination: SettingsView()) {
                             Label("Settings", systemImage: "gear")
                         }
                     }
                 }
             }
        }
     }
    
    func fetchRecipes() {
        isLoading = true
        let url = URL(string: "http://127.0.0.1:5000/api/recipes")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOjIsImV4cCI6MTY4MzMyNjQzN30.nUZ_T3kqlrEJLPgNXTV5ZvtppWoLlvh8Z7vwmiuJx9M", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let parameters = ["ingredients": [searchText]]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            isLoading = false
            
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                let recipesResponse = try JSONDecoder().decode(RecipesResponse.self, from: data)
                self.recipes = recipesResponse.recipes
            } catch {
                print("Error decoding JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct SigninView: View{
    @Environment(\.colorScheme) var colorScheme
    
    @AppStorage("email") var email: String = ""
    @AppStorage("firstName") var firstName: String = ""
    @AppStorage("lastName") var lastName: String = ""
    @AppStorage("userID") var userID: String = ""
    
    var body: some View{
        NavigationView{
            VStack{
                SignInWithAppleButton(.continue){ request in
                    request.requestedScopes = [.email, .fullName]
                } onCompletion: { result in
                    switch result{
                    case .success(let auth):
                        switch auth.credential{
                        case let credential as ASAuthorizationAppleIDCredential:
                            // persisted by apple
                            let userID = credential.user
                            // Need to store this information, never given again
                            let email = credential.email
                            let firstName = credential.fullName?.givenName
                            let lastName = credential.fullName?.familyName
                            
                            self.email = email ?? ""
                            self.firstName = firstName ?? ""
                            self.lastName = lastName ?? ""
                            self.userID = userID
                            
                            
                        default:
                            break
                        }
                        
                    case .failure(let error):
                        print(error)
                    }
                }
                .signInWithAppleButtonStyle(
                    colorScheme == .dark ? .white : .black
                )
                .frame(width: 250, height: 50, alignment: .center)
                .padding()
                .cornerRadius(10)
            }
            .navigationTitle("Signin With Apple")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text(recipe.name)
                    .font(.largeTitle)
                    .padding(.bottom)
                
                Text("Ingredients:")
                    .font(.headline)
                    .padding(.bottom)
                
                ForEach(recipe.ingredients.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").replacingOccurrences(of: "\'", with: "").split(separator: ","), id: \.self) { ingredient in
                    Text("- \(ingredient.trimmingCharacters(in: .whitespaces))")
                        .padding(.bottom, 5)
                }
                
                Divider()
                
                VStack(alignment: .leading) {
                    Text("Calories:")
                        .font(.headline)
                    Text("\(recipe.calories)")
                        .padding(.bottom, 10)
                    Text("Protein:")
                        .font(.headline)
                    Text("\(recipe.protein_grams)g")
                        .padding(.bottom, 10)
                    Text("Fat:")
                        .font(.headline)
                    Text("\(recipe.fat_grams)g")
                        .padding(.bottom, 10)
                    Text("Carbs:")
                        .font(.headline)
                    Text("\(recipe.carbohydrate_grams)g")
                }
                .padding(.top)
            }
            .padding()
            Spacer()
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search", text: $text)
                .autocapitalization(.none)
        }
        .padding(.horizontal)
        .frame(height: 40)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

struct SavedRecipesView: View {
    @State private var searchText = ""
    @State private var savedRecipes: [Recipe] = []
    @State private var filteredRecipes: [Recipe] = []
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText)
            
            List(filteredRecipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    VStack(alignment: .leading) {
                        Text(recipe.name)
                            .font(.headline)
                        HStack {
                            Text("Calories: \(recipe.calories)")
                            Spacer()
                            Text("Time to make: \(recipe.time_to_make) minutes")
                        }
                        HStack {
                            Text("Protein: \(recipe.protein_grams)g")
                            Spacer()
                            Text("Fat: \(recipe.fat_grams)g")
                            Spacer()
                            Text("Carbs: \(recipe.carbohydrate_grams)g")
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
        }
        .onAppear {
            fetchSavedRecipes()
        }
        .navigationTitle("Saved Recipes")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func fetchSavedRecipes() {
        // Fetch saved recipes from the database
        // and assign them to the `savedRecipes` property.
        // ...
        
        // Filter recipes by name if the search text is not empty.
        if searchText.isEmpty {
            filteredRecipes = savedRecipes
        } else {
            filteredRecipes = savedRecipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                SignInWithAppleButton(.signIn, onRequest: { request in
                    // Customize the requested scopes here
                    request.requestedScopes = [.fullName, .email]
                }, onCompletion: { result in
                    switch result {
                    case .success(let authResult):
                        // Handle successful authentication
                        print("Successfully authenticated with Apple: \(authResult)")
                    case .failure(let error):
                        // Handle error
                        print("Error authenticating with Apple: \(error.localizedDescription)")
                    }
                })
                .frame(width: 200, height: 44)
            }
            
            Section(header: Text("Kitchen Staples")) {
                Text("Select the kitchen staples you have:")
                    .padding(.bottom, 4)
                
                ForEach(KitchenStaple.allCases, id: \.self) { staple in
                    Toggle(staple.rawValue, isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: staple.rawValue) },
                        set: { UserDefaults.standard.set($0, forKey: staple.rawValue) }
                    ))
                }
            }
            
            Section(header: Text("Dietary Preferences")) {
                Text("Select Your Dietary Preferences")
                    .padding(.bottom, 4)
                
                ForEach(DietaryPreferences.allCases, id: \.self) { staple in
                    Toggle(staple.rawValue, isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: staple.rawValue) },
                        set: { UserDefaults.standard.set($0, forKey: staple.rawValue) }
                    ))
                }
            }
            
            Section {
                Button("Sign Out") {
                    // Handle sign out here
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .foregroundColor(.red)
        }
        .navigationTitle("Settings")
    }
}

enum KitchenStaple: String, CaseIterable {
    case oil = "Oil"
    case salt = "Salt"
    case pepper = "Pepper"
    case garlic = "Garlic"
    case onion = "Onion"
    case rice = "Rice"
    case pasta = "Pasta"
    case flour = "Flour"
    case sugar = "Sugar"
    case bakingPowder = "Baking Powder"
    case bakingSoda = "Baking Soda"
}

enum DietaryPreferences: String, CaseIterable{
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case lowCarb = "Low Carb"
}
