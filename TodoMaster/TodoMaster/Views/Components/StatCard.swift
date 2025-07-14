import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            StatCard(
                title: "Completed Today", 
                value: "5",
                icon: "checkmark.circle.fill",
                color: .blue
            )
            StatCard(
                title: "High Priority", 
                value: "3",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 
