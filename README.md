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
