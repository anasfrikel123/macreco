import SwiftUI

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatBox_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            StatBox(title: "Total Tasks", value: "12")
            StatBox(title: "Completed", value: "5")
        }
        .padding()
    }
} 