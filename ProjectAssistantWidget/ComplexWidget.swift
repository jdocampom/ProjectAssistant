//
//  ComplexWidget.swift
//  ProjectAssistant
//
//  Created by Juan Diego Ocampo on 4/04/22.
//

import SwiftUI
import WidgetKit

struct PortfolioWidgetMultipleEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.sizeCategory) var dynamicTypeSize
    var entry: Provider.Entry
    var items: ArraySlice<Item> {
        let itemCount: Int
        switch widgetFamily {
        case .systemSmall, .systemMedium:
            if dynamicTypeSize < .extraExtraLarge {
                itemCount = 2
            } else {
                itemCount = 1
            }
        case .systemLarge:
            if dynamicTypeSize < .extraExtraLarge {
                itemCount = 5
            } else {
                itemCount = 4
            }
        default:
            if dynamicTypeSize < .extraExtraLarge {
                itemCount = 7
            } else {
                itemCount = 6
            }
        }
        return entry.items.prefix(itemCount)
    }

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: "stopwatch.fill")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                Text("Up Next…")
                    .bold()
                    .font(.title3)
                Spacer()
            }
            .padding(.vertical)
            if entry.items.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Nothing!")
                            .font(.subheadline)
                        Spacer()
                    }
                    Spacer()
                }
            } else {
                ForEach(items) { item in
                    HStack {
                        Color(item.project?.color ?? "Light Blue")
                            .frame(width: 5)
                            .clipShape(Capsule())
                            .padding(.horizontal)
                        VStack(alignment: .leading) {
                            Text(item.itemTitle)
                                .font(.headline)
                                .minimumScaleFactor(0.75)
                                .lineLimit(1)
                            if let projectTitle = item.project?.projectTitle {
                                Text(projectTitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .minimumScaleFactor(0.75)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct ComplexPortfolioWidget: Widget {
    let kind: String = "ComplexPortfolioWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PortfolioWidgetMultipleEntryView(entry: entry)
        }
        .configurationDisplayName("Up Next…")
        .description("Your most important items.")
    }
}

struct ComplexPortfolioWidget_Previews: PreviewProvider {
    static var previews: some View {
        PortfolioWidgetMultipleEntryView(entry: SimpleEntry(date: Date(), items: [Item.example]))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
