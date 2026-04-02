import Foundation

struct LinkedAccount: Identifiable, Codable {
    var id: UUID
    var itemID: String           // Plaid item_id (opaque identifier, not the access_token)
    var institutionName: String  // "Chase", "Bank of America"
    var accountName: String      // "Checking ••4521"
    var currentBalance: Double
    var lastSynced: Date
    var serverURL: String        // URL of companion Plaid backend

    init(
        id: UUID = UUID(),
        itemID: String,
        institutionName: String,
        accountName: String,
        currentBalance: Double = 0,
        lastSynced: Date = Date(),
        serverURL: String
    ) {
        self.id = id
        self.itemID = itemID
        self.institutionName = institutionName
        self.accountName = accountName
        self.currentBalance = currentBalance
        self.lastSynced = lastSynced
        self.serverURL = serverURL
    }
}
