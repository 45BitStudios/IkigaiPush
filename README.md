# IkigaiPush

SPM client for [IkigaiServer](https://github.com/45BitStudios/IkigaiServer) push notifications and Live Activities.

## Add the package

```swift
.package(url: "https://github.com/45BitStudios/IkigaiServer.git", from: "…"),
// product: IkigaiPush — use path dependency while developing:
.package(path: "../IkigaiServer/IkigaiPush"),
```

Or open `IkigaiPush/Package.swift` as a local package.

## Usage

```swift
let push = IkigaiPushClient(
    baseURL: URL(string: "https://ikigai-swcodw.fly.dev")!,
    appId: "empressblood",
    apiKey: ProcessInfo.processInfo.environment["IKIGAI_API_KEY"] ?? "",
    deviceId: Keychain.deviceId // stable UUID you store once
)

// After APNs registration:
try await push.registerDevice(token: deviceToken, userId: currentUserId)

// Alert (also works as a webhook from any backend):
try await push.send(title: "Hello", body: "From Ikigai", to: .user(currentUserId))

// Personal Live Activity:
try await push.registerLiveActivity(id: "order-9", updateToken: token, attributesType: "OrderAttributes")
try await push.updateLiveActivity(id: "order-9", contentState: state)

// Broadcast Live Activity (iOS 18+; enable Broadcast Capability on the App ID):
let channelId = try await push.createChannel(eventId: "match-42", attributesType: "MatchAttributes")
// Activity.request(..., pushType: .channel(channelId))
try await push.send(toChannel: "match-42", contentState: MatchState(home: 1, away: 0))
try await push.endChannel("match-42", finalState: MatchState(home: 2, away: 0))
```

The app never holds APNs auth keys. Register tokens here; send/update from the app, a webhook, or a server job via the same HTTP API.

## Correlation-keyed Live Activities (fan-out across a user's devices)

Use a **`correlationId`** — any stable business key (a build id, order id, match id) — when one logical
activity should appear on *all* of a user's devices and be driven without knowing each device's
per-activity `activityId`. The server stores it on each instance and fans update/end out to every
device sharing the id.

**1. Include `correlationId` in your `ActivityAttributes`** so a push-started activity carries it:

```swift
struct BuildActivityAttributes: ActivityAttributes {
    struct ContentState: Codable & Hashable { var status: String; var message: String? }
    var workflowName: String
    var appName: String
    var buildNumber: Int?
    var correlationId: String   // <- the shared key (server injects it on push-to-start)
}
```

**2. Register the update token *with* the `correlationId`.** Observe both locally-started and
**push-started** activities so either path registers:

```swift
// Register once per running activity (local OR push-started):
func register(_ activity: Activity<BuildActivityAttributes>) {
    Task {
        for await tokenData in activity.pushTokenUpdates {
            try? await push.registerLiveActivity(
                id: activity.id,
                updateToken: tokenData,
                attributesType: "BuildActivityAttributes",
                correlationId: activity.attributes.correlationId   // echo the key back
            )
        }
    }
}

// Catch activities the system starts from a push-to-start (correlationId came down in attributes):
Task {
    for await activity in Activity<BuildActivityAttributes>.activityUpdates {
        register(activity)
    }
}
```

**3. Drive it by `correlationId`** — from the app, a webhook, CI, or a server job:

```swift
// Fan a start out to every device registered to a user:
try await push.startLiveActivityByUser(
    userId: "dev-1",
    attributesType: "BuildActivityAttributes",
    attributes: ["workflowName": "Deploy", "appName": "Ikigai", "buildNumber": 42],
    contentState: ["status": "running", "message": "cloning"],
    correlationId: buildRunID
)

// Update / end every device sharing the id:
try await push.updateLiveActivity(correlationId: buildRunID, contentState: ["status": "testing"])
try await push.endLiveActivity(correlationId: buildRunID, finalState: ["status": "succeeded"])
```

For an **app-initiated** activity, start it locally with `correlationId` set in the attributes and
register its update token immediately — no push-to-start needed. Because update/end are keyed by
`correlationId` (not by how the activity started), CI webhooks and the app can drive the same
activity interchangeably.
