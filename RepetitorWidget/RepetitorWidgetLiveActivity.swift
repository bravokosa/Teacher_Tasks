//
//  RepetitorWidgetLiveActivity.swift
//  RepetitorWidget
//
//  Created by Анна on 13.12.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RepetitorWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RepetitorWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RepetitorWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension RepetitorWidgetAttributes {
    fileprivate static var preview: RepetitorWidgetAttributes {
        RepetitorWidgetAttributes(name: "World")
    }
}

extension RepetitorWidgetAttributes.ContentState {
    fileprivate static var smiley: RepetitorWidgetAttributes.ContentState {
        RepetitorWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RepetitorWidgetAttributes.ContentState {
         RepetitorWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RepetitorWidgetAttributes.preview) {
   RepetitorWidgetLiveActivity()
} contentStates: {
    RepetitorWidgetAttributes.ContentState.smiley
    RepetitorWidgetAttributes.ContentState.starEyes
}
