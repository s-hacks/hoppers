import Foundation
import Supabase

enum SupabaseManager {
    static let client: SupabaseClient = {
        guard let url = Secrets.supabaseURL, Secrets.hasSupabaseConfig else {
            return SupabaseClient(
                supabaseURL: URL(string: "https://example.supabase.co")!,
                supabaseKey: "missing"
            )
        }
        return SupabaseClient(supabaseURL: url, supabaseKey: Secrets.supabaseAnonKey)
    }()

    static var storageBucket: String { "materials" }
}
